#!/usr/bin/env python3
"""Validate the shared release identity before CI builds or Apple continuation."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def command(*args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def load_release(root):
    release = json.loads((root / 'release.json').read_text(encoding='utf-8'))
    version = release['version']
    build = release['build']
    if not re.fullmatch(r'\d+\.\d+\.\d+', release['flutterVersion']):
        raise ValueError('A fixed Flutter version is required')
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or type(build) is not int or build < 1:
        raise ValueError('Invalid release version/build')
    actual = re.search(r'^version:\s*(\S+)', (root / 'pubspec.yaml').read_text(encoding='utf-8'), re.M)
    if actual is None or actual[1] != f'{version}+{build}':
        raise ValueError('release.json and pubspec.yaml version/build differ')
    for key in ('adapter', 'native'):
        if not re.fullmatch(r'[0-9a-f]{40}', release[key]['commit']):
            raise ValueError(f'{key} must use a full commit SHA')
    if release['adapter']['repository'] != 'RWKV-APP/rwkv_mobile_flutter' or release['native']['repository'] != 'RWKV-APP/rwkv-mobile':
        raise ValueError('Unexpected release dependency repository')
    if not re.fullmatch(r'v?[0-9][0-9A-Za-z._-]*', release['native']['tag']):
        raise ValueError('Native libraries must use an immutable version tag')
    for key in ('github', 'modelscope', 'huggingface'):
        if type(release['channels'][key]) is not bool:
            raise ValueError(f'Invalid channel flag: {key}')
    return release


def upload_github(release, files):
    repository = 'RWKV-APP/RWKV_APP'
    tag = release['version']
    for file in files:
        digest = hashlib.sha256()
        with file.open('rb') as stream:
            for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b''):
                digest.update(chunk)
        expected = 'sha256:' + digest.hexdigest()
        def existing():
            published = json.loads(command('gh', 'release', 'view', tag, '--repo', repository, '--json', 'tagName,assets'))
            if published['tagName'] != tag:
                raise ValueError('Unexpected GitHub release tag')
            return next((asset for asset in published['assets'] if asset['name'] == file.name), None)
        asset = existing()
        if asset is None:
            subprocess.run(['gh', 'release', 'upload', tag, str(file), '--repo', repository], check=True)
            asset = existing()
        if asset is None or asset['size'] != file.stat().st_size or asset.get('digest') != expected:
            raise ValueError(f'GitHub asset differs from the release file; refusing replacement: {file.name}')
        print(f'GitHub verified: {file.name} {expected}')


def prepare_apple(root, release):
    if sys.platform != 'darwin':
        raise RuntimeError('Apple release requires macOS')
    flutter = json.loads(command('flutter', '--version', '--machine'))
    if flutter['frameworkVersion'] != release['flutterVersion']:
        raise RuntimeError(f"Use Flutter {release['flutterVersion']} for this release")
    if command('git', 'status', '--porcelain', cwd=root):
        raise RuntimeError('Commit or preserve local App changes before continuing this release')
    version = release['version']
    refs = command('git', 'ls-remote', 'https://github.com/RWKV-APP/RWKV_APP.git', f'refs/tags/{version}', f'refs/tags/{version}^{{}}')
    tag = {ref: sha for sha, ref in (line.split() for line in refs.splitlines())}
    expected = tag.get(f'refs/tags/{version}^{{}}', tag.get(f'refs/tags/{version}'))
    if not expected or command('git', 'rev-parse', 'HEAD', cwd=root) != expected:
        raise RuntimeError(f'Check out the published App tag {version} before running fastlane apple')
    published = json.loads(command('gh', 'release', 'view', version, '--repo', 'RWKV-APP/RWKV_APP', '--json', 'isDraft,tagName'))
    if published['isDraft'] or published['tagName'] != version:
        raise RuntimeError('The base GitHub release must already be published')
    adapter = root.parent / 'rwkv_mobile_flutter'
    remote = command('git', 'remote', 'get-url', 'origin', cwd=adapter).removesuffix('.git')
    if remote not in ('https://github.com/RWKV-APP/rwkv_mobile_flutter', 'git@github.com:RWKV-APP/rwkv_mobile_flutter'):
        raise RuntimeError('Unexpected adapter remote')
    if command('git', 'status', '--porcelain', cwd=adapter):
        raise RuntimeError('Preserve local adapter changes before continuing this release')
    sha = release['adapter']['commit']
    if command('git', 'rev-parse', 'HEAD', cwd=adapter) != sha:
        subprocess.run(['git', 'fetch', 'origin', sha], cwd=adapter, check=True)
        subprocess.run(['git', 'checkout', '--detach', sha], cwd=adapter, check=True)
    native = json.loads((adapter / 'native-libraries.json').read_text())
    if any(native[key] != release['native'][key] for key in ('repository', 'tag', 'commit')):
        raise RuntimeError('Adapter native libraries differ from the frozen release')
    subprocess.run([sys.executable, str(adapter / 'tools/fetch_native_libraries.py'), '--platform', 'ios', '--platform', 'macos'], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--github-output')
    parser.add_argument('--prepare-apple', action='store_true')
    parser.add_argument('--upload-github', action='append', help='Upload matching files into the existing release without changing publication state')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    release = load_release(root)
    requested_tag = os.environ.get('RWKV_RELEASE_TAG') or (os.environ.get('GITHUB_REF_NAME') if os.environ.get('GITHUB_REF_TYPE') == 'tag' else '')
    if requested_tag and requested_tag != release['version']:
        raise ValueError('Requested tag differs from the frozen release version')
    if args.prepare_apple:
        prepare_apple(root, release)
    if args.upload_github:
        for pattern in args.upload_github:
            files = sorted(Path.cwd().glob(pattern))
            if not files or any(not file.is_file() for file in files):
                raise ValueError(f'No release files match {pattern}')
            upload_github(release, files)
    if args.github_output:
        with open(args.github_output, 'a', encoding='utf-8') as output:
            output.write(f"adapter_ref={release['adapter']['commit']}\n")
            output.write(f"flutter_version={release['flutterVersion']}\n")
            for key in ('modelscope', 'huggingface'):
                output.write(f"upload_{key}={str(release['channels'][key]).lower()}\n")
    print(json.dumps(release))


if __name__ == '__main__':
    main()
