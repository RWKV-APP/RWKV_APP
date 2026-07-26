# Optional assets not included in the NPU transfer

The source Mac contained two RWKV7-G1g 2.9B GGUF files:

```text
rwkv7-g1g-2.9b-20260526-ctx8192-Q4_K_M.gguf
bytes   1919047808
sha256  473daef65f1e7af6d7e286f2827e681ef7410ca117a3e2f1cf2f5a0ef9c5ab9a

rwkv7-g1g-2.9b-20260526-ctx8192-Q3_K_M-requant.gguf
bytes   1519278208
sha256  1522fa9033fc6d75d227790b7ed816447deddb1ebe3cd379104dfd74841b2d53
```

These assets use the llama.cpp CPU/ARM NEON path in the current HarmonyOS host. They are not required for the 0.1B Kirin NPU verification and are excluded from the ordinary transfer to keep it smaller

The previously downloaded 1.5B BF16 PTH and its cache directory were no longer present on the source Mac at packaging time
