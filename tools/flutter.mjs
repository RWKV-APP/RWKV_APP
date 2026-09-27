import { readFileSync, existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Use the same sibling SDK as VS Code, independently of the host's PATH.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const version = readFileSync(path.join(root, '.flutter-version'), 'utf8').trim();
if (!/^\d+\.\d+\.\d+$/.test(version)) throw new Error('Invalid .flutter-version');
const sdk = path.resolve(root, '..', `flutter-${version}`);
const cachedVersion = path.join(sdk, 'bin/cache/flutter.version.json');
if (!existsSync(cachedVersion)) {
  throw new Error(`Initialize the Flutter ${version} SDK at ${sdk} before running this command.`);
}
const actual = JSON.parse(readFileSync(cachedVersion, 'utf8'));
if (actual.flutterVersion !== version && actual.frameworkVersion !== version) {
  throw new Error(`Expected Flutter ${version}; SDK reports ${actual.flutterVersion ?? actual.frameworkVersion}`);
}
const dart = path.join(sdk, 'bin/cache/dart-sdk/bin', process.platform === 'win32' ? 'dart.exe' : 'dart');
const args = process.argv.slice(2);
const dartOnly = args[0] === '--dart';
const result = spawnSync(dart, dartOnly ? args.slice(1) : [path.join(sdk, 'bin/cache/flutter_tools.snapshot'), ...args], {
  cwd: root,
  stdio: 'inherit',
  env: { ...process.env, FLUTTER_ROOT: sdk, PATH: `${path.join(sdk, 'bin')}${path.delimiter}${process.env.PATH ?? ''}` },
});
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
