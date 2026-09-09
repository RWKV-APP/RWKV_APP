#!/usr/bin/env python3
"""Validate the shared release identity before CI builds or Apple continuation."""

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
from urllib.parse import urljoin, urlparse
from urllib.request import url2pathname


APPLE_IDENTITY = Path('tools/output/apple-release-identity.json')
IOS_INFO = 'ios/mlx-swift_Cmlx.bundle/Info.plist'


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


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def require_clean(root, allow_artwork=False):
    paths = set(command('git', 'ls-files', '--modified', '--deleted', '--others', '--exclude-standard', '-z', cwd=root).split('\0'))
    paths.update(command('git', 'diff', '--cached', '--name-only', '-z', cwd=root).split('\0'))
    paths.discard('')
    if allow_artwork:
        # Keep the same generated-artwork boundary as release_git_staging.rb.
        paths = {p for p in paths if not re.search(r'\.(?:ico|png)$', p, re.I)
                 and not re.fullmatch(r'(?:ios|macos)/Runner/Assets\.xcassets/.+/Contents\.json', p)}
    if paths:
        raise RuntimeError('Preserve local source changes before release:\n' + '\n'.join(str(root / p) for p in sorted(paths)))


def verify_origin(root, repository):
    allowed = {f'https://github.com/{repository}', f'git@github.com:{repository}', f'ssh://git@github.com/{repository}'}
    for options in ((), ('--push',)):
        urls = command('git', 'remote', 'get-url', *options, '--all', 'origin', cwd=root).splitlines()
        if not urls or any(url.removesuffix('/').removesuffix('.git') not in allowed for url in urls):
            # Do not echo a potentially credential-bearing remote URL.
            raise RuntimeError(f'Unexpected origin {"push" if options else "fetch"} repository for {root.name}')


def remote_refs(repository, *refs):
    output = command('git', 'ls-remote', f'https://github.com/{repository}.git', *refs)
    return {ref: sha for sha, ref in (line.split() for line in output.splitlines())}


def peeled_tag(refs, tag):
    return refs.get(f'refs/tags/{tag}^{{}}', refs.get(f'refs/tags/{tag}'))


def check_apple_source(root, release):
    apple = release['apple']
    if apple['baseTag'] != release['version'] or not re.fullmatch(r'[0-9a-f]{40}', apple['baseCommit']):
        raise RuntimeError('Apple base tag/commit does not identify the frozen release')
    for branch in (apple['sourceBranch'], apple['integrationBranch'], release['adapter']['branch'], release['native']['branch']):
        command('git', 'check-ref-format', f'refs/heads/{branch}')
    verify_origin(root, 'RWKV-APP/RWKV_APP')
    if command('git', 'branch', '--show-current', cwd=root) != apple['sourceBranch']:
        raise RuntimeError(f"Check out the Apple source branch {apple['sourceBranch']}")
    require_clean(root)
    head = command('git', 'rev-parse', 'HEAD', cwd=root)
    refs = remote_refs('RWKV-APP/RWKV_APP', f"refs/heads/{apple['sourceBranch']}",
                       f"refs/heads/{apple['integrationBranch']}", f"refs/tags/{apple['baseTag']}", f"refs/tags/{apple['baseTag']}^{{}}")
    if refs.get(f"refs/heads/{apple['sourceBranch']}") != head:
        raise RuntimeError('Apple source HEAD differs from the current official remote branch tip')
    if peeled_tag(refs, apple['baseTag']) != apple['baseCommit']:
        raise RuntimeError('The published base tag moved or is missing')
    integration = refs.get(f"refs/heads/{apple['integrationBranch']}")
    if not integration:
        raise RuntimeError('The official integration branch is missing')
    for label, ancestor in (('integration branch', integration), ('published base', apple['baseCommit'])):
        # Remote comparison also works with a shallow local checkout, without fetching or changing refs.
        comparison = json.loads(command('gh', 'api', f'repos/RWKV-APP/RWKV_APP/compare/{ancestor}...{head}'))
        if comparison.get('status') not in ('identical', 'ahead') or comparison.get('merge_base_commit', {}).get('sha') != ancestor:
            raise RuntimeError(f'The current remote {label} is not contained in Apple source HEAD')
    adapter = root.parent / 'rwkv_mobile_flutter'
    verify_origin(adapter, release['adapter']['repository'])
    require_clean(adapter)
    for key in ('adapter', 'native'):
        dependency = release[key]
        wanted = [f"refs/heads/{dependency['branch']}"]
        if key == 'native':
            wanted += [f"refs/tags/{dependency['tag']}", f"refs/tags/{dependency['tag']}^{{}}"]
        refs = remote_refs(dependency['repository'], *wanted)
        if refs.get(wanted[0]) != dependency['commit']:
            raise RuntimeError(f'{key} remote release branch differs from the verified pin; refresh and verify the release identity')
        if key == 'native' and peeled_tag(refs, dependency['tag']) != dependency['commit']:
            raise RuntimeError('The pinned native tag moved or is missing')
    return head


