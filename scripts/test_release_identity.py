import json
import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from release_identity import (APPLE_IDENTITY, IOS_INFO, apple_identity, apple_native_files,
                              check_apple_environment, check_apple_source, load_release,
                              prepare_apple, upload_github, verify_apple_build_inputs,
                              verify_package_bindings)


class ReleaseIdentityTest(unittest.TestCase):
    def test_github_resume_verifies_bytes_without_replacing_or_publishing(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'release.zip'
            file.write_bytes(b'accepted release')
            asset = dict(name=file.name, size=file.stat().st_size, digest='sha256:' + hashlib.sha256(file.read_bytes()).hexdigest())
            with patch('release_identity.command', return_value=json.dumps(dict(tagName='4.8.0', assets=[asset]))), patch('release_identity.subprocess.run') as mutate:
                upload_github(dict(version='4.8.0'), [file])
                mutate.assert_not_called()
                file.write_bytes(b'different release')
                with self.assertRaisesRegex(ValueError, 'refusing replacement'):
                    upload_github(dict(version='4.8.0'), [file])
                mutate.assert_not_called()

    def test_rejects_version_and_mutable_dependency_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            root.joinpath('pubspec.yaml').write_text('version: 4.8.0+755\n')
            release = dict(version='4.8.0', build=755, flutterVersion='3.47.2',
                           adapter=dict(repository='RWKV-APP/rwkv_mobile_flutter', commit='a' * 40),
                           native=dict(repository='RWKV-APP/rwkv-mobile', commit='b' * 40, tag='v4.8.0-native.1'),
                           channels=dict(github=True, modelscope=True, huggingface=False))
            def write():
                root.joinpath('release.json').write_text(json.dumps(release))
            write()
            self.assertEqual(755, load_release(root)['build'])
            release['build'] = 756
            write()
            with self.assertRaisesRegex(ValueError, 'differ'):
                load_release(root)
            release['build'] = 755
            release['adapter']['commit'] = 'dev'
            write()
            with self.assertRaisesRegex(ValueError, 'full commit'):
                load_release(root)
            release['adapter']['commit'] = 'a' * 40
            release['native']['tag'] = 'latest'
            write()
            with self.assertRaisesRegex(ValueError, 'immutable'):
                load_release(root)


class AppleReleaseGuardTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name) / 'rwkv_app'
        self.adapter = self.root.parent / 'rwkv_mobile_flutter'
        self.root.mkdir()
        self.adapter.mkdir()
        self.head = 'a' * 40
        self.adapter_head = 'c' * 40
        self.branch = 'codex/apple-release-4.8.0'
        self.dirty = {}
        self.remotes = {}
        self.contained = True
        self.flutter = '3.47.2'
        self.info_blob = b'pinned adapter bundle plist'
        self.release = dict(version='4.8.0', build=755, flutterVersion=self.flutter,
                            apple=dict(sourceBranch=self.branch, integrationBranch='dev', baseTag='4.8.0', baseCommit='b' * 40),
                            adapter=dict(repository='RWKV-APP/rwkv_mobile_flutter', branch='dev', commit=self.adapter_head),
                            native=dict(repository='RWKV-APP/rwkv-mobile', branch='codex/palm-release-4.8.0', commit='d' * 40, tag='4.8.0-native.4'),
                            channels=dict(github=True, modelscope=True, huggingface=True))
        self.refs = {
            'RWKV_APP': {f'refs/heads/{self.branch}': self.head, 'refs/heads/dev': 'f' * 40,
                         'refs/tags/4.8.0': 'b' * 40},
            'rwkv_mobile_flutter': {'refs/heads/dev': 'c' * 40},
            'rwkv-mobile': {'refs/heads/codex/palm-release-4.8.0': 'd' * 40, 'refs/tags/4.8.0-native.4': 'd' * 40}}
        self.root.joinpath('release.json').write_text(json.dumps(self.release), encoding='utf-8')
        self.root.joinpath('pubspec.yaml').write_text('version: 4.8.0+755\n', encoding='utf-8')
        native = {key: self.release['native'][key] for key in ('repository', 'tag', 'commit')}
        native['platforms'] = {}
        for target, paths in {'ios': ['librwkv_mobile.a', 'libncnn.a', 'libMLXModelFFI.a', 'mlx-swift_Cmlx.bundle/default.metallib'],
                              'macos': ['librwkv_mobile.dylib', 'mlx-swift_Cmlx.bundle/Contents/Info.plist', 'mlx-swift_Cmlx.bundle/Contents/Resources/default.metallib']}.items():
            files = {}
            for name in paths:
                relative = f'{target}/{name}'
                data = relative.encode()
                path = self.adapter / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                files[name] = dict(path=relative, size=len(data), sha256=hashlib.sha256(data).hexdigest())
            native['platforms'][target] = dict(archive=f'{target}.zip', sha256='e' * 64, files=files)
        self.adapter.joinpath('native-libraries.json').write_text(json.dumps(native), encoding='utf-8')
        self.adapter.joinpath(IOS_INFO).write_bytes(self.info_blob)
        self.write_bindings()
        self.commands = []
        mocked = patch('release_identity.command', side_effect=self.command)
        mocked.start()
        self.addCleanup(mocked.stop)
        blob = patch('release_identity.subprocess.check_output', side_effect=lambda *a, **k: self.info_blob)
        blob.start()
        self.addCleanup(blob.stop)

    def write_bindings(self):
        config = self.root / '.dart_tool/package_config.json'
        config.parent.mkdir(exist_ok=True)
        config.write_text(json.dumps(dict(packages=[dict(name='rwkv_mobile_flutter', rootUri='../../rwkv_mobile_flutter')])), encoding='utf-8')
        self.root.joinpath('.flutter-plugins-dependencies').write_text(json.dumps(dict(plugins={
            target: [dict(name='rwkv_mobile_flutter', path=str(self.adapter))] for target in ('ios', 'macos')})), encoding='utf-8')

    def command(self, *args, cwd=None):
        self.commands.append(args)
        if args[:3] == ('git', 'remote', 'get-url'):
            repo = 'RWKV_APP' if cwd == self.root else 'rwkv_mobile_flutter'
            return self.remotes.get((repo, '--push' in args), f'https://github.com/RWKV-APP/{repo}.git')
        if args[:2] == ('git', 'ls-files'):
            return '\0'.join(self.dirty.get(cwd, [])) + '\0'
        if args[:2] == ('git', 'diff'):
            return ''
        if args[:2] == ('git', 'branch'):
            return self.branch
        if args[:2] == ('git', 'rev-parse'):
            return self.head if cwd == self.root else self.adapter_head
        if args[:2] == ('git', 'check-ref-format'):
            return ''
        if args[:2] == ('git', 'ls-remote'):
            repo = args[2].split('/')[-1].removesuffix('.git')
            return '\n'.join(f'{sha}\t{ref}' for ref, sha in self.refs[repo].items())
        if args[:2] == ('gh', 'api'):
            ancestor = args[2].split('/')[-1].split('...')[0]
            return json.dumps(dict(status='ahead' if self.contained else 'diverged', merge_base_commit=dict(sha=ancestor)))
        if args[:3] == ('gh', 'release', 'view'):
            return json.dumps(dict(isDraft=False, tagName='4.8.0'))
        if args[0] == 'flutter':
            return json.dumps(dict(frameworkVersion=self.flutter))
        if args[0] == 'xcrun':
            return str(self.root)
        if args[0] in ('xcodebuild', 'pod') or args[:2] == ('gh', 'auth'):
            return 'available'
        raise AssertionError(f'Unexpected command: {args}')

    def save_identity(self):
        identity = apple_identity(self.root, self.release)
        path = self.root / APPLE_IDENTITY
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(identity), encoding='utf-8')
        return identity

    def test_source_gate_is_read_only_and_rejects_fetch_or_push_remote_drift(self):
        with patch('release_identity.subprocess.run') as mutate:
            self.assertEqual(self.head, check_apple_source(self.root, self.release))
            mutate.assert_not_called()
            for repo in ('RWKV_APP', 'rwkv_mobile_flutter'):
                for push in (False, True):
                    self.remotes[(repo, push)] = 'https://secret@example.com/unexpected/repo.git'
                    with self.assertRaisesRegex(RuntimeError, 'Unexpected origin') as error:
                        check_apple_source(self.root, self.release)
                    self.assertNotIn('secret', str(error.exception))
                    self.remotes.clear()

    def test_source_rejects_wrong_branch_dirty_source_stale_tip_or_missing_ancestor(self):
        self.branch = 'dev'
        with self.assertRaisesRegex(RuntimeError, 'source branch'):
            check_apple_source(self.root, self.release)
        self.branch = self.release['apple']['sourceBranch']
        self.dirty[self.root] = ['lib/changed.dart']
        with self.assertRaisesRegex(RuntimeError, 'changed.dart'):
            check_apple_source(self.root, self.release)
        self.dirty.clear()
        self.head = '9' * 40
        with self.assertRaisesRegex(RuntimeError, 'remote branch tip'):
            check_apple_source(self.root, self.release)
        self.head = 'a' * 40
        self.contained = False
        with self.assertRaisesRegex(RuntimeError, 'not contained'):
            check_apple_source(self.root, self.release)

    def test_moved_base_dependency_branches_and_peeled_native_tag_fail_closed(self):
        for repo, ref in [('RWKV_APP', 'refs/tags/4.8.0'), ('rwkv_mobile_flutter', 'refs/heads/dev'),
                          ('rwkv-mobile', 'refs/heads/codex/palm-release-4.8.0'),
                          ('rwkv-mobile', 'refs/tags/4.8.0-native.4^{}')]:
            prior = self.refs[repo].get(ref)
            self.refs[repo][ref] = '9' * 40
            with self.assertRaises(RuntimeError):
                check_apple_source(self.root, self.release)
            if prior is None:
                del self.refs[repo][ref]
            else:
                self.refs[repo][ref] = prior

    def test_native_hashes_tracked_plist_and_extra_packaged_library_are_checked(self):
        rows = apple_native_files(self.adapter, self.release)
        self.assertEqual(8, len(rows))
        self.assertEqual(rows, sorted(rows, key=lambda row: (row['platform'], row['path'])))
        path = self.adapter / 'macos/librwkv_mobile.dylib'
        original = path.read_bytes()
        path.write_bytes(b'x' * len(original))
        with self.assertRaisesRegex(RuntimeError, 'size/SHA'):
            apple_native_files(self.adapter, self.release)
        path.write_bytes(original)
        self.adapter.joinpath(IOS_INFO).write_bytes(b'old plist')
        with self.assertRaisesRegex(RuntimeError, 'pinned adapter Git blob'):
            apple_native_files(self.adapter, self.release)
        self.adapter.joinpath(IOS_INFO).write_bytes(self.info_blob)
        extra = self.adapter / 'macos/old-runtime.dylib'
        extra.write_bytes(b'old runtime')
        with self.assertRaisesRegex(RuntimeError, 'Unexpected native files') as error:
            apple_native_files(self.adapter, self.release)
        self.assertIn(str(extra), str(error.exception))
        self.assertTrue(extra.is_file())

    def test_prepare_writes_public_identity_and_fetches_only_apple_platforms(self):
        self.adapter_head = '9' * 40
        def mutate(args, **kwargs):
            if args[:3] == ['git', 'checkout', '--detach']:
                self.adapter_head = args[3]
        with patch('release_identity.check_apple_environment'), patch('release_identity.subprocess.run', side_effect=mutate) as run:
            identity = prepare_apple(self.root, self.release)
        self.assertEqual(3, run.call_count)
        self.assertEqual(['--platform', 'ios', '--platform', 'macos'], run.call_args.args[0][-4:])
        self.assertEqual({'sourceCommit', 'releaseManifestSha256', 'adapterCommit', 'nativeCommit', 'nativeTag', 'nativeFiles', 'version', 'build'}, set(identity))
        stored = (self.root / APPLE_IDENTITY).read_text(encoding='utf-8')
        self.assertNotIn(str(self.root.parent), stored)
        self.assertEqual(identity, json.loads(stored))
        self.assertEqual(8, len(identity['nativeFiles']))

    def test_manifest_native_drift_stops_before_fetch(self):
        path = self.adapter / 'native-libraries.json'
        native = json.loads(path.read_text())
        native['commit'] = '9' * 40
        path.write_text(json.dumps(native))
        with patch('release_identity.check_apple_environment'), patch('release_identity.subprocess.run') as run:
            with self.assertRaisesRegex(RuntimeError, 'differ from the frozen release'):
                prepare_apple(self.root, self.release)
            run.assert_not_called()

    def test_prepare_rejects_source_changes_during_native_download_before_writing_identity(self):
        for kind in ('commit', 'branch', 'dirty'):
            self.head = 'a' * 40
            self.branch = self.release['apple']['sourceBranch']
            self.dirty.clear()
            def change_source(*args, **kwargs):
                if kind == 'commit':
                    self.head = '9' * 40
                elif kind == 'branch':
                    self.branch = 'dev'
                else:
                    self.dirty[self.root] = ['lib/changed-during-fetch.dart']
            with patch('release_identity.check_apple_environment'), patch('release_identity.subprocess.run', side_effect=change_source):
                with self.assertRaises(RuntimeError):
                    prepare_apple(self.root, self.release)
            self.assertFalse((self.root / APPLE_IDENTITY).exists())

    def test_verify_inputs_accepts_generated_artwork_but_rejects_code_or_identity_drift(self):
        expected = self.save_identity()
        self.dirty[self.root] = ['assets/icon.PNG', 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json']
        self.assertEqual(expected, verify_apple_build_inputs(self.root, self.release, 'ios'))
        self.dirty[self.root].append('lib/chat.dart')
        with self.assertRaisesRegex(RuntimeError, 'chat.dart'):
            verify_apple_build_inputs(self.root, self.release, 'ios')
        self.dirty.clear()
        self.head = '9' * 40
        with self.assertRaisesRegex(RuntimeError, 'prepared identity'):
            verify_apple_build_inputs(self.root, self.release, 'ios')
        self.head = 'a' * 40
        with self.root.joinpath('release.json').open('a') as stream:
            stream.write('\n')
        with self.assertRaisesRegex(RuntimeError, 'prepared identity'):
            verify_apple_build_inputs(self.root, self.release, 'ios')

    def test_package_and_plugin_resolution_must_match_the_verified_sibling(self):
        config_path = self.root / '.dart_tool/package_config.json'
        config = json.loads(config_path.read_text())
        config['packages'][0]['rootUri'] = '../../other-adapter'
        config_path.write_text(json.dumps(config))
        with self.assertRaisesRegex(RuntimeError, 'package_config resolves'):
            verify_package_bindings(self.root, 'ios')
        self.write_bindings()
        plugin_path = self.root / '.flutter-plugins-dependencies'
        plugins = json.loads(plugin_path.read_text())
        plugins['plugins']['macos'][0]['path'] = str(self.root / 'wrong-adapter')
        plugin_path.write_text(json.dumps(plugins))
        with self.assertRaisesRegex(RuntimeError, 'Flutter plugin metadata'):
            verify_package_bindings(self.root, 'macos')

    def test_pod_link_is_optional_only_before_build_and_always_checked_when_present(self):
        with self.assertRaisesRegex(RuntimeError, 'Pod symlink is missing'):
            verify_package_bindings(self.root, 'ios', require_pods=True)
        for target, relative in [('ios', 'ios/.symlinks/plugins/rwkv_mobile_flutter'),
                                 ('macos', 'macos/Flutter/ephemeral/.symlinks/plugins/rwkv_mobile_flutter')]:
            link = self.root / relative
            link.parent.mkdir(parents=True)
            try:
                link.symlink_to(self.adapter, target_is_directory=True)
            except OSError as error:
                self.skipTest(f'Host does not permit temporary symlinks: {error}')
            verify_package_bindings(self.root, target, require_pods=True)
            link.unlink()
            link.symlink_to(self.root / 'old-adapter', target_is_directory=True)
            with self.assertRaisesRegex(RuntimeError, 'Pod symlink'):
                verify_package_bindings(self.root, target)

    def test_environment_checks_selected_python_providers_without_installation(self):
        with patch('release_identity.sys.platform', 'darwin'), patch('release_identity.platform.machine', return_value='arm64'), \
             patch('release_identity.shutil.which', return_value='/usr/bin/available'), \
             patch('release_identity.importlib.util.find_spec', return_value=object()) as available, \
             patch('release_identity.subprocess.run') as mutate:
            check_apple_environment(self.release)
            self.assertEqual(['huggingface_hub', 'modelscope_hub'], [call.args[0] for call in available.call_args_list])
            available.return_value = None
            with self.assertRaisesRegex(RuntimeError, 'huggingface_hub'):
                check_apple_environment(self.release)
            available.return_value = object()
            self.flutter = '3.44.7'
            with self.assertRaisesRegex(RuntimeError, 'Use Flutter 3.47.2'):
                check_apple_environment(self.release)
            mutate.assert_not_called()


if __name__ == '__main__':
    unittest.main()
