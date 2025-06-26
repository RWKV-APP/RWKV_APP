enum WorldType {
  modrwkvV2,
  reasoningQA,
  ocr,
  @Deprecated("")
  qa,
  @Deprecated("")
  engVisualQA,
  @Deprecated("")
  engAudioQA,
  @Deprecated("")
  chineseASR,
  @Deprecated("")
  engASR;

  String get displayName => switch (this) {
    WorldType.reasoningQA => "Visual QA Reasoning (🇨🇳 Chinese & 🇺🇸 English)",
    WorldType.ocr => "Visual + OCR (🇨🇳 Chinese & 🇺🇸 English)",
    WorldType.modrwkvV2 => "Visual QA (🇨🇳 Chinese & 🇺🇸 English)",
    WorldType.qa => "Visual QA (🇨🇳 Chinese & 🇺🇸 English)",
    WorldType.engVisualQA => "Visual QA (🇺🇸 English)",
    WorldType.engAudioQA => "Audio QA (🇺🇸 English)",
    WorldType.chineseASR => "ASR (🇨🇳 Chinese)",
    WorldType.engASR => "ASR (🇺🇸 English)",
  };

  String get taskDescription => switch (this) {
    WorldType.reasoningQA => "Visual Question Answering (Reasoning)",
    WorldType.modrwkvV2 => "Visual Question Answering",
    WorldType.qa => "Visual Question Answering",
    WorldType.ocr => "Visual + OCR",
    WorldType.engVisualQA => "Visual Question Answering",
    WorldType.engAudioQA => "Audio Question Answering",
    WorldType.chineseASR => "Automatic Speech Recognition",
    WorldType.engASR => "Automatic Speech Recognition",
  };

  bool get isAudioDemo => switch (this) {
    WorldType.engAudioQA || WorldType.chineseASR || WorldType.engASR => true,
    WorldType.engVisualQA || WorldType.reasoningQA || WorldType.qa || WorldType.ocr || WorldType.modrwkvV2 => false,
  };

  bool get isVisualDemo => switch (this) {
    WorldType.engVisualQA || WorldType.reasoningQA || WorldType.qa || WorldType.ocr || WorldType.modrwkvV2 => true,
    WorldType.engAudioQA || WorldType.chineseASR || WorldType.engASR => false,
  };

  bool get isReasoning => switch (this) {
    WorldType.reasoningQA => true,
    _ => false,
  };

  bool get available => switch (this) {
    WorldType.reasoningQA || WorldType.qa || WorldType.ocr || WorldType.modrwkvV2 => true,
    _ => false,
  };

  List<(String, String)> get socPairs => switch (this) {
    WorldType.reasoningQA => [
      ("", "RWKV7-0.4B-G1-SigLIP2-ColdStart-Q8_0.gguf"),
      ("8 Elite", "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8elite_combined_embedding.bin"),
      ("8 Gen 3", "RWKV7-0.4B-G1-SigLIP2-ColdStart-a16w8_8gen3_combined_embedding.bin"),
    ],
    WorldType.qa => [
      ("", "rwkv7-v-0.4B-Q8_0.gguf"),
      ("8 Elite", "rwkv7-v-0.4B-a16w8_8elite_combined_embedding.bin"),
      ("8 Gen 3", "rwkv7-v-0.4B-a16w8_8gen3_combined_embedding.bin"),
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
    _ => [],
  };
}
