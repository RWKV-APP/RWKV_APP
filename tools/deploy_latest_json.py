import paramiko
import os
import json
import sys
import argparse
import tempfile
import difflib
from dotenv import load_dotenv

# Load environment variables from .env file
# Try loading from project root or tools directory
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(project_root, '.env'))

# Configuration
HOSTNAME = os.getenv('RWKV_REMOTE_HOST')
PORT = int(os.getenv('RWKV_REMOTE_PORT', 22))
USERNAME = os.getenv('RWKV_REMOTE_USER')
PASSWORD = os.getenv('RWKV_REMOTE_PASS')

REMOTE_PATH = '/opt/rwkv/apps/api-model/json/latest.json'
# Path relative to this script: ../../remote/latest.json
LOCAL_PATH = os.path.join(project_root, 'remote', 'latest.json')
RESTART_CMD = 'pm2 reload 9'

def deploy():
    # Check for missing credentials
    if not all([HOSTNAME, USERNAME, PASSWORD]):
        print("❌ Error: Missing configuration. Please set RWKV_REMOTE_HOST, RWKV_REMOTE_USER, and RWKV_REMOTE_PASS in your .env file.")
        sys.exit(1)

    parser = argparse.ArgumentParser(description='Deploy latest.json to remote server with diff check.')
    parser.add_argument('-y', '--yes', action='store_true', help='Skip confirmation prompt and overwrite')
    parser.add_argument('--diff-only', action='store_true', help='Download, show diff, and exit')
    args = parser.parse_args()

    # 1. Validate local JSON
    print(f"Validating {LOCAL_PATH}...")
    try:
        with open(LOCAL_PATH, 'r', encoding='utf-8') as f:
            local_content = f.read()
        # Ensure it's valid JSON
        json.loads(local_content)
        print("Local JSON is valid.")
    except Exception as e:
        print(f"❌ Error: Invalid local JSON file: {e}")
        sys.exit(1)

    # 2. Connect
    print(f"Connecting to {HOSTNAME}...")
    ssh = None
    temp_path = None
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(HOSTNAME, PORT, USERNAME, PASSWORD)
        
        sftp = ssh.open_sftp()
        
        # 3. Download remote file for comparison
        print(f"Downloading {REMOTE_PATH} for comparison...")
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as tmp:
            temp_path = tmp.name
        
        try:
            sftp.get(REMOTE_PATH, temp_path)
            with open(temp_path, 'r', encoding='utf-8') as f:
                remote_content = f.read()
        except FileNotFoundError:
            print("Remote file not found. This will be a new file.")
            remote_content = ""
        except Exception as e:
            print(f"Error downloading remote file: {e}")
            remote_content = ""

        # 4. Compare
        if local_content == remote_content:
            print("✅ Remote file is identical to local file.")
            if args.diff_only:
                return
        else:
            print("⚠️ Differences found (Local vs Remote):")
            diff = difflib.unified_diff(
                remote_content.splitlines(keepends=True),
                local_content.splitlines(keepends=True),
                fromfile=f'Remote ({REMOTE_PATH})',
                tofile=f'Local ({LOCAL_PATH})'
            )
            diff_text = ''.join(diff)
            if diff_text:
                print(diff_text)
            else:
                print("(Files differ but unified_diff is empty - likely line ending or encoding differences)")

            if args.diff_only:
                return

            if not args.yes:
                # Interactive confirmation
                try:
                    confirm = input("Do you want to overwrite the remote file? (y/N): ")
                    if confirm.lower() != 'y':
                        print("Deployment aborted by user.")
                        return
                except EOFError:
                    print("\nNon-interactive mode detected. Use --yes to force overwrite.")
                    return

        # 5. Upload
        print(f"🚀 Uploading to {REMOTE_PATH}...")
        sftp.put(LOCAL_PATH, REMOTE_PATH)
        sftp.close()
        print("Upload complete.")
        
        # 6. Restart
        print(f"🔄 Executing restart command: {RESTART_CMD}")
        stdin, stdout, stderr = ssh.exec_command(RESTART_CMD)
        exit_status = stdout.channel.recv_exit_status()
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        
        if exit_status == 0:
            print("✅ Restart successful.")
            print(out)
        else:
            print(f"❌ Restart failed (exit code {exit_status}).")
            print(f"Stdout: {out}")
            print(f"Stderr: {err}")
            sys.exit(exit_status)
            
    except Exception as e:
        print(f"❌ Deployment failed: {e}")
        sys.exit(1)
    finally:
        if ssh:
            ssh.close()
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == '__main__':
    deploy()