def check_apple_environment(release):
    if sys.platform != 'darwin' or platform.machine().lower() != 'arm64':
        raise RuntimeError('Apple release requires an arm64 macOS host')
    for tool in ('flutter', 'xcodebuild', 'xcrun', 'pod', 'gh'):
        if shutil.which(tool) is None:
            raise RuntimeError(f'Apple release prerequisite is missing: {tool}')
    flutter = json.loads(command('flutter', '--version', '--machine'))
    if flutter['frameworkVersion'] != release['flutterVersion']:
        raise RuntimeError(f"Use Flutter {release['flutterVersion']} for this release")
    command('xcodebuild', '-version')
    for sdk in ('iphoneos', 'macosx'):
        if not Path(command('xcrun', '--sdk', sdk, '--show-sdk-path')).is_dir():
            raise RuntimeError(f'Xcode SDK is missing: {sdk}')
    command('pod', '--version')
    command('gh', 'auth', 'status', '--hostname', 'github.com')
    for channel, module in (('huggingface', 'huggingface_hub'), ('modelscope', 'modelscope_hub')):
        if release['channels'][channel] and importlib.util.find_spec(module) is None:
            raise RuntimeError(f'Apple publication prerequisite is missing from this Python interpreter: {module}')


def apple_native_files(adapter, release):
    if command('git', 'rev-parse', 'HEAD', cwd=adapter) != release['adapter']['commit']:
        raise RuntimeError('The actual adapter checkout differs from the frozen commit')
    require_clean(adapter)
    native = json.loads((adapter / 'native-libraries.json').read_text(encoding='utf-8'))
    if any(native[key] != release['native'][key] for key in ('repository', 'tag', 'commit')):
        raise RuntimeError('Adapter native libraries differ from the frozen release')
    rows = []
    for target in ('ios', 'macos'):
        asset = native['platforms'][target]
        if not re.fullmatch(r'[0-9a-f]{64}', asset['sha256']) or not asset['files']:
            raise RuntimeError(f'Incomplete pinned native archive: {target}')
        for info in asset['files'].values():
            relative = info['path']
            if not relative.startswith(target + '/') or any(part in ('', '.', '..') for part in relative.split('/')) or re.search(r'[\\:\x00-\x1f]', relative):
                raise RuntimeError('Invalid relative Apple native path')
            path = adapter / relative
            if path.is_symlink() or not path.resolve().is_relative_to(adapter.resolve()) or not path.is_file() or path.stat().st_size != info['size'] or file_sha256(path) != info['sha256']:
                raise RuntimeError(f'Apple native file differs from the pinned size/SHA: {path}')
            rows.append(dict(platform=target, path=relative, size=info['size'], sha256=info['sha256']))
    # This packaging plist is tracked in the adapter; it is not part of the native iOS ZIP.
    blob = subprocess.check_output(['git', 'show', f"{release['adapter']['commit']}:{IOS_INFO}"], cwd=adapter)
    info_path = adapter / IOS_INFO
    if info_path.is_symlink() or not info_path.is_file() or info_path.read_bytes() != blob:
        raise RuntimeError(f'iOS bundle metadata differs from the pinned adapter Git blob: {info_path}')
    rows.append(dict(platform='ios', path=IOS_INFO, size=len(blob), sha256=hashlib.sha256(blob).hexdigest()))
    allowed = {row['path'] for row in rows}
    packaged = list((adapter / 'ios').glob('*.a')) + list((adapter / 'macos').glob('*.dylib'))
    for target in ('ios', 'macos'):
        packaged += [p for p in (adapter / target / 'mlx-swift_Cmlx.bundle').rglob('*') if p.is_file() or p.is_symlink()]
    extras = sorted(str(p) for p in packaged if p.is_symlink() or p.relative_to(adapter).as_posix() not in allowed)
    if extras:
        raise RuntimeError('Unexpected native files would enter the Apple package; preserve or remove these exact files:\n' + '\n'.join(extras))
    return sorted(rows, key=lambda row: (row['platform'], row['path']))


def apple_identity(root, release):
    adapter = root.parent / 'rwkv_mobile_flutter'
    return dict(sourceCommit=command('git', 'rev-parse', 'HEAD', cwd=root),
                releaseManifestSha256=file_sha256(root / 'release.json'), adapterCommit=release['adapter']['commit'],
                nativeCommit=release['native']['commit'], nativeTag=release['native']['tag'],
                nativeFiles=apple_native_files(adapter, release), version=release['version'], build=release['build'])


