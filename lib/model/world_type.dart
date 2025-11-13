enum WorldType {
  modrwkvV2,
  modrwkvV3,
  reasoningQA,
  ocr;

  String get displayName => switch (this) {
    WorldType.reasoningQA => "Visual QA Reasoning (🇨🇳 Chinese & 🇺🇸 English)",
    WorldType.ocr => "Visual + OCR (🇨🇳 Chinese & 🇺🇸 English)",
    WorldType.modrwkvV2 => "Visual QA (🇨🇳 Chinese & 🇺🇸 English)",
    WorldType.modrwkvV3 => "Visual QA (🇨🇳 Chinese & 🇺🇸 English)",
  };

  String get taskDescription => switch (this) {
    WorldType.reasoningQA => "Visual Question Answering (Reasoning)",
    WorldType.modrwkvV2 => "Visual Question Answering",
    WorldType.modrwkvV3 => "Visual Question Answering",
    WorldType.ocr => "Visual + OCR",
  };

  bool get isAudioDemo => false;

  bool get isVisualDemo => true;

  bool get isReasoning => switch (this) {
    WorldType.reasoningQA => true,
    _ => false,
  };

  bool get available => switch (this) {
    WorldType.reasoningQA => false,
    WorldType.modrwkvV2 => false,
    WorldType.modrwkvV3 => true,
    WorldType.ocr => false,
  };

  List<(String, String)> get socPairs => switch (this) {
    WorldType.reasoningQA => [
      ("", "RWKV7-0.4B-G1-SigLIP2-ColdStart-Q8_0.gguf"),
      ("8 Elite", "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8elite_combined_embedding.bin"),
      ("8 Gen 3", "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8gen3_combined_embedding.bin"),
    ],
    WorldType.ocr => [
      ("", "RWKV7-0.4B-G1-SigLIP2-Q8_0.gguf"),
      ("8 Elite", "RWKV7-0.4B-G1-SigLIP2-a16w8_8elite_combined_embedding.bin"),
      ("8 Gen 3", "RWKV7-0.4B-G1-SigLIP2-a16w8_8gen3_combined_embedding.bin"),
    ],
    WorldType.modrwkvV2 => [
      ("", "modrwkv-v2-1B5-step4-q6_K.gguf"),
      ("8 Elite", "modrwkv-v2-1B5-step4-a16w8-8elite_combined_embedding.bin"),
      ("8 Gen 3", "modrwkv-v2-1B5-step4-a16w8-8gen3_combined_embedding.bin"),
    ],
    WorldType.modrwkvV3 => [
      ("", "modrwkv-v3-0.4b-251113-q8_0.gguf"),
      ("8 Elite", "modrwkv-v3-0.4b-251113-a16w8-8elite.bin"),
      ("8 Gen 3", "modrwkv-v3-0.4b-251113-a16w8-8gen3.bin"),
      ("8s Gen 3", "modrwkv-v3-0.4b-251113-a16w8-8sgen3.bin"),
      ("8 Gen 2", "modrwkv-v3-0.4b-251113-a16w8-8gen2.bin"),
      ("8 Elite Gen5", "modrwkv-v3-0.4b-251113-a16w8-8elitegen5.bin"),
    ],
  };
}
