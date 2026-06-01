#!/usr/bin/env python3
"""
Test script for the RWKV OpenAI Compatible API Server.

Usage:
    python tools/test_openai_api.py [--base-url http://localhost:8080]

Prerequisites:
    pip install requests
"""

import argparse
import json
import sys
import time

import requests


def test_models(base_url: str) -> bool:
    print("\n=== GET /v1/models ===")
    try:
        r = requests.get(f"{base_url}/v1/models", timeout=5)
        print(f"Status: {r.status_code}")
        data = r.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"
        assert "data" in data, "Missing 'data' field"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_server_status(base_url: str) -> bool:
    print("\n=== GET /v1/server/status ===")
    try:
        r = requests.get(f"{base_url}/v1/server/status", timeout=5)
        print(f"Status: {r.status_code}")
        data = r.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"
        assert data.get("status") == "running", "Server not running"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_chat_completions_blocking(base_url: str) -> bool:
    print("\n=== POST /v1/chat/completions (non-streaming) ===")
    payload = {
        "model": "rwkv",
        "messages": [{"role": "user", "content": "Hello, who are you?"}],
        "stream": False,
        "max_tokens": 64,
    }
    try:
        r = requests.post(
            f"{base_url}/v1/chat/completions",
            json=payload,
            timeout=120,
        )
        print(f"Status: {r.status_code}")
        data = r.json()
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"
        content = data["choices"][0]["message"]["content"]
        assert len(content) > 0, "Empty response content"
        print(f"Content: {content[:200]}")
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_chat_completions_streaming(base_url: str) -> bool:
    print("\n=== POST /v1/chat/completions (streaming) ===")
    payload = {
        "model": "rwkv",
        "messages": [{"role": "user", "content": "Count from 1 to 5."}],
        "stream": True,
        "max_tokens": 64,
    }
    try:
        r = requests.post(
            f"{base_url}/v1/chat/completions",
            json=payload,
            timeout=120,
            stream=True,
        )
        print(f"Status: {r.status_code}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"

        full_content = ""
        chunk_count = 0
        done = False

        for line in r.iter_lines(decode_unicode=True):
            if not line:
                continue
            if not line.startswith("data: "):
                continue
            payload_str = line[6:].strip()
            if payload_str == "[DONE]":
                done = True
                break
            chunk = json.loads(payload_str)
            delta = chunk.get("choices", [{}])[0].get("delta", {})
            content = delta.get("content", "")
            if content:
                full_content += content
                chunk_count += 1
                print(content, end="", flush=True)

        print()
        print(f"Chunks received: {chunk_count}")
        print(f"Full content: {full_content[:200]}")
        assert done, "Did not receive [DONE]"
        assert chunk_count > 0, "No content chunks received"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_chat_completions_tool_call_blocking(base_url: str) -> bool:
    print("\n=== POST /v1/chat/completions (tool calling, non-streaming) ===")
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_current_time",
                "description": "Get the current time in a given timezone",
                "parameters": {
                    "type": "object",
                    "properties": {"timezone": {"type": "string"}},
                    "required": ["timezone"],
                },
            },
        }
    ]
    payload = {
        "model": "rwkv",
        "messages": [{"role": "user", "content": "What time is it right now? Use the tool."}],
        "tools": tools,
        "tool_choice": {"type": "function", "function": {"name": "get_current_time"}},
        "stream": False,
        "max_tokens": 128,
    }
    try:
        r = requests.post(f"{base_url}/v1/chat/completions", json=payload, timeout=120)
        print(f"Status: {r.status_code}")
        data = r.json()
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"
        msg = data["choices"][0]["message"]
        assert "tool_calls" in msg, "Missing tool_calls in response message"
        assert len(msg["tool_calls"]) > 0, "Empty tool_calls"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_chat_completions_tool_call_streaming(base_url: str) -> bool:
    print("\n=== POST /v1/chat/completions (tool calling, streaming) ===")
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_current_time",
                "description": "Get the current time in a given timezone",
                "parameters": {
                    "type": "object",
                    "properties": {"timezone": {"type": "string"}},
                    "required": ["timezone"],
                },
            },
        }
    ]
    payload = {
        "model": "rwkv",
        "messages": [{"role": "user", "content": "Use the tool to get current time in UTC."}],
        "tools": tools,
        "tool_choice": {"type": "function", "function": {"name": "get_current_time"}},
        "stream": True,
        "max_tokens": 128,
    }
    try:
        r = requests.post(
            f"{base_url}/v1/chat/completions",
            json=payload,
            timeout=120,
            stream=True,
        )
        print(f"Status: {r.status_code}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"

        saw_done = False
        saw_tool_calls = False
        last_finish_reason = None

        for line in r.iter_lines(decode_unicode=True):
            if not line:
                continue
            if not line.startswith("data: "):
                continue
            payload_str = line[6:].strip()
            if payload_str == "[DONE]":
                saw_done = True
                break

            chunk = json.loads(payload_str)
            choice0 = chunk.get("choices", [{}])[0]
            delta = choice0.get("delta", {})
            last_finish_reason = choice0.get("finish_reason", last_finish_reason)
            if "tool_calls" in delta:
                saw_tool_calls = True
                print("tool_calls delta:", json.dumps(delta["tool_calls"], ensure_ascii=False))

        assert saw_done, "Did not receive [DONE]"
        assert saw_tool_calls, "Did not receive tool_calls delta"
        # Depending on server semantics, finish_reason can be tool_calls or stop.
        assert last_finish_reason in ("tool_calls", "stop", None), f"Unexpected finish_reason: {last_finish_reason}"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_chat_completions_legacy_function_call_blocking(base_url: str) -> bool:
    print("\n=== POST /v1/chat/completions (legacy function_call, non-streaming) ===")
    functions = [
        {
            "name": "get_current_time",
            "description": "Get the current time in a given timezone",
            "parameters": {
                "type": "object",
                "properties": {"timezone": {"type": "string"}},
                "required": ["timezone"],
            },
        }
    ]
    payload = {
        "model": "rwkv",
        "messages": [{"role": "user", "content": "Use the function to get the time in UTC."}],
        "functions": functions,
        "function_call": {"name": "get_current_time"},
        "stream": False,
        "max_tokens": 128,
    }
    try:
        r = requests.post(f"{base_url}/v1/chat/completions", json=payload, timeout=120)
        print(f"Status: {r.status_code}")
        data = r.json()
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"
        msg = data["choices"][0]["message"]
        # Server may return modern tool_calls and mirror the first into legacy function_call.
        assert "function_call" in msg or "tool_calls" in msg, "Missing function_call/tool_calls"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_completions_blocking(base_url: str) -> bool:
    print("\n=== POST /v1/completions (non-streaming) ===")
    payload = {
        "model": "rwkv",
        "prompt": "The capital of France is",
        "stream": False,
        "max_tokens": 32,
    }
    try:
        r = requests.post(
            f"{base_url}/v1/completions",
            json=payload,
            timeout=120,
        )
        print(f"Status: {r.status_code}")
        data = r.json()
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"
        text = data["choices"][0]["text"]
        assert len(text) > 0, "Empty response text"
        print(f"Text: {text[:200]}")
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_completions_streaming(base_url: str) -> bool:
    print("\n=== POST /v1/completions (streaming) ===")
    payload = {
        "model": "rwkv",
        "prompt": "Once upon a time",
        "stream": True,
        "max_tokens": 32,
    }
    try:
        r = requests.post(
            f"{base_url}/v1/completions",
            json=payload,
            timeout=120,
            stream=True,
        )
        print(f"Status: {r.status_code}")
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"

        full_text = ""
        chunk_count = 0
        done = False

        for line in r.iter_lines(decode_unicode=True):
            if not line:
                continue
            if not line.startswith("data: "):
                continue
            payload_str = line[6:].strip()
            if payload_str == "[DONE]":
                done = True
                break
            chunk = json.loads(payload_str)
            text = chunk.get("choices", [{}])[0].get("text", "")
            if text:
                full_text += text
                chunk_count += 1
                print(text, end="", flush=True)

        print()
        print(f"Chunks received: {chunk_count}")
        print(f"Full text: {full_text[:200]}")
        assert done, "Did not receive [DONE]"
        assert chunk_count > 0, "No text chunks received"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_invalid_request(base_url: str) -> bool:
    print("\n=== POST /v1/chat/completions (invalid body) ===")
    try:
        r = requests.post(
            f"{base_url}/v1/chat/completions",
            data="not json",
            headers={"Content-Type": "application/json"},
            timeout=10,
        )
        print(f"Status: {r.status_code}")
        assert r.status_code == 400, f"Expected 400, got {r.status_code}"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def test_not_found(base_url: str) -> bool:
    print("\n=== GET /v1/nonexistent ===")
    try:
        r = requests.get(f"{base_url}/v1/nonexistent", timeout=5)
        print(f"Status: {r.status_code}")
        assert r.status_code == 404, f"Expected 404, got {r.status_code}"
        print("PASS")
        return True
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Test RWKV OpenAI Compatible API")
    parser.add_argument("--base-url", default="http://127.0.0.1:52345", help="Server base URL")
    args = parser.parse_args()

    base_url = args.base_url.rstrip("/")
    print(f"Testing server at: {base_url}")

    tests = [
        ("Server Status", test_server_status),
        ("Models", test_models),
        ("Chat Completions (blocking)", test_chat_completions_blocking),
        ("Chat Completions (streaming)", test_chat_completions_streaming),
        ("Chat Completions (tool calling)", test_chat_completions_tool_call_blocking),
        ("Chat Completions (tool calling, streaming)", test_chat_completions_tool_call_streaming),
        ("Chat Completions (legacy function_call)", test_chat_completions_legacy_function_call_blocking),
        ("Completions (blocking)", test_completions_blocking),
        ("Completions (streaming)", test_completions_streaming),
        ("Invalid Request", test_invalid_request),
        ("Not Found", test_not_found),
    ]

    results = []
    for name, fn in tests:
        passed = fn(base_url)
        results.append((name, passed))
        time.sleep(0.5)

    print("\n" + "=" * 50)
    print("RESULTS:")
    print("=" * 50)
    total = len(results)
    passed = sum(1 for _, p in results if p)
    for name, p in results:
        status = "PASS" if p else "FAIL"
        print(f"  [{status}] {name}")
    print(f"\n{passed}/{total} tests passed")

    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
