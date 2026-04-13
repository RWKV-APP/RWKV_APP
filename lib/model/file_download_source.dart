enum FileDownloadSource {
  aifasthub,
  hfmirror,
  modelscope,
  huggingface,
  github,
  googleapis
  ;

  String get prefix => switch (this) {
    aifasthub => 'https://aifasthub.com/',
    hfmirror => 'https://hf-mirror.com/',
    modelscope => 'https://modelscope.cn/',
    huggingface => 'https://huggingface.co/',
    github => 'https://github.com/',
    googleapis => 'https://googleapis.com/',
  };

  String get suffix => switch (this) {
    aifasthub => '?download=true',
    hfmirror => '?download=true',
    modelscope => '',
    huggingface => '',
    github => '',
    googleapis => '',
  };

  bool get isDebug => switch (this) {
    huggingface => false,
    hfmirror => false,
    aifasthub => false,
    modelscope => false,
    github => true,
    googleapis => true,
  };

  bool get hidden => switch (this) {
    github => true,
    googleapis => true,
    _ => false,
  };

  String transformRaw(String raw) => switch (this) {
    modelscope => raw.replaceFirst('mollysama/rwkv-mobile-models/resolve/main/', 'models/RWKV/rwkv-mobile-models/resolve/master/'),
    _ => raw,
  };
}
