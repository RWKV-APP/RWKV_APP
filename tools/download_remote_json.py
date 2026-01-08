import os
import sys
import paramiko
from dotenv import load_dotenv

# Load environment variables from .env file
# Try loading from project root or tools directory
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(project_root, ".env"))

# Configuration (same as deploy script)
HOSTNAME = os.getenv("RWKV_REMOTE_HOST")
PORT = int(os.getenv("RWKV_REMOTE_PORT", 22))
USERNAME = os.getenv("RWKV_REMOTE_USER")
PASSWORD = os.getenv("RWKV_REMOTE_PASS")

# Remote directory which holds all the JSON/config files
REMOTE_DIR = "/opt/rwkv/apps/api-model/json"

# Local directory to store downloaded files (this repo's /remote)
LOCAL_DIR = os.path.join(project_root, "remote")


def download_all():
    # Check for missing credentials
    if not all([HOSTNAME, USERNAME, PASSWORD]):
        print("❌ Error: Missing configuration. Please set RWKV_REMOTE_HOST, RWKV_REMOTE_USER, and RWKV_REMOTE_PASS in your .env file.")
        sys.exit(1)

    # Ensure local directory exists
    os.makedirs(LOCAL_DIR, exist_ok=True)

    print(f"Connecting to {HOSTNAME}...")
    ssh = None
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(HOSTNAME, PORT, USERNAME, PASSWORD)

        sftp = ssh.open_sftp()

        print(f"Listing remote directory: {REMOTE_DIR}")
        try:
            entries = sftp.listdir_attr(REMOTE_DIR)
        except FileNotFoundError:
            print(f"❌ Remote directory not found: {REMOTE_DIR}")
            sftp.close()
            return

        if not entries:
            print("Remote directory is empty.")
            sftp.close()
            return

        print("The following remote files will be downloaded:")
        files = []
        for attr in sorted(entries, key=lambda x: x.filename):
            # Skip directories; only download regular files.
            # S_ISDIR uses stat.S_ISDIR, but we avoid importing stat by relying on st_mode bit 0o170000.
            mode = attr.st_mode
            is_dir = (mode & 0o170000) == 0o040000
            if is_dir:
                continue

            # Skip suggestions.json
            if attr.filename == "suggestions.json":
                continue

            remote_path = os.path.join(REMOTE_DIR, attr.filename)
            local_path = os.path.join(LOCAL_DIR, attr.filename)
            files.append((remote_path, local_path))
            print(f"  - {remote_path} -> {local_path}")

        if not files:
            print("No regular files to download.")
            sftp.close()
            return

        print("\nDownloading files...")
        for remote_path, local_path in files:
            print(f"  - {remote_path} -> {local_path}")
            sftp.get(remote_path, local_path)

        sftp.close()
        print("✅ Download complete.")

    except Exception as e:
        print(f"❌ Download failed: {e}")
        sys.exit(1)
    finally:
        if ssh:
            ssh.close()


if __name__ == "__main__":
    download_all()
