import 'package:zone/gen/l10n.dart' show S;

/// LLM 解码参数类型枚举
///
/// 定义了不同的文本生成参数预设，用于控制大语言模型的输出行为。
/// 每个预设包含五个关键参数：temperature、topP、presencePenalty、frequencyPenalty 和 penaltyDecay。
enum DecodeParamType {
  /// 未知/自定义类型
  ///
  /// 所有参数值为 -1，表示用户自定义配置，不属于任何预设类型。
  custom(
    temperature: -1,
    topP: -1,
    presencePenalty: -1,
    frequencyPenalty: -1,
    penaltyDecay: -1,
  ),

  /// 创意模式
  ///
  /// 适合创意写作、头脑风暴等需要多样性和创新性的场景。
  /// - 中等温度值，允许一定随机性
  /// - 较高的 topP 值，增加候选 token 多样性
  /// - 强存在惩罚，鼓励探索新话题和词汇
  /// - 适度的频率惩罚，减少重复
  creative(
    temperature: 0.6,
    topP: 0.6,
    presencePenalty: 2,
    frequencyPenalty: 0.2,
    penaltyDecay: 0.990,
  ),

  /// 保守模式
  ///
  /// 适合事实性回答、技术文档等需要准确性和可预测性的场景。
  /// - 低温度值，输出更确定
  /// - 低 topP 值，聚焦高概率 token
  /// - 无惩罚机制，允许重复以保持一致性
  conservative(
    temperature: 0.4,
    topP: 0.4,
    presencePenalty: 1,
    frequencyPenalty: 0.1,
    penaltyDecay: 0.99,
  ),

  /// 固定模式
  ///
  /// 确定性最高的模式，适合需要完全可预测输出的场景。
  /// - 极低温度值，几乎完全确定
  /// - topP 为 0，仅选择最高概率的 token
  /// - 无惩罚机制
  fixed(
    temperature: 0.2,
    topP: 0,
    presencePenalty: 0,
    frequencyPenalty: 0,
    penaltyDecay: 0.99,
  ),

  /// 综合模式
  ///
  /// 平衡多样性与质量的模式，适合需要全面回答的场景。
  /// - 标准温度值，保持自然随机性
  /// - 较保守的 topP，确保质量
  /// - 强存在惩罚，鼓励话题多样性
  /// - 适度频率惩罚，减少重复
  comprehensive(
    temperature: 1,
    topP: 0.3,
    presencePenalty: 2,
    frequencyPenalty: 0.2,
    penaltyDecay: 0.99,
  ),

  /// 默认模式
  ///
  /// 通用场景的平衡配置，适合大多数对话和文本生成任务。
  /// - 标准温度值
  /// - 较保守的 topP，确保输出质量
  /// - 中等存在惩罚，适度鼓励多样性
  /// - 轻微频率惩罚，减少明显重复
  defaults(
    temperature: 1,
    topP: 0.3,
    presencePenalty: 1,
    frequencyPenalty: 0.1,
    penaltyDecay: 0.99,
  )
  ;

  /// 温度参数（Temperature）
  ///
  /// 控制输出的随机性：
  /// - 值越高（如 1.0-2.0）：输出越随机、多样、有创意
  /// - 值越低（如 0.1-0.3）：输出越确定、保守、可预测
  /// - 典型范围：0.2 - 2.0
  final double temperature;

  /// Top-P 参数（核采样）
  ///
  /// 从累积概率达到 P 的 token 集合中采样：
  /// - 值越高（如 0.6-1.0）：候选 token 越多，多样性越高
  /// - 值越低（如 0.0-0.3）：候选 token 越少，输出更聚焦
  /// - 0.0 表示仅选择最高概率的 token（贪婪解码）
  /// - 典型范围：0.0 - 1.0
  final double topP;

  /// 存在惩罚（Presence Penalty）
  ///
  /// 惩罚已出现过的 token，鼓励探索新话题和词汇：
  /// - 值越高（如 1.0-2.0）：越避免重复，话题转换越频繁
  /// - 值越低（如 0.0-0.5）：允许更多重复，保持话题一致性
  /// - 0.0 表示不进行存在惩罚
  /// - 典型范围：0.0 - 2.0
  final double presencePenalty;

  /// 频率惩罚（Frequency Penalty）
  ///
  /// 惩罚频繁出现的 token，减少词汇重复：
  /// - 值越高（如 0.5-2.0）：越减少重复词汇
  /// - 值越低（如 0.0-0.2）：允许更多重复
  /// - 0.0 表示不进行频率惩罚
  /// - 典型范围：0.0 - 2.0
  final double frequencyPenalty;

  /// 惩罚衰减（Penalty Decay）
  ///
  /// 控制惩罚强度随时间的衰减速度：
  /// - 值越低（如 0.99）：衰减越快，后期惩罚更弱
  /// - 值越高（如 0.995-0.999）：衰减越慢，惩罚持续更久
  /// - 典型范围：0.99 - 0.999
  final double penaltyDecay;

  String get displayNameShort => switch (this) {
    defaults => S.current.decode_param_default_short,
    creative => S.current.decode_param_creative_short,
    conservative => S.current.decode_param_conservative_short,
    fixed => S.current.decode_param_fixed_short,
    comprehensive => S.current.decode_param_comprehensive_short,
    custom => S.current.decode_param_custom_short,
  };

  /// 创建解码参数类型实例
  const DecodeParamType({
    required this.temperature,
    required this.topP,
    required this.presencePenalty,
    required this.frequencyPenalty,
    required this.penaltyDecay,
  });

  /// 根据参数值查找对应的解码参数类型
  ///
  /// 如果找到完全匹配的预设类型，返回该类型；否则返回 [custom]。
  ///
  /// 参数：
  /// - [temperature]: 温度参数值
  /// - [topP]: Top-P 参数值
  /// - [presencePenalty]: 存在惩罚值
  /// - [frequencyPenalty]: 频率惩罚值
  /// - [penaltyDecay]: 惩罚衰减值
  ///
  /// 返回：匹配的 [DecodeParamType]，如果未找到则返回 [custom]
  static DecodeParamType fromValue({
    required double temperature,
    required double topP,
    required double presencePenalty,
    required double frequencyPenalty,
    required double penaltyDecay,
  }) {
    for (final type in values) {
      if (type.temperature == temperature &&
          type.topP == topP &&
          type.presencePenalty == presencePenalty &&
          type.frequencyPenalty == frequencyPenalty &&
          type.penaltyDecay == penaltyDecay) {
        return type;
      }
    }
    return custom;
  }
}
