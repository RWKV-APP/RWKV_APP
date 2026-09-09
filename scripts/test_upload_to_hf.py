import hashlib
import importlib.util
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import MagicMock, patch


class FrozenHFUploadTest(unittest.TestCase):
    def test_verified_resume_conflict_and_new_upload(self):
        spec = importlib.util.spec_from_file_location('hf_upload_under_test', Path(__file__).with_name('upload_to_hf.py'))
        module = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {'huggingface_hub': SimpleNamespace(HfApi=MagicMock())}):
            spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / 'release.dmg'
            artifact.write_bytes(b'accepted package')
            row = SimpleNamespace(size=artifact.stat().st_size, lfs=SimpleNamespace(sha256=hashlib.sha256(artifact.read_bytes()).hexdigest()))
            writer, reader = MagicMock(), MagicMock()
            with patch.object(module, 'HfApi', side_effect=[writer, reader, reader, reader, reader]):
                uploader = module.HFUploader('private-test-token')
                reader.get_paths_info.return_value = [row]
                self.assertTrue(uploader.upload_file('owner/repo', str(artifact), verify_package=True))
                writer.upload_file.assert_not_called()
                reader.get_paths_info.assert_called_with('owner/repo', paths=['release.dmg'], repo_type='dataset', revision='main', token=False)

                artifact.write_bytes(b'different package')
                with self.assertRaisesRegex(ValueError, 'refusing replacement'):
                    uploader.upload_file('owner/repo', str(artifact), verify_package=True)
                writer.upload_file.assert_not_called()

                artifact.write_bytes(b'accepted package')
                reader.get_paths_info.side_effect = [[], [row]]
                writer.upload_file.return_value = SimpleNamespace(oid='a' * 40)
                self.assertTrue(uploader.upload_file('owner/repo', str(artifact), verify_package=True))
                self.assertEqual('a' * 40, reader.get_paths_info.call_args.kwargs['revision'])

                reader.get_paths_info.side_effect = [[], []]
                with self.assertRaisesRegex(ValueError, 'not anonymously visible'):
                    uploader.upload_file('owner/repo', str(artifact), verify_package=True)


if __name__ == '__main__':
    unittest.main()
