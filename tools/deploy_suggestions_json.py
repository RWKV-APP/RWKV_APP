import argparse
import difflib
import json
import os
import sys
import tempfile

try:
    import paramiko
except ImportError:
    paramiko = None

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if load_dotenv is not None:
    load_dotenv(os.path.join(project_root, ".env"))

DEFAULT_HOST = os.getenv("RWKV_SUGGESTIONS_HOST")
DEFAULT_PORT = int(os.getenv("RWKV_SUGGESTIONS_PORT", 22))
DEFAULT_USER = os.getenv("RWKV_SUGGESTIONS_USER")
DEFAULT_PASS = os.getenv("RWKV_SUGGESTIONS_PASS")
DEFAULT_LOCAL_PATH = os.getenv(
    "RWKV_SUGGESTIONS_LOCAL_PATH",
    os.path.join(project_root, "remote", "suggestions.json"),
)
DEFAULT_REMOTE_PATH = os.getenv(
    "RWKV_SUGGESTIONS_REMOTE_PATH",
    "/var/www/json/suggestions.json",
)


def _error(message: str, exit_code: int = 1) -> None:
    print(f"❌ Error: {message}")
    sys.exit(exit_code)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Deploy remote/suggestions.json to remote server with diff check."
    )
    parser.add_argument("--host", default=DEFAULT_HOST, help="SSH host. Default: RWKV_SUGGESTIONS_HOST")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="SSH port. Default: RWKV_SUGGESTIONS_PORT")
    parser.add_argument("--user", default=DEFAULT_USER, help="SSH user. Default: RWKV_SUGGESTIONS_USER")
    parser.add_argument("--password", default=DEFAULT_PASS, help="SSH password. Default: RWKV_SUGGESTIONS_PASS")
    parser.add_argument(
        "--local-path",
        default=DEFAULT_LOCAL_PATH,
        help="Local suggestions JSON path. Default: RWKV_SUGGESTIONS_LOCAL_PATH",
    )
    parser.add_argument(
        "--remote-path",
        default=DEFAULT_REMOTE_PATH,
        help="Remote suggestions JSON path. Default: RWKV_SUGGESTIONS_REMOTE_PATH",
    )
    parser.add_argument("-y", "--yes", action="store_true", help="Skip confirmation prompt")
    parser.add_argument("--diff-only", action="store_true", help="Show diff only, do not upload")
    return parser.parse_args()


def _validate_local_json(local_path: str) -> str:
    if not os.path.isfile(local_path):
        _error(f"Local suggestions file not found: {local_path}")

    print(f"Validating local JSON: {local_path}")
    try:
        with open(local_path, "r", encoding="utf-8") as file:
            local_content = file.read()
        json.loads(local_content)
        print("✅ Local suggestions.json is valid.")
        return local_content
    except Exception as exc:
        _error(f"Invalid local JSON: {exc}")
    return ""


def _read_remote_content(sftp: paramiko.SFTPClient, remote_path: str) -> str:
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(mode="w+", delete=False) as tmp_file:
            tmp_path = tmp_file.name
        sftp.get(remote_path, tmp_path)
        with open(tmp_path, "r", encoding="utf-8") as file:
            return file.read()
    except FileNotFoundError:
        print("Remote file not found. This will be treated as a new upload.")
        return ""
    except Exception as exc:
        error_no = getattr(exc, "errno", None)
        if error_no == 2 or "No such file" in str(exc):
            print("Remote file not found. This will be treated as a new upload.")
            return ""
        _error(f"Failed to download remote file: {exc}")
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)

    return ""


def _show_diff(local_content: str, remote_content: str, local_path: str, remote_path: str) -> bool:
    if local_content == remote_content:
        print("✅ Remote file is identical to local file.")
        return False

    print("⚠️ Differences found (Local vs Remote):")
    diff = difflib.unified_diff(
        remote_content.splitlines(keepends=True),
        local_content.splitlines(keepends=True),
        fromfile=f"Remote ({remote_path})",
        tofile=f"Local ({local_path})",
    )
    diff_text = "".join(diff)
    if diff_text:
        print(diff_text)
    else:
        print("(Files differ but unified_diff is empty - likely line ending or encoding differences)")
    return True


def deploy() -> None:
    args = _parse_args()
    if paramiko is None:
        _error("Missing dependency: paramiko. Run `python3 -m pip install -r tools/requirements.txt`.")

    if not all([args.host, args.user, args.password]):
        _error(
            "Missing suggestions SSH config. Please set RWKV_SUGGESTIONS_HOST, RWKV_SUGGESTIONS_USER, and RWKV_SUGGESTIONS_PASS in .env or pass args."
        )

    local_path = os.path.abspath(args.local_path)
    local_content = _validate_local_json(local_path)

    ssh = None
    sftp = None
    try:
        print(f"Connecting to {args.host}:{args.port} as {args.user} ...")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(args.host, args.port, args.user, args.password)

        sftp = ssh.open_sftp()
        remote_path = args.remote_path

        print(f"Comparing: {local_path} -> {remote_path}")
        remote_content = _read_remote_content(sftp, remote_path)
        has_diff = _show_diff(local_content, remote_content, local_path, remote_path)

        if args.diff_only:
            if not has_diff:
                print("\n✅ No differences.")
            return

        if not has_diff:
            print("\n✅ No upload needed.")
            return

        if not args.yes:
            try:
                confirm = input("Do you want to overwrite the remote suggestions file? (y/N): ")
            except EOFError:
                print("\nNon-interactive mode detected. Use --yes to force overwrite.")
                return
            if confirm.lower() != "y":
                print("Deployment aborted by user.")
                return

        print("\n🚀 Uploading suggestions.json ...")
        sftp.put(local_path, remote_path)
        print("✅ Upload complete. No restart required for suggestions.json.")
    except Exception as exc:
        print(f"❌ Deployment failed: {exc}")
        sys.exit(1)
    finally:
        if sftp:
            sftp.close()
        if ssh:
            ssh.close()


if __name__ == "__main__":
    deploy()
