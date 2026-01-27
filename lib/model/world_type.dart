enum WorldType {
  modrwkvV2,
  modrwkvV3,
  reasoningQA,
  ocr
  ;

  String get displayName => switch (this) {
    reasoningQA => "Visual QA Reasoning (🇨🇳 Chinese & 🇺🇸 English)",
    ocr => "Visual + OCR (🇨🇳 Chinese & 🇺🇸 English)",
    modrwkvV2 => "Visual QA (🇨🇳 Chinese & 🇺🇸 English)",
    modrwkvV3 => "Visual QA (🇨🇳 Chinese & 🇺🇸 English)",
  };

  String get taskDescription => switch (this) {
    reasoningQA => "Visual Question Answering (Reasoning)",
    modrwkvV2 => "Visual Question Answering",
    modrwkvV3 => "Visual Question Answering",
    ocr => "Visual + OCR",
  };

  bool get isAudioDemo => false;

  bool get isVisualDemo => true;

  bool get isReasoning => switch (this) {
    reasoningQA => true,
    _ => false,
  };

  bool get available => switch (this) {
    reasoningQA => false,
    modrwkvV2 => false,
    modrwkvV3 => true,
    ocr => false,
  };

  List<(String, String)> get socPairs => switch (this) {
    reasoningQA => [
      ("", "RWKV7-0.4B-G1-SigLIP2-ColdStart-Q8_0.gguf"),
      ("8 Elite", "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8elite_combined_embedding.bin"),
      ("8 Gen 3", "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8gen3_combined_embedding.bin"),
    ],
    ocr => [
      ("", "RWKV7-0.4B-G1-SigLIP2-Q8_0.gguf"),
      ("8 Elite", "RWKV7-0.4B-G1-SigLIP2-a16w8_8elite_combined_embedding.bin"),
      ("8 Gen 3", "RWKV7-0.4B-G1-SigLIP2-a16w8_8gen3_combined_embedding.bin"),
    ],
    modrwkvV2 => [
      ("", "modrwkv-v2-1B5-step4-q6_K.gguf"),
      ("8 Elite", "modrwkv-v2-1B5-step4-a16w8-8elite_combined_embedding.bin"),
      ("8 Gen 3", "modrwkv-v2-1B5-step4-a16w8-8gen3_combined_embedding.bin"),
    ],
    modrwkvV3 => [
      ("", "rwkv-vl-0.4b-251222-q8_0.gguf"),
      ("8 Elite", "rwkv-vl-0.4b-251222-a16w8-8elite.rmpack"),
      ("8 Gen 3", "rwkv-vl-0.4b-251222-a16w8-8gen3.rmpack"),
      ("8s Gen 3", "rwkv-vl-0.4b-251222-a16w8-8sgen3.rmpack"),
      ("8 Gen 2", "rwkv-vl-0.4b-251222-a16w8-8gen2.rmpack"),
      ("8+ Gen 1", "rwkv-vl-0.4b-251222-a16w8-8plusgen1.rmpack"),
      ("8 Elite Gen5", "rwkv-vl-0.4b-251222-a16w8-8elitegen5.rmpack"),
      ("Dimensity 9300", "rwkv-vl-0.4b-251222-MT6989.rmpack"),
    ],
  };
}
