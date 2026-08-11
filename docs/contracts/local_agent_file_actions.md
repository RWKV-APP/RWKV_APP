<a id="SPEC-RWKV-LOCAL-AGENT-FILE-ACTIONS"></a>

# Local Agent File Actions

## Product contract

The Windows Debug App must let the active local model create, read, update, and delete real text files inside a user-authorized workspace from ordinary chat

The deterministic Agentic Evaluation sandbox remains in-memory and must not gain host file access. Real local actions use a separate tool host and are not benchmark scores

The ordinary chat composer is the primary user-facing entry point. A user can send a clear natural-language request such as creating a named text file on the desktop. The App routes that request through the local Agent tool protocol without requiring navigation to Agentic Evaluation or a dedicated local-file page

A dedicated diagnostic page may expose the same host for development, but its existence or successful use does not satisfy ordinary-chat acceptance

## Authorization and visibility

- The user selects the workspace with the operating-system directory picker
- Workspace authorization lasts only for the current App session
- When an ordinary-chat request needs local file access and no workspace is authorized, the App opens the directory picker and continues the same request after authorization
- The Agent receives relative paths and never receives authority over arbitrary absolute paths
- Reading and listing are allowed after workspace selection
- Every create, update, and delete call pauses for an in-App approval
- The approval is visible on the ordinary chat screen and shows the operation, relative path, authorized workspace, and proposed text content when applicable
- A rejected action returns a truthful tool error and does not change the file
- The final verified result or truthful failure appears as the assistant reply in the same conversation

## File boundary

- The initial Windows delivery supports UTF-8 text files
- File paths must resolve inside the selected workspace after symbolic-link resolution
- Absolute paths, parent traversal, links that escape the workspace, directories passed as files, and inaccessible paths are rejected
- Parent directories must already exist
- File reads and writes are bounded to 1,000,000 bytes
- `write_file` creates a missing file or replaces an existing text file only after approval
- `delete_file` deletes one regular file only after approval and never recursively deletes a directory
- No shell, process execution, network access, or unrestricted operating-system API is exposed

## Result verification

- After a write, the host reads the file back and compares the exact UTF-8 content before reporting success
- After a delete, the host verifies that the file is absent before reporting success
- Tool errors and user rejection must remain visible to the model and the user
- Acceptance requires a real Windows Debug run started from the ordinary chat composer with the registered 13B model that demonstrates create, read, update, and delete against a disposable file in an explicitly selected desktop workspace
- The accepted evidence must show the ordinary user message, the in-chat mutation approval, the assistant result, and the corresponding real Windows file state

## Capability assessment and reporting

- A real Windows capability report starts from tools actually exposed by `AgentLocalFileHost`
- Atomic tools and model-composed workflows are separate claims; for example, copy or rename may compose read, write, and delete without having a dedicated host tool
- Each real capability claim requires an ordinary-chat run plus independent inspection of the affected Windows state
- Deterministic `AgentSandbox` tools are reported as sandbox-only unless the ordinary-chat host exposes and verifies an equivalent real operation
- Results are classified as real verified, engineering-test-only, sandbox-only, unavailable, or unverified
- Unsupported prompts and truthful failures are part of the capability result and must not be rewritten as successful Agent actions

## Repository ownership

The RWKV App repository owns the user interface, directory authorization, approval lifecycle, local tool host, and audit events. Adapter or inference-engine repositories are involved only when evidence identifies a lower-layer generation defect

The first delivery is Windows Debug ordinary chat. Other desktop platforms remain separate delivery work
