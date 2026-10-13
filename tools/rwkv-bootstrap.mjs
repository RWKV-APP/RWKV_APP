// Public bootstrap wrapper for a selected target; native paths stay in ignored config.
// Native JSON is bounded and discarded; no prompt/history field is accessed.
import { lstat, readFile, realpath } from "node:fs/promises";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";

try {
  const configPath = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", ".codex", "rwkv-bootstrap.json");
  const info = await lstat(configPath);
  if (!info.isFile() || info.isSymbolicLink() || info.size > 16 * 1024) throw new Error("Invalid public bootstrap config");
  const config = JSON.parse(await readFile(configPath, "utf8"));
  if (config.schemaVersion !== 1 || !path.isAbsolute(config.harnessRoot) || !path.isAbsolute(config.projectPath)) throw new Error("Bootstrap config needs resolved native paths");
  let bytes = 0; const chunks = [];
  for await (const chunk of process.stdin) {
    const data = Buffer.from(chunk); bytes += data.length;
    if (bytes > 256 * 1024) throw new Error("Native bootstrap event exceeds bound");
    chunks.push(data);
  }
  const native = JSON.parse(Buffer.concat(chunks).toString("utf8"));
  const event = { hook_event_name: native.hook_event_name, session_id: native.session_id, cwd: native.cwd };
  const root = await realpath(config.harnessRoot);
  const modulePath = path.join(root, "lib/task-bootstrap.mjs");
  const library = await lstat(path.join(root, "lib"));
  const runtime = await lstat(modulePath);
  if (library.isSymbolicLink() || !library.isDirectory() || runtime.isSymbolicLink() ||
      !runtime.isFile() || await realpath(modulePath) !== modulePath) {
    throw new Error("Bootstrap import requires regular native runtime paths");
  }
  const { prepareTargetBootstrap } = await import(pathToFileURL(modulePath).href);
  const result = await prepareTargetBootstrap({ harnessRoot: root, projectId: config.projectId, projectPath: config.projectPath, event });
  process.stdout.write(`${JSON.stringify({ hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: result.additionalContext } })}\n`);
} catch {
  // Report only a fixed reason: native/config/parser errors can contain inputs.
  process.stdout.write(`${JSON.stringify({ decision: "block", reason: "RWKV bootstrap did not verify its runtime or project binding. Inspect the existing binding; preserve current work and authorization." })}\n`);
}
