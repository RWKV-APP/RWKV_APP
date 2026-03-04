// Project imports:
import 'package:zone/args.dart';
import 'package:zone/router/page_key.dart';

abstract class Config {
  static final firstPage = PageKey.chat.name;

  static const prompt = """<EOD>""";

  static const promptCN = """<EOD>""";

  static const reasonTag = "reason";

  /// 模型文件夹名称
  static const desktopModelsDirName = "models";
  static const mobileModelsDirName = "rwkv_chat_models";

  static const domain = "https://api-model.rwkvos.com";
  // static const apiv2 = "http://localhost:3462";
  static const apiv2 = "http://api.rwkv.halowang.cloud";

  static const timeout = Duration(seconds: 60);

  static late final String xApiKey;

  static const appTitle = "RWKV Chat";

  /// 全局字体 fallback, 主要用于桌面端:
  /// - 优先一些常见的中文 UI 字体
  /// - 兼容 Windows / macOS / 小米 / OPPO / vivo 等 ROM
  static const fontFamilyFallback = [
    // Windows / 通用中文无衬线
    'Microsoft YaHei',
    '微软雅黑',
    // macOS / iOS 系统 UI 字体
    '.AppleSystemUIFont',
    'PingFang SC',

    'SF Pro Text',
    // 一些常见的中文无衬线字体
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'HarmonyOS Sans SC',
    // 交叉覆盖部分国产 ROM（小米 / OPPO / vivo 等）
    'miui',
    'mipro',
    'OPPO Sans',
    'OPPOSans',
    'vivo Sans',
    'vivoSans',
    // 最后退回到通用 sans-serif
    'sans-serif',
  ];

  static const maxTitleLength = 120;
  static const legacyMaxTitleLength = 60;

  static const batchMarker = "V9m!T7#q2fH@x1Lz*8YwK0^g4";
  static const userMsgModifierSep = "G7!k9#rVq2@Xz8LpY4m%";

  static const msgFontScale = 1.1;
  // Markdown font sizes: h1=18, h2=17, h3=16, h4=16, h5=15, h6=15, body=14
  static const markdownHeaderFontSizes = [18.0, 17.0, 16.0, 16.0, 15.0, 15.0];
  static const markdownBodyFontSize = 14.0;
  static const newConversationTokenReminderThreshold = Args.conversationTokenReminderThreshold;

  static const seePrefillId = -42;

  static final inputBarDebuggerPassword = 'RWKV_A9!vT7#qL2@mX8kN5%pR';
}
