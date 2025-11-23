enum FileDownloadSource {
  aifasthub,
  hfmirror,
  huggingface,
  github,
  googleapis
  ;

  String get prefix => switch (this) {
    aifasthub => 'https://aifasthub.com/',
    hfmirror => 'https://hf-mirror.com/',
    huggingface => 'https://huggingface.co/',
    github => 'https://github.com/',
    googleapis => 'https://googleapis.com/',
  };

  String get suffix => switch (this) {
    aifasthub => '?download=true',
    hfmirror => '?download=true',
    huggingface => '',
    github => '',
    googleapis => '',
  };

  bool get isDebug => switch (this) {
    huggingface => false,
    hfmirror => false,
    aifasthub => false,
    github => true,
    googleapis => true,
  };

  bool get hidden => switch (this) {
    _ => false,
  };
}

