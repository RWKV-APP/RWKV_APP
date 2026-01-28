class FontInfo {
  final String name;
  final String? path;
  final bool isMonospace;

  FontInfo({
    required this.name,
    this.path,
    required this.isMonospace,
  });

  factory FontInfo.fromMap(Map<dynamic, dynamic> map) {
    return FontInfo(
      name: map['name'] as String,
      path: map['path'] as String?,
      isMonospace: map['isMonospace'] as bool? ?? false,
    );
  }
}
