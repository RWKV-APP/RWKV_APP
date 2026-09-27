import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const expected = readFileSync(new URL('../.flutter-version', import.meta.url), 'utf8').trim();
const settings = readFileSync(new URL('../.vscode/settings.json', import.meta.url), 'utf8');
assert(settings.includes(`"dart.flutterSdkPath": "../flutter-${expected}"`), 'VS Code SDK must match .flutter-version');
const actual = JSON.parse(execFileSync(process.execPath, [fileURLToPath(new URL('./flutter.mjs', import.meta.url)), '--version', '--machine'], { encoding: 'utf8' }));
assert.equal(actual.frameworkVersion, expected);
assert.equal(actual.dartSdkVersion, '3.13.4');
const dart = execFileSync(process.execPath, [fileURLToPath(new URL('./flutter.mjs', import.meta.url)), '--dart', '--version'], { encoding: 'utf8' });
assert.match(dart, /Dart SDK version: 3\.13\.4\b/);
console.log(`PASS Flutter ${actual.frameworkVersion} / Dart ${actual.dartSdkVersion}; IDE and command entrypoint agree.`);
