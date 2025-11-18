enum Tag {
  adapter,
  audio,
  core,
  cpu,
  decoder,
  encoder,
  english,
  image,
  model,
  npu,
  reason,
  text,
  tts,
  video,
  vision,
  world,
  unknown;

  Tag fromString(String tag) {
    return switch (tag) {
      "adapter" => Tag.adapter,
      "audio" => Tag.audio,
      "core" => Tag.core,
      "cpu" => Tag.cpu,
      "decoder" => Tag.decoder,
      "encoder" => Tag.encoder,
      "english" => Tag.english,
      "image" => Tag.image,
      "model" => Tag.model,
      "npu" => Tag.npu,
      "reason" => Tag.reason,
      "text" => Tag.text,
      "tts" => Tag.tts,
      "video" => Tag.video,
      "vision" => Tag.vision,
      "world" => Tag.world,
      _ => Tag.unknown,
    };
  }

  bool get show => switch (this) {
    _ => true,
  };

  static final _orders = [
    Tag.adapter,
    Tag.audio,
    Tag.core,
    Tag.cpu,
    Tag.decoder,
    Tag.encoder,
    Tag.english,
    Tag.image,
    Tag.model,
    Tag.npu,
    Tag.reason,
    Tag.text,
    Tag.tts,
    Tag.video,
    Tag.vision,
    Tag.world,
    Tag.unknown,
  ];

  static int sort(Tag a, Tag b) {
    return 0;
  }

  String get displayName => switch (this) {
    Tag.adapter => "Adapter",
    Tag.audio => "Audio",
    Tag.core => "Core",
    Tag.cpu => "CPU",
    Tag.decoder => "Decoder",
    Tag.encoder => "Encoder",
    Tag.english => "English",
    Tag.image => "Image",
    Tag.model => "Model",
    Tag.npu => "NPU",
    Tag.reason => "Reason",
    Tag.text => "Text",
    Tag.tts => "TTS",
    Tag.video => "Video",
    Tag.vision => "Vision",
    Tag.world => "World",
    Tag.unknown => "Unknown",
  };
}
