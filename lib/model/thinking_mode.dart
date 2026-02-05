enum ThinkingMode {
  /// 不加思考标签，普通回答
  none(
    header: '',
    userMsgFooter: '',
    forceReasoning: false,
  ),

  /// 旧模式：加思考标签但不强制推理（已废弃，改用 fast）
  @Deprecated('Use .fast instead')
  lighting(
    header: '<think>\n</think>',
    userMsgFooter: '',
    forceReasoning: false,
  ),

  /// 推荐模式：短暂思考标签，不强制推理
  fast(
    header: '<think>\n</think',
    userMsgFooter: '',
    forceReasoning: false,
  ),

  /// 完全自由推理：`<think` 开头，强制推理
  free(
    header: '<think',
    userMsgFooter: '',
    forceReasoning: true,
  ),

  /// 中文偏好推理
  preferChinese(
    header: '<think>嗯',
    userMsgFooter: '',
    forceReasoning: true,
  ),

  /// 英文推理（后缀提示）
  en(
    header: '<think',
    userMsgFooter: ' (think)',
    forceReasoning: true,
  ),

  /// 英文短思考
  enShort(
    header: '<think',
    userMsgFooter: ' (think a bit)',
    forceReasoning: true,
  ),

  /// 英文长思考
  enLong(
    header: '<think',
    userMsgFooter: ' (think a lot)',
    forceReasoning: true,
  )
  ;

  const ThinkingMode({
    required this.header,
    required this.userMsgFooter,
    required this.forceReasoning,
  });

  final String header;
  final String userMsgFooter;
  final bool forceReasoning;

  bool get hasThinkTag => header.startsWith('<think');

  /// 兼容旧字符串存储格式，例如 ".Fast"
  static ThinkingMode fromString(String? runningMode) {
    return switch (runningMode) {
      ".None" => .none,
      ".Lighting" => .fast,
      ".Free" => .free,
      ".PreferChinese" => .preferChinese,
      ".Fast" => .fast,
      ".En" => .en,
      ".EnShort" => .enShort,
      ".EnLong" => .enLong,
      _ => .none,
    };
  }

  /// 保持与旧实现一致的 toString，继续返回 ".Xxx"
  @override
  String toString() =>
      '.${switch (this) {
        .none => 'None',
        .lighting => 'Lighting',
        .fast => 'Fast',
        .free => 'Free',
        .preferChinese => 'PreferChinese',
        .en => 'En',
        .enShort => 'EnShort',
        .enLong => 'EnLong',
      }}';
}
