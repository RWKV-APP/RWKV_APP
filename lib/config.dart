import 'package:zone/router/page_key.dart';

abstract class Config {
  static final firstPage = PageKey.chat.name;

  static const prompt = """<EOD>""";

  static const promptCN = """<EOD>""";

  static const reasonTag = "reason";

  static const domain = "https://api-model.rwkvos.com";

  static const timeout = Duration(seconds: 60);

  static late final String xApiKey;

  static const appTitle = "RWKV Chat";

  static const fontFamilyFallback = [
    'Microsoft YaHei',
    "Sarasa Mono SC",
    "PingFang SC",
    ".AppleSystemUIFont",
    'miui',
    'mipro',
  ];

  static const maxTitleLength = 60;

  static const batchMarker = "V9m!T7#q2fH@x1Lz*8YwK0^g4";
  static const userMsgModifierSep = "G7!k9#rVq2@Xz8LpY4m%";
}
