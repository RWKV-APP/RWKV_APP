# Kirin 9020 NPU model assets

This archive contains the NNRT-prepared 0.1B model verified on the source Mac

```text
rwkv7-g1d-0.1b-20260129-ctx8192-nnrt-f16.st
bytes   382205426
sha256  3706582deaf23056ac284afcd1203d62102028bcc9fc88559858e6e3566ac208

b_rwkv_vocab_v20230424.txt
bytes   2275556
sha256  4931cd8fd86354cf1d0ecab72e1302aac6235bea73dc9aab1421b9245641ee5b
```

The specialized safetensors file was generated from the verified generic F16 model with:

```text
rwkv_mobile/converter/convert_rwkv_to_nnrt_safetensors.py
```

The conversion precomputes the constant embedding `ln0` in FP32 and writes the result in F16. This avoids the first precision-sensitive LayerNorm on the Kirin NNRT graph

Host verification confirmed that all non-embedding tensors are byte-identical to the generic source, the marker tensor is present, and every embedding value equals the four-thread FP32 LayerNorm conversion. The included `nnrt_model_conversion_report.json` records the exact source and output hashes, package versions, and the fact that device validation is still pending

The earlier device-tested artifact used SHA-256 `23d636c3c4f37f29db180316ede77cae7cb602879b57c94c295947919258a0d5`; the runtime accepts both registered artifacts

To repeat the tensor comparison after downloading the generic source model:

```powershell
py -3.12 -m pip install -r .\requirements-nnrt.txt
py -3.12 .\verify_rwkv_nnrt_safetensors.py `
  .\rwkv7-g1d-0.1b-20260129-ctx8192.st `
  .\rwkv7-g1d-0.1b-20260129-ctx8192-nnrt-f16.st `
  --expected-output-sha256 3706582deaf23056ac284afcd1203d62102028bcc9fc88559858e6e3566ac208
```

The dependency versions are pinned, while platform wheel hashes are not. Windows regeneration must be treated as a fresh artifact and checked by full SHA-256 plus token-1 and phone generation acceptance

Verify `SHA256MANIFEST.txt` before sending either file to a phone
