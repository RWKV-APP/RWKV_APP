bool containsChineseCharacters(String text) {
  // 正则表达式匹配 Unicode 范围 U+4E00 到 U+9FFF
  // 这个范围包含了大多数常用的汉字
  RegExp chineseRegex = RegExp(r'[\u4E00-\u9FFF]');

  // 使用 hasMatch() 方法检查字符串是否包含匹配的字符
  return chineseRegex.hasMatch(text);
}

bool isEnglish(String str) {
  if (str.isEmpty) return false;
  return RegExp(r'^[a-zA-Z]+$').hasMatch(str);
}
