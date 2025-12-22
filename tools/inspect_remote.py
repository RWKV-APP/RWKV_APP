import paramiko
import os

hostname = '114.67.216.121'
port = 22
username = 'rwkvuser'
password = 'rwkvuser@rwkvuserqnwi0n^!@&123'

def run_command(ssh, command):
    stdin, stdout, stderr = ssh.exec_command(command)
    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    return exit_status, out, err

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, port, username, password)

    print("Connected to server.")
    
    # Check target directory
    target_dir = '/opt/rwkv/apps/api-model'
    print(f"Listing {target_dir}:")
    status, out, err = run_command(ssh, f"ls -la {target_dir}")
    print(out)
    
    json_dir = '/opt/rwkv/apps/api-model/json'
    print(f"Listing {json_dir}:")
    status, out, err = run_command(ssh, f"ls -la {json_dir}")
    print(out)

    print("Checking PM2 list:")
    status, out, err = run_command(ssh, "/home/rwkvuser/.npm-global/bin/pm2 list") # Guessing path or trying standard
    if status != 0:
         status, out, err = run_command(ssh, "pm2 list")
    print(out)
    if err:
        print(f"PM2 stderr: {err}")

    ssh.close()
except Exception as e:
    print(f"Connection failed: {e}")

