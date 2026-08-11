<a id="SPEC-RWKV-MULTI-QUESTION-PARALLEL"></a>

# Multi-Question Parallel Inference Contract

Lifecycle: active

When the loaded model exposes supported batch sizes, the app may send multiple
distinct questions in one batch and present one question-and-answer result per
slot in the Chat surface.

The active behavior is constrained as follows:

- a batch contains at least two questions and never exceeds the loaded model's
  declared maximum supported batch size
- each result slot preserves the corresponding user question and model answer
- unsupported models keep the multi-question batch action unavailable
- ordinary single-message rendering resumes after batch completion
- persisted batch messages remain parseable without exposing internal batch
  separators in prompts or user-visible generated questions
- token accounting, decode-parameter display, selection, and restored state
  remain correct for every slot

Implementation details and iteration history are evidence, not additions to
this product contract. Current behavior must be verified against
`lib/store/multi_question.dart`, `lib/store/chat.dart`, and the applicable Chat
widgets before making a delivery claim.
