enum MessageType {
  text,
  userImage,
  userTTS,
  ttsGeneration,
  @Deprecated("Xuan 说 RWKV-See 不添加 Audio QA 功能")
  userAudio,
}
