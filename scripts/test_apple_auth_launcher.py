import os
import errno
from pathlib import Path
import select
import signal
import subprocess
import tempfile
import time
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'tools/apple_auth.command'


@unittest.skipUnless(os.name == 'posix', 'Apple authentication requires POSIX terminals')
class AppleAuthLauncherTest(unittest.TestCase):
    def test_native_authentication_boundary(self):
        import pty

        with tempfile.TemporaryDirectory(prefix='apple-auth-') as directory:
            folder = Path(directory)
            log = folder / 'calls'
            xcrun = folder / 'xcrun'
            xcrun.write_text('''#!/bin/bash
printf '%s\\n' "$*" >> "$AUTH_TEST_LOG"
[ "$MACOS_APP_PASSWORD" = dummy ] || exit 93
exit "${AUTH_TEST_STATUS:-0}"
''')
            xcrun.chmod(0o755)
            env = dict(os.environ, PATH=f'{folder}:{os.environ["PATH"]}',
                       AUTH_TEST_LOG=str(log), APPLE_ID_EMAIL='release@example.invalid',
                       MACOS_APP_PASSWORD='dummy', RWKV_APPLE_AUTH_MODE='api_key')

            for args, status in [([], 1), (['release'], 2)]:
                result = subprocess.run([str(SCRIPT), *args], env=env,
                                        capture_output=True, timeout=10)
                self.assertEqual(status, result.returncode)
                self.assertFalse(log.exists())

            for missing, native_status, foreground in [
                (True, '0', True), (False, '0', True),
                (False, '9', True), (False, '0', False),
            ]:
                current = dict(env, AUTH_TEST_STATUS=native_status)
                if missing:
                    current.pop('MACOS_APP_PASSWORD')
                log.unlink(missing_ok=True)
                if foreground:
                    pid, master = pty.fork()
                    if pid == 0:
                        try:
                            os.execve(str(SCRIPT), [str(SCRIPT)], current)
                        finally:
                            os._exit(127)
                    status = None
                    try:
                        deadline = time.monotonic() + 10
                        while time.monotonic() < deadline:
                            if select.select([master], [], [], 0.05)[0]:
                                try:
                                    os.read(master, 4096)
                                except OSError as error:
                                    if error.errno != errno.EIO:
                                        raise
                            child, value = os.waitpid(pid, os.WNOHANG)
                            if child:
                                status = value
                                break
                    finally:
                        if status is None:
                            os.kill(pid, signal.SIGKILL)
                            os.waitpid(pid, 0)
                        os.close(master)
                    self.assertIsNotNone(status, 'Foreground authentication test timed out')
                    result = os.waitstatus_to_exitcode(status)
                else:
                    master, slave = pty.openpty()
                    try:
                        result = subprocess.run([str(SCRIPT)], env=current, stdin=slave,
                                                stdout=slave, stderr=slave, timeout=10).returncode
                    finally:
                        os.close(master)
                        os.close(slave)
                self.assertEqual(1 if missing or not foreground else int(native_status), result)
                if missing or not foreground:
                    self.assertFalse(log.exists())
                else:
                    self.assertEqual(
                        'altool --list-providers --username release@example.invalid '
                        '--password @env:MACOS_APP_PASSWORD --output-format json\n',
                        log.read_text())
                    self.assertNotIn('dummy', log.read_text())


if __name__ == '__main__':
    unittest.main()
