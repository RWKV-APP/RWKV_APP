# Product

## Register

product

<a id="SPEC-RWKV-PRODUCT-USERS"></a>

## Users

RWKV App serves users who evaluate, run, and compare RWKV models on phones and desktop machines. They are often experimenting with model behavior, hardware fit, local inference performance, or prototype AI workflows.

<a id="SPEC-RWKV-PRODUCT-PURPOSE"></a>

## Product Purpose

RWKV App is a privacy-first, local-first AI application for Android, iOS, Windows, macOS, and Linux. It helps users download models, load them on real devices, run chat, speech, vision, and Web Demo workflows, and inspect outputs without relying on cloud-only demos.

Public product and organization introductions must lead with RWKV's architectural distinction: parallelizable training with recurrent inference. For autoregressive generation, describe sequence scaling precisely: processing a sequence of length `T` takes `O(T)` total work, while the recurrent state carried between decoding steps remains `O(1)` with respect to sequence length and does not require a KV cache that grows with context.

Connect those architecture properties to relevant deployment scenarios such as streaming generation, long-running sessions, on-device inference, and high-concurrency serving. Treat concrete speed, capacity, backend, platform, device, and accelerator support as implementation- and hardware-dependent claims that require current verification.

## Brand Personality

Practical, technical, direct.

## Anti-references

Avoid marketing-page ornament, decorative cards, hidden critical controls, and UI that makes expert workflows feel like a demo toy. Avoid presenting raw generated artifacts as the primary experience when the user needs to inspect the rendered result.

<a id="SPEC-RWKV-DESIGN-PRINCIPLES"></a>

## Design Principles

- Put the task surface first
- Make model and runtime state visible without making it the main attraction
- Prefer dense but calm controls for repeated experimentation
- Show generated artifacts in their useful form first
- Keep advanced text and source output available on demand
- On public introduction surfaces, put the RWKV architecture distinction and its verified user-facing consequences in the first screen before generic capability copy
- State what each complexity bound is relative to, and separate architecture properties from implementation- or hardware-dependent performance and support claims

## Accessibility & Inclusion

Use standard platform controls, readable contrast, keyboard-accessible actions, and layouts that remain usable across phone and desktop widths. Avoid relying on color alone for state.
