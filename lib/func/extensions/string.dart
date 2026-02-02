extension RWKVStringExtension on String {
  // 定义匹配基本中文字符的正则 (范围: 0x4E00 - 0x9FFF)
  static final RegExp _chineseRegex = RegExp(r'[\u4E00-\u9FFF]');

  /// Determine whether this string contains any Chinese characters.
  bool get containsChinese {
    return _chineseRegex.hasMatch(this);
  }

  /// Determine whether Chinese characters account for more than half of the characters in this string.
  bool get isMostlyChinese {
    if (isEmpty) return false;

    // 计算匹配到的中文字符数量
    final int chineseCount = _chineseRegex.allMatches(this).length;

    // 判断是否超过总长度的一半
    return chineseCount > (length / 2);
  }
}
