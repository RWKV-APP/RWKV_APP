import assert from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function checkRuntimeEnv(content) {
  for (const line of content.split(/\r?\n/)) {
    const entry = line.trim();
    if (!entry || entry.startsWith('#')) continue;
    if (!/^x-api-key\s*=/.test(entry)) {
      throw new Error('Bundled .env may contain only x-api-key. Keep signing and publication credentials outside App resources.');
    }
  }
}

if (path.resolve(process.argv[1] ?? '') === fileURLToPath(import.meta.url)) {
  checkRuntimeEnv('\uFEFF# runtime only\r\nx-api-key = "client-value"\r\n\r\n');
  checkRuntimeEnv('');
  for (const content of ['HF_TOKEN=secret', 'x-api-key=client\nMACOS_APP_PASSWORD=secret', 'invalid line']) {
    assert.throws(() => checkRuntimeEnv(content), /Bundled \.env may contain only x-api-key/);
  }
  console.log('Runtime environment guard checks passed.');
}
