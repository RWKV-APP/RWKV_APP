#!/usr/bin/env python3

import importlib.util
import hashlib
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace


SCRIPT_PATH = Path(__file__).with_name("upload_to_modelscope.py")
SPEC = importlib.util.spec_from_file_location("upload_to_modelscope", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FakeApi:
    def __init__(self, **kwargs):
        self.init_kwargs = kwargs
        self.calls = []
        self.files = []

    def list_repo_files(self, *args, **kwargs):
        return self.files

    def upload_file(self, *args, **kwargs):
        self.calls.append((args, kwargs))
        data = Path(args[2]).read_bytes()
        self.files = [SimpleNamespace(path=args[3], size=len(data), sha256=hashlib.sha256(data).hexdigest())]
        return {"commit": "test"}


class ModelScopeUploaderTest(unittest.TestCase):
    def test_upload_preserves_dataset_path_and_revision(self):
        fake_api = FakeApi()
        def api_factory(**kwargs):
            fake_api.init_kwargs.update(kwargs)
            return fake_api

        uploader = MODULE.ModelScopeUploader(
            token="test-token",
            endpoint="https://modelscope.cn/",
            api_factory=api_factory,
        )

        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / 'release.apk'
            artifact.write_bytes(b'release')
            result = uploader.upload_file(
                repo_id="HaloWang1991/rwkv-chat",
                local_path=str(artifact),
                path_in_repo="android-arm64/rwkv_chat_4.5.0_750.apk",
                revision="master",
                commit_message="Upload Android release",
            )

        self.assertEqual(result, {"commit": "test"})
        self.assertEqual(
            fake_api.init_kwargs,
            {"token": "", "endpoint": "https://modelscope.cn"},
        )
        args, kwargs = fake_api.calls[0]
        self.assertEqual(args[0:2], ("HaloWang1991/rwkv-chat", "dataset"))
        self.assertEqual(args[3], "android-arm64/rwkv_chat_4.5.0_750.apk")
        self.assertEqual(kwargs["revision"], "master")
        self.assertTrue(kwargs["disable_tqdm"])

    def test_resume_skips_equal_bytes_and_refuses_a_conflicting_file(self):
        api = FakeApi()
        uploader = MODULE.ModelScopeUploader(token='test-token', api_factory=lambda **_: api)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'release.zip'
            path.write_bytes(b'accepted artifact')
            options = dict(repo_id='HaloWang1991/rwkv-chat', local_path=str(path), path_in_repo='windows-x64/release.zip')
            uploader.upload_file(**options)
            self.assertTrue(uploader.upload_file(**options)['skipped'])
            self.assertEqual(len(api.calls), 1)
            path.write_bytes(b'different artifact')
            with self.assertRaisesRegex(ValueError, 'overwrite different'):
                uploader.upload_file(**options)
            self.assertEqual(len(api.calls), 1)

    def test_download_url_uses_dataset_resolve_route(self):
        self.assertEqual(
            MODULE.build_download_url(
                "https://modelscope.cn/",
                "HaloWang1991/rwkv-chat",
                "master",
                "windows-x64/RWKV Chat.zip",
            ),
            "https://modelscope.cn/datasets/HaloWang1991/rwkv-chat/resolve/master/windows-x64/RWKV%20Chat.zip",
        )


if __name__ == "__main__":
    unittest.main()
