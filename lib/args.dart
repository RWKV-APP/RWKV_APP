abstract class Args {
  static const _webDemoOfficialApiKeyDefault = "rwkv7b13b-fyrik-7b";

  static const autoShowTranslator = bool.fromEnvironment("autoShowTranslator", defaultValue: false);
  static const batchCount = int.fromEnvironment("batchCount", defaultValue: 3);
  static const batchVW = int.fromEnvironment("batchVW", defaultValue: -1);
  static const conversationTokenReminderThreshold = int.fromEnvironment("conversationTokenReminderThreshold", defaultValue: 8000);
  static const debugMsgId = bool.fromEnvironment("debugMsgId", defaultValue: false);
  static const debuggingThemes = bool.fromEnvironment("debuggingThemes", defaultValue: false);
  static const demoType = String.fromEnvironment("demoType", defaultValue: "__chat__");
  static const disableAutoShowOfWeightsPanel = bool.fromEnvironment("disableAutoShowOfWeightsPanel", defaultValue: false);
  static const disableRemoteConfig = bool.fromEnvironment("disableRemoteConfig", defaultValue: false);
  static const enableBatchInference = bool.fromEnvironment("enableBatchInference", defaultValue: true);
  static const enableChatDebugger = bool.fromEnvironment("enableChatDebugger");
  static const maxTokens = int.fromEnvironment("maxTokens", defaultValue: -1);
  static const nativeSplashPreserveDurationInMS = int.fromEnvironment("nativeSplashPreserveDurationInMS", defaultValue: 50);
  static const othelloTestCase = int.fromEnvironment("othello_test_case", defaultValue: -1);
  static const showHaloDebugger = bool.fromEnvironment("showHaloDebugger", defaultValue: false);
  static const testingSeeQueue = bool.fromEnvironment("testingSeeQueue", defaultValue: false);
  static const forceShowNewVersionPanel = bool.fromEnvironment("forceShowNewVersionPanel", defaultValue: false);
  static const autoPushTestPage = bool.fromEnvironment("autoPushTestPage", defaultValue: false);
  static const useWindowsSandboxModels = bool.fromEnvironment("useWindowsSandboxModels", defaultValue: false);
  static const distributionChannel = String.fromEnvironment("distributionChannel", defaultValue: "default");
  static const domain = String.fromEnvironment("domain", defaultValue: "https://api.rwkv.halowang.cloud");
  static const webDemoOfficialBaseUrl = String.fromEnvironment(
    "webDemoOfficialBaseUrl",
    defaultValue: "http://47.115.88.183:1801/v1/chat/completions",
  );
  static const webDemoOfficialProtocol = String.fromEnvironment("webDemoOfficialProtocol", defaultValue: "rwkv_lightning_v1");
  static const webDemoOfficialModel = String.fromEnvironment("webDemoOfficialModel", defaultValue: "7b");
  static const webDemoOfficialApiKey = String.fromEnvironment("webDemoOfficialApiKey", defaultValue: _webDemoOfficialApiKeyDefault);
}
