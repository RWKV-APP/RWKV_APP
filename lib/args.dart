abstract class Args {
  static const autoShowTranslator = bool.fromEnvironment("autoShowTranslator", defaultValue: false);
  static const batchCount = int.fromEnvironment("batchCount", defaultValue: 2);
  static const batchVW = int.fromEnvironment("batchVW", defaultValue: 70);
  static const debugMsgId = bool.fromEnvironment("debugMsgId", defaultValue: false);
  static const debuggingThemes = bool.fromEnvironment("debuggingThemes", defaultValue: false);
  static const demoType = String.fromEnvironment("demoType", defaultValue: "__chat__");
  static const disableAutoShowOfWeightsPanel = bool.fromEnvironment("disableAutoShowOfWeightsPanel", defaultValue: false);
  static const disableRemoteConfig = bool.fromEnvironment("disableRemoteConfig", defaultValue: false);
  static const enableBatchInference = bool.fromEnvironment("enableBatchInference", defaultValue: false);
  static const enableChatDebugger = bool.fromEnvironment("enableChatDebugger");
  static const maxTokens = int.fromEnvironment("maxTokens", defaultValue: -1);
  static const nativeSplashPreserveDurationInMS = int.fromEnvironment("nativeSplashPreserveDurationInMS", defaultValue: 50);
  static const othelloTestCase = int.fromEnvironment("othello_test_case", defaultValue: -1);
  static const showHaloDebugger = bool.fromEnvironment("showHaloDebugger", defaultValue: false);
  static const testingSeeQueue = bool.fromEnvironment("testingSeeQueue", defaultValue: false);
}
