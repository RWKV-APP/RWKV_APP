#!/usr/bin/env python3

import importlib.util
import hashlib
import tempfile
import unittest
from pathlib import Path


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
        self.legacy = self
        self.queries = []

    def list_repo_files(self, *args, **kwargs):
        raise AssertionError("The incomplete high-level listing must never be used")

    def list_dataset_files_paginated(self, *args, **kwargs):
        self.queries.append((args, kwargs))
        return self.files

    def upload_file(self, *args, **kwargs):
        self.calls.append((args, kwargs))
        data = Path(args[2]).read_bytes()
        self.files = [{"Path": args[3], "Size": len(data), "Sha256": hashlib.sha256(data).hexdigest()}]
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

    def test_late_page_target_is_checked_before_upload(self):
        api = FakeApi()
        uploader = MODULE.ModelScopeUploader(token='test-token', api_factory=lambda **_: api)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'release.zip'
            path.write_bytes(b'accepted artifact')
            target = dict(Path='windows-x64/nested/release.zip', Size=path.stat().st_size,
                          Sha256=hashlib.sha256(path.read_bytes()).hexdigest())
            api.files = [dict(Path=f'windows-x64/nested/old-{i}.zip', Size=1, Sha256='0' * 64) for i in range(101)] + [target]
            options = dict(repo_id='HaloWang1991/rwkv-chat', local_path=str(path),
                           path_in_repo=target['Path'], revision='frozen-revision')
            self.assertTrue(uploader.upload_file(**options)['skipped'])
            target['Sha256'] = '1' * 64
            with self.assertRaisesRegex(ValueError, 'overwrite different'):
                uploader.upload_file(**options)
            self.assertEqual(api.calls, [])
            self.assertTrue(api.queries)
            for args, kwargs in api.queries:
                self.assertEqual(args, ('HaloWang1991/rwkv-chat',))
                self.assertEqual(kwargs, dict(revision='frozen-revision', root_path='windows-x64/nested', page_size=100))

    def test_anonymous_metadata_must_match_after_upload(self):
        for observed in (None, dict(Path='release.zip', Size=99, Sha256=hashlib.sha256(b'release').hexdigest()),
                         dict(Path='release.zip', Size=7, Sha256='1' * 64)):
            with self.subTest(observed=observed), tempfile.TemporaryDirectory() as directory:
                authenticated, anonymous = FakeApi(), FakeApi()
                anonymous.files = [] if observed is None else [observed]
                uploader = MODULE.ModelScopeUploader(token='test-token', api_factory=lambda token, **_: authenticated if token else anonymous)
                path = Path(directory) / 'release.zip'
                path.write_bytes(b'release')
                with self.assertRaisesRegex(RuntimeError, 'checksum verification failed'):
                    uploader.upload_file('HaloWang1991/rwkv-chat', str(path), 'release.zip')
                self.assertEqual(len(authenticated.calls), 1)
                self.assertEqual(anonymous.queries[0][1], dict(revision='master', root_path='/', page_size=100))

    def test_missing_or_failed_pagination_blocks_upload(self):
        for failure in ('missing', 'query_error'):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                api = FakeApi()
                if failure == 'missing':
                    api.legacy = None
                else:
                    def fail(*args, **kwargs):
                        raise RuntimeError('query failed')
                    api.list_dataset_files_paginated = fail
                uploader = MODULE.ModelScopeUploader(token='test-token', api_factory=lambda **_: api)
                path = Path(directory) / 'release.zip'
                path.write_bytes(b'release')
                with self.assertRaises(RuntimeError):
                    uploader.upload_file('HaloWang1991/rwkv-chat', str(path), 'release.zip')
                self.assertEqual(api.calls, [])

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
