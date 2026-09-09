import errno
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'tools/apple_auth.command'


@unittest.skipUnless(os.name == 'posix', 'The Apple launcher requires a POSIX terminal')
class AppleAuthLauncherTest(unittest.TestCase):
    def test_launcher_requires_foreground_and_only_dispatches_apple_id_auth(self):
        import pty

        with tempfile.TemporaryDirectory(prefix='apple auth test ') as directory:
            folder = Path(directory)
            log = folder / 'calls'
            bundle = folder / 'bundle'
            bundle.write_text('''#!/bin/bash
[ "$FASTLANE_SKIP_DOCS" = 1 ] || exit 92
printf '%s|%s|%s\\n' "$BUNDLE_GEMFILE" "$BUNDLE_FROZEN" "$*" >> "$AUTH_TEST_LOG"
if [ "$2" = check ]; then exit "${AUTH_TEST_BUNDLE_STATUS:-0}"; fi
[ "$2 $3 $4 $5" = 'exec fastlane ios_auth_preflight apple_auth_mode:apple_id' ] || exit 91
''')
            bundle.chmod(0o755)
            env = dict(os.environ, PATH=f'{folder}:{os.environ["PATH"]}',
                       AUTH_TEST_LOG=str(log), RWKV_APPLE_AUTH_MODE='api_key')

            # Neither a redirected launch nor injected release arguments may reach Bundler.
            result = subprocess.run([str(SCRIPT)], env=env, cwd=folder,
                                    capture_output=True, timeout=10)
            self.assertEqual(1, result.returncode)
            self.assertFalse(log.exists())
            result = subprocess.run([str(SCRIPT), 'apple'], env=env, cwd=folder,
                                    capture_output=True, timeout=10)
            self.assertEqual(2, result.returncode)
            self.assertFalse(log.exists())

            for bundle_status, expected_calls in [('0', 2), ('9', 1)]:
                env['AUTH_TEST_BUNDLE_STATUS'] = bundle_status
                log.unlink(missing_ok=True)
                master, slave = pty.openpty()
                try:
                    process = subprocess.Popen([str(SCRIPT)], env=env, cwd=folder,
                                               stdin=slave, stdout=slave, stderr=slave)
                    os.close(slave)
                    slave = None
                    try:
                        status = process.wait(timeout=10)
                    finally:
                        if process.poll() is None:
                            process.kill()
                            process.wait()
                    # The small stub output cannot fill the terminal buffer.
                    try:
                        while os.read(master, 4096):
                            pass
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                finally:
                    os.close(master)
                    if slave is not None:
                        os.close(slave)
                self.assertEqual(int(bundle_status), status)
                calls = log.read_text().splitlines()
                self.assertEqual(expected_calls, len(calls))
                version = (ROOT / 'Gemfile.lock').read_text().split('BUNDLED WITH\n')[1].strip()
                prefix = f'{ROOT / "Gemfile"}|true|_{version}_ '
                self.assertEqual(prefix + 'check', calls[0])
                if expected_calls == 2:
                    self.assertEqual(prefix + 'exec fastlane ios_auth_preflight apple_auth_mode:apple_id', calls[1])


if __name__ == '__main__':
    unittest.main()
