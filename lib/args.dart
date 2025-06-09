abstract class Args {
  static const enableChatDebugger = bool.fromEnvironment("enableChatDebugger");
  static const othelloTestCase = int.fromEnvironment("othello_test_case", defaultValue: -1);
  static const demoType = String.fromEnvironment("demoType", defaultValue: "__chat__");
  static const maxTokens = int.fromEnvironment("maxTokens", defaultValue: -1);
  static const disableRemoteConfig = bool.fromEnvironment("disableRemoteConfig", defaultValue: false);
  static const disableAutoShowOfWeightsPanel = bool.fromEnvironment("disableAutoShowOfWeightsPanel", defaultValue: false);
  static const debuggingThemes = bool.fromEnvironment("debuggingThemes", defaultValue: false);
}
