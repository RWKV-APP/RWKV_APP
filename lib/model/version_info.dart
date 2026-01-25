class VersionInfo {
  final String type;
  final String url;
  final String version;
  final int build;

  const VersionInfo({
    required this.type,
    required this.url,
    required this.version,
    required this.build,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      type: json['type'],
      url: json['url'],
      version: json['version'],
      build: json['build'],
    );
  }

  @override
  String toString() {
    return '\nVersionInfo(\n  type: $type,\n  url: $url,\n  version: $version,\n  build: $build\n)';
  }
}
