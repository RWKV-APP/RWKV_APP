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
load_dotenv(os.path.join(project_root, ".env"))

# Configuration
HOSTNAME = os.getenv("RWKV_REMOTE_HOST")
PORT = int(os.getenv("RWKV_REMOTE_PORT", 22))
USERNAME = os.getenv("RWKV_REMOTE_USER")
PASSWORD = os.getenv("RWKV_REMOTE_PASS")

# Remote directory which holds all the JSON config files
REMOTE_DIR = "/opt/rwkv/apps/api-model/json"

# Local directory which holds all the JSON config files (this repo's /remote)
LOCAL_DIR = os.path.join(project_root, "remote")

RESTART_CMD = "pm2 reload api-model"


def deploy():
    # Check for missing credentials
    if not all([HOSTNAME, USERNAME, PASSWORD]):
        print("❌ Error: Missing configuration. Please set RWKV_REMOTE_HOST, RWKV_REMOTE_USER, and RWKV_REMOTE_PASS in your .env file.")
        sys.exit(1)

    parser = argparse.ArgumentParser(description="Deploy all JSON files in ./remote to remote server with diff check.")
    parser.add_argument("-y", "--yes", action="store_true", help="Skip confirmation prompt and overwrite")
    parser.add_argument("--diff-only", action="store_true", help="Download remote files, show diff, and exit without uploading")
    args = parser.parse_args()

    # 1. Collect local JSON files
    if not os.path.isdir(LOCAL_DIR):
        print(f"❌ Error: Local directory not found: {LOCAL_DIR}")
        sys.exit(1)

    local_files = []
    for name in sorted(os.listdir(LOCAL_DIR)):
        path = os.path.join(LOCAL_DIR, name)
        if not os.path.isfile(path):
            continue
        # Only sync JSON files, skip things like README.md / .DS_Store
        if not name.lower().endswith(".json"):
            continue
        local_files.append((name, path))

    if not local_files:
        print(f"❌ Error: No JSON files found in {LOCAL_DIR}")
        sys.exit(1)

    # 2. Validate all local JSON files
    print(f"Validating JSON files in {LOCAL_DIR}...")
    has_error = False
    for name, path in local_files:
        print(f"  - {path}")
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            json.loads(content)
        except Exception as e:
            has_error = True
            print(f"    ❌ Invalid JSON: {e}")

    if has_error:
        print("❌ One or more JSON files are invalid. Fix them before deploying.")
        sys.exit(1)
    else:
        print("✅ All local JSON files are valid.")

    # 3. Connect
    print(f"Connecting to {HOSTNAME}...")
    ssh = None
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(HOSTNAME, PORT, USERNAME, PASSWORD)

        sftp = ssh.open_sftp()

        # 4. Compare each local file with its remote counterpart
        files_to_upload = []
        any_diff = False

        print(f"Comparing local JSON files with remote directory {REMOTE_DIR} ...")
        for name, local_path in local_files:
            remote_path = os.path.join(REMOTE_DIR, name)
            print(f"\n=== {name} ===")

            with open(local_path, "r", encoding="utf-8") as f:
                local_content = f.read()

            remote_content = ""
            tmp_path = None
            try:
                with tempfile.NamedTemporaryFile(mode="w+", delete=False) as tmp:
                    tmp_path = tmp.name
                sftp.get(remote_path, tmp_path)
                with open(tmp_path, "r", encoding="utf-8") as f:
                    remote_content = f.read()
            except FileNotFoundError:
                print("Remote file not found. This will be a new file.")
            except Exception as e:
                print(f"Error downloading remote file: {e}")
            finally:
                if tmp_path and os.path.exists(tmp_path):
                    os.remove(tmp_path)

            if local_content == remote_content:
                print("✅ Remote file is identical to local file.")
            else:
                any_diff = True
                print("⚠️ Differences found (Local vs Remote):")
                diff = difflib.unified_diff(remote_content.splitlines(keepends=True), local_content.splitlines(keepends=True), fromfile=f"Remote ({remote_path})", tofile=f"Local ({local_path})")
                diff_text = "".join(diff)
                if diff_text:
                    print(diff_text)
                else:
                    print("(Files differ but unified_diff is empty - likely line ending or encoding differences)")

                files_to_upload.append((local_path, remote_path))

        if args.diff_only:
            # Only show diffs, do not upload or restart
            sftp.close()
            if not any_diff:
                print("\n✅ All remote JSON files are identical to local files.")
            return

        if not files_to_upload:
            sftp.close()
            print("\n✅ All remote JSON files are identical to local files. Nothing to upload.")
        else:
            print("\nThe following files will be uploaded:")
            for local_path, remote_path in files_to_upload:
                print(f"  - {local_path} -> {remote_path}")

            if not args.yes:
                # Interactive confirmation (single prompt for all files)
                try:
                    confirm = input("Do you want to overwrite the above remote files? (y/N): ")
                    if confirm.lower() != "y":
                        print("Deployment aborted by user.")
                        sftp.close()
                        return
                except EOFError:
                    print("\nNon-interactive mode detected. Use --yes to force overwrite.")
                    sftp.close()
                    return

            # 5. Upload all changed files
            print("\n🚀 Uploading files...")
            for local_path, remote_path in files_to_upload:
                print(f"  - {local_path} -> {remote_path}")
                sftp.put(local_path, remote_path)

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


if __name__ == "__main__":
    deploy()