def prepare_apple(root, release):
    check_apple_environment(release)
    source_head = check_apple_source(root, release)
    published = json.loads(command('gh', 'release', 'view', release['version'], '--repo', 'RWKV-APP/RWKV_APP', '--json', 'isDraft,tagName'))
    if published['isDraft'] or published['tagName'] != release['version']:
        raise RuntimeError('The base GitHub release must already be published')
    adapter = root.parent / 'rwkv_mobile_flutter'
    sha = release['adapter']['commit']
    if command('git', 'rev-parse', 'HEAD', cwd=adapter) != sha:
        subprocess.run(['git', 'fetch', 'origin', sha], cwd=adapter, check=True)
        subprocess.run(['git', 'checkout', '--detach', sha], cwd=adapter, check=True)
    require_clean(adapter)
    native = json.loads((adapter / 'native-libraries.json').read_text(encoding='utf-8'))
    if any(native[key] != release['native'][key] for key in ('repository', 'tag', 'commit')):
        raise RuntimeError('Adapter native libraries differ from the frozen release')
    subprocess.run([sys.executable, str(adapter / 'tools/fetch_native_libraries.py'), '--platform', 'ios', '--platform', 'macos'], check=True)
    require_clean(root)
    if command('git', 'rev-parse', 'HEAD', cwd=root) != source_head or command('git', 'branch', '--show-current', cwd=root) != release['apple']['sourceBranch']:
        raise RuntimeError('Apple source changed while preparing native libraries; restart from the source preflight')
    identity = apple_identity(root, release)
    output = root / APPLE_IDENTITY
    output.parent.mkdir(parents=True, exist_ok=True)
    pending = output.with_suffix('.tmp')
    pending.write_text(json.dumps(identity, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    pending.replace(output)
    return identity


def verify_package_bindings(root, target, require_pods=False):
    adapter = (root.parent / 'rwkv_mobile_flutter').resolve()
    config_path = root / '.dart_tool/package_config.json'
    config = json.loads(config_path.read_text(encoding='utf-8'))
    packages = [p for p in config['packages'] if p['name'] == 'rwkv_mobile_flutter']
    if len(packages) != 1:
        raise RuntimeError('package_config must resolve exactly one rwkv_mobile_flutter')
    uri = urlparse(urljoin(config_path.resolve().as_uri(), packages[0]['rootUri']))
    if uri.scheme != 'file' or uri.netloc not in ('', 'localhost') or uri.query or uri.fragment or Path(url2pathname(uri.path)).resolve() != adapter:
        raise RuntimeError('package_config resolves a different adapter than the verified sibling')
    plugins = json.loads((root / '.flutter-plugins-dependencies').read_text(encoding='utf-8'))
    selected = [p for p in plugins['plugins'].get(target, []) if p['name'] == 'rwkv_mobile_flutter']
    if len(selected) != 1 or Path(selected[0]['path']).resolve() != adapter:
        raise RuntimeError('Flutter plugin metadata resolves a different adapter than the verified sibling')
    pod_link = root / ('ios/.symlinks/plugins/rwkv_mobile_flutter' if target == 'ios'
                       else 'macos/Flutter/ephemeral/.symlinks/plugins/rwkv_mobile_flutter')
    present = pod_link.exists() or pod_link.is_symlink()
    if (require_pods and not present) or (present and pod_link.resolve() != adapter):
        raise RuntimeError(f'Apple Pod symlink is missing or resolves a different adapter: {pod_link}')


def verify_apple_build_inputs(root, release, target, require_pods=False):
    verify_origin(root, 'RWKV-APP/RWKV_APP')
    verify_origin(root.parent / 'rwkv_mobile_flutter', release['adapter']['repository'])
    if command('git', 'branch', '--show-current', cwd=root) != release['apple']['sourceBranch']:
        raise RuntimeError('The Apple source branch changed after preparation')
    require_clean(root, allow_artwork=True)
    expected = json.loads((root / APPLE_IDENTITY).read_text(encoding='utf-8'))
    if apple_identity(root, release) != expected:
        raise RuntimeError('Apple source/release manifest/adapter/native bytes differ from the prepared identity')
    verify_package_bindings(root, target, require_pods)
    return expected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--github-output')
    parser.add_argument('--prepare-apple', action='store_true')
    parser.add_argument('--check-apple-source', action='store_true')
    parser.add_argument('--check-apple-environment', action='store_true')
    parser.add_argument('--verify-apple-build-inputs', action='store_true')
    parser.add_argument('--platform', choices=('ios', 'macos'))
    parser.add_argument('--require-pods', action='store_true')
    parser.add_argument('--upload-github', action='append', help='Upload matching files into the existing release without changing publication state')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    release = load_release(root)
    requested_tag = os.environ.get('RWKV_RELEASE_TAG') or (os.environ.get('GITHUB_REF_NAME') if os.environ.get('GITHUB_REF_TYPE') == 'tag' else '')
    if requested_tag and requested_tag != release['version']:
        raise ValueError('Requested tag differs from the frozen release version')
    if args.verify_apple_build_inputs and not args.platform:
        parser.error('--verify-apple-build-inputs requires --platform ios or macos')
    if args.check_apple_source:
        check_apple_source(root, release)
    if args.check_apple_environment:
        check_apple_environment(release)
    if args.prepare_apple:
        prepare_apple(root, release)
    if args.verify_apple_build_inputs:
        verify_apple_build_inputs(root, release, args.platform, args.require_pods)
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
