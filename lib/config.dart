import 'package:zone/router/page_key.dart';

abstract class Config {
  static final firstPage = PageKey.chat.name;

  static const prompt = """<EOD>""";

  static const promptCN = """<EOD>""";

  static const reasonTag = "reason";

  static const modelsDirName = "rwkv_chat_models";

  static const domain = "https://api-model.rwkvos.com";

  static const timeout = Duration(seconds: 60);

  static const String xApiKey = String.fromEnvironment("X_API_KEY");

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

  static const msgFontScale = 1.1;
  // Markdown font sizes: h1=18, h2=17, h3=16, h4=16, h5=15, h6=15, body=14
  static const markdownHeaderFontSizes = [18.0, 17.0, 16.0, 16.0, 15.0, 15.0];
  static const markdownBodyFontSize = 14.0;
}
