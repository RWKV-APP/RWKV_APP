import json
import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from release_identity import load_release, upload_github


class ReleaseIdentityTest(unittest.TestCase):
    def test_github_resume_verifies_bytes_without_replacing_or_publishing(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'release.zip'
            file.write_bytes(b'accepted release')
            asset = dict(name=file.name, size=file.stat().st_size, digest='sha256:' + hashlib.sha256(file.read_bytes()).hexdigest())
            with patch('release_identity.command', return_value=json.dumps(dict(tagName='4.8.0', assets=[asset]))), patch('release_identity.subprocess.run') as mutate:
                upload_github(dict(version='4.8.0'), [file])
                mutate.assert_not_called()
                file.write_bytes(b'different release')
                with self.assertRaisesRegex(ValueError, 'refusing replacement'):
                    upload_github(dict(version='4.8.0'), [file])
                mutate.assert_not_called()

    def test_rejects_version_and_mutable_dependency_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            root.joinpath('pubspec.yaml').write_text('version: 4.8.0+755\n')
            release = dict(version='4.8.0', build=755, flutterVersion='3.44.8',
                           adapter=dict(repository='RWKV-APP/rwkv_mobile_flutter', commit='a' * 40),
                           native=dict(repository='RWKV-APP/rwkv-mobile', commit='b' * 40, tag='v4.8.0-native.1'),
                           channels=dict(github=True, modelscope=True, huggingface=False))
            def write():
                root.joinpath('release.json').write_text(json.dumps(release))
            write()
            self.assertEqual(755, load_release(root)['build'])
            release['build'] = 756
            write()
            with self.assertRaisesRegex(ValueError, 'differ'):
                load_release(root)
            release['build'] = 755
            release['adapter']['commit'] = 'dev'
            write()
            with self.assertRaisesRegex(ValueError, 'full commit'):
                load_release(root)
            release['adapter']['commit'] = 'a' * 40
            release['native']['tag'] = 'latest'
            write()
            with self.assertRaisesRegex(ValueError, 'immutable'):
                load_release(root)


if __name__ == '__main__':
    unittest.main()
