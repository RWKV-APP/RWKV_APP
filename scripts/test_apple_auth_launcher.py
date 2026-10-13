import errno
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'tools/apple_auth.command'


@unittest.skipUnless(os.name == 'posix', 'The Apple launcher requires a POSIX terminal')
class AppleAuthLauncherTest(unittest.TestCase):
    def test_native_auth_preserves_foreground_and_secret_boundaries(self):
        import pty

        with tempfile.TemporaryDirectory(prefix='apple auth test ') as directory:
            folder = Path(directory)
            log = folder / 'calls'
            xcrun = folder / 'xcrun'
            xcrun.write_text('''#!/usr/bin/env python3
import json, os, pathlib, sys
pathlib.Path(os.environ['AUTH_TEST_LOG']).write_text(json.dumps(sys.argv[1:]))
assert os.environ['MACOS_APP_PASSWORD'] == 'test-secret-never-in-argv'
sys.exit(int(os.environ['AUTH_TEST_STATUS']))
''')
            xcrun.chmod(0o755)
            env = dict(os.environ, PATH=f'{folder}:{os.environ["PATH"]}',
                       AUTH_TEST_LOG=str(log), AUTH_TEST_STATUS='0',
                       APPLE_ID_EMAIL='test@example.invalid',
                       MACOS_APP_PASSWORD='test-secret-never-in-argv',
                       RWKV_APPLE_AUTH_MODE='api_key')

            for arguments, expected in [([], 1), (['apple'], 2)]:
                result = subprocess.run([str(SCRIPT), *arguments], env=env,
                                        capture_output=True, timeout=10)
                self.assertEqual(expected, result.returncode)
                self.assertFalse(log.exists())

            cases = [('success', {}, 0, True),
                     ('provider failure', {'AUTH_TEST_STATUS': '9'}, 9, True),
                     ('missing password', {'MACOS_APP_PASSWORD': ''}, 1, False),
                     ('missing account', {'APPLE_ID_EMAIL': ''}, 1, False)]
            for name, overrides, expected, contacted in cases:
                with self.subTest(name=name):
                    log.unlink(missing_ok=True)
                    master, slave = pty.openpty()
                    try:
                        process = subprocess.Popen([str(SCRIPT)], env=env | overrides,
                                                   stdin=slave, stdout=slave, stderr=slave)
                        os.close(slave)
                        slave = None
                        try:
                            status = process.wait(timeout=10)
                        finally:
                            if process.poll() is None:
                                process.kill()
                                process.wait()
                        output = b''
                        try:
                            while chunk := os.read(master, 4096):
                                output += chunk
                        except OSError as error:
                            if error.errno != errno.EIO:
                                raise
                    finally:
                        os.close(master)
                        if slave is not None:
                            os.close(slave)
                    self.assertEqual(expected, status)
                    self.assertEqual(contacted, log.exists())
                    self.assertNotIn(b'test-secret-never-in-argv', output)
                    if contacted:
                        self.assertEqual(['altool', '--list-providers', '--username',
                                          'test@example.invalid', '--password',
                                          '@env:MACOS_APP_PASSWORD'], json.loads(log.read_text()))


if __name__ == '__main__':
    unittest.main()
