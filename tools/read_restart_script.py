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

    file_path = '/opt/rwkv/apps/api-model/json/restart_server.sh'
    print(f"Reading {file_path}:")
    status, out, err = run_command(ssh, f"cat {file_path}")
    print(out)
    
    ssh.close()
except Exception as e:
    print(f"Connection failed: {e}")

