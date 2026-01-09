sealed class ThinkingMode {
  abstract final String header;
  abstract final bool forceReasoning;
  final String userMsgFooter = "";

  bool get hasThinkTag => header.startsWith("<think");

  const ThinkingMode();

  @override
  String toString() {
    return "ThinkingMode." + runtimeType.toString();
  }

  static ThinkingMode fromString(String? runningMode) {
    if (runningMode == "ThinkingMode.None") return const None();
    if (runningMode == "ThinkingMode.Lighting") return const Lighting();
    if (runningMode == "ThinkingMode.Free") return const Free();
    if (runningMode == "ThinkingMode.PreferChinese") return const PreferChinese();
    if (runningMode == "ThinkingMode.Fast") return const Fast();
    if (runningMode == "ThinkingMode.None") return const None();
    if (runningMode == "ThinkingMode.En") return const En();
    if (runningMode == "ThinkingMode.EnShort") return const EnShort();
    if (runningMode == "ThinkingMode.EnLong") return const EnLong();
    return const None();
  }
}

@Deprecated("Use Fast instead")
class Lighting extends ThinkingMode {
  @override
  final String header = '<think>\n</think>';
  
  @override
  final bool forceReasoning = false;
  
  const Lighting();
}

class Fast extends ThinkingMode {
  @override
  final String header = '<think>\n</think';

  @override
  final bool forceReasoning = false;

  const Fast();
}

class Free extends ThinkingMode {
  @override
  final String header = '<think';

  @override
  final bool forceReasoning = true;

  const Free();
}

class PreferChinese extends ThinkingMode {
  @override
  final String header = '<think>嗯';
  @override
  final bool forceReasoning = true;

  const PreferChinese();
}

class None extends ThinkingMode {
  @override
  String get header => "";

  @override
  final bool forceReasoning = false;

  const None();
}

class En extends ThinkingMode {
  @override
  String get header => "<think";

  @override
  String get userMsgFooter => " think";

  @override
  final bool forceReasoning = true;

  const En();
}

class EnShort extends ThinkingMode {
  @override
  String get header => "<think";

  @override
  String get userMsgFooter => " think a bit";

  @override
  final bool forceReasoning = true;

  const EnShort();
}

class EnLong extends ThinkingMode {
  @override
  String get header => "<think";

  @override
  String get userMsgFooter => " think a lot";

  @override
  final bool forceReasoning = true;

  const EnLong();
}
