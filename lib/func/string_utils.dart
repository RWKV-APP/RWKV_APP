String withoutTrailingZero(String value) {
  if (value.endsWith(".0")) return value.substring(0, value.length - 2);
  if (value.endsWith(".00")) return value.substring(0, value.length - 3);
  return value;
}

String withoutNonAlphabets(String value) {
  final regExp = RegExp("[^a-zA-Z0-9]");
  return value.replaceAll(regExp, "");
}

String withoutAlphabets(String value) {
  final regExp = RegExp("[a-zA-Z0-9]");
  return value.replaceAll(regExp, "");
}

List<String> scatterString(String value, {int minLength = 1}) {
  final subSequence = <String>[];
  if (value.length <= minLength) return [value];
  final iBias = minLength - 1;
  for (int i = 0; i < value.length; i++) {
    for (int j = value.length; j > i + iBias; j--) {
      final sub = value.substring(i, j);
      subSequence.add(sub);
    }
  }
  return subSequence;
}

String codeToName(String value) {
  if (value.isEmpty) return "";

  String formatted = value;
  while (formatted.contains("__")) {
    formatted = formatted.replaceAll("__", "_");
  }

  formatted = formatted.replaceAllMapped(RegExp(r'_([a-z])'), (match) {
    return ' ${match[1]!.toUpperCase()}';
  });

  formatted = formatted.replaceAllMapped(RegExp(r'([A-z])_'), (match) {
    return '${match[1]} ';
  });

  formatted = formatted.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
    return '${match[1]} ${match[2]}';
  });

  formatted = formatted.replaceAllMapped(RegExp(r'([A-Z])([A-Z])([a-z])'), (match) {
    return '${match[1]} ${match[2]}${match[3]}';
  });

  formatted = formatted
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');

  return formatted;
}

List<String> allCaseCombinations(String value) {
  final result = <String>[];

  void backtrack(String current, int index) {
    if (index == value.length) {
      result.add(current);
      return;
    }

    backtrack(current + value[index].toLowerCase(), index + 1);
    backtrack(current + value[index].toUpperCase(), index + 1);
  }

  backtrack('', 0);
  return result;
}

bool containsChinese(String value) {
  final chineseRegex = RegExp(r'[\u4E00-\u9FFF]');
  return chineseRegex.hasMatch(value);
}

bool isEnglishLetters(String value) {
  if (value.isEmpty) return false;
  return RegExp(r'^[a-zA-Z]+$').hasMatch(value);
}

Set<String> isolatedChars(String value) {
  final result = <String>{};
  for (int i = 0; i < value.length; i++) {
    result.add(value[i]);
  }
  return result;
}
