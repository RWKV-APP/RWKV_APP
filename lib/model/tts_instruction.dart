enum TTSInstruction {
  none,
  emotion,
  dialect,
  speed,
  role,
  intonation;

  String get nameCN => switch (this) {
    emotion => "情感",
    dialect => "方言",
    speed => "语速",
    role => "角色扮演",
    intonation => "语气词",
    none => "无",
  };

  String get nameEN => switch (this) {
    emotion => "emotion",
    dialect => "dialect",
    speed => "speed",
    role => "role",
    intonation => "intonation",
    none => "none",
  };

  bool get forInstruction => switch (this) {
    none => false,
    intonation => false,
    _ => true,
  };

  String get tail => switch (this) {
    none => "",
    intonation => "",
    emotion => "的情感",
    dialect => "的口音",
    speed => "的语速",
    role => "的声音",
  };

  String get head => switch (this) {
    none => "",
    intonation => "",
    emotion => "",
    dialect => "模仿",
    speed => "以",
    role => "用",
  };

  List<String> get options => switch (this) {
    none => [],
    emotion => [
      "高兴",
      "悲伤",
      "惊讶",
      "愤怒",
      "恐惧",
      "厌恶",
      "冷静",
      "严肃",
    ],
    dialect => [
      "粤语",
      "四川话",
      "上海话",
      "郑州话",
      "长沙话",
      "天津话",
    ],
    speed => [
      "快速",
      "非常快速",
      "慢速",
      "非常慢速",
    ],
    role => [
      "神秘",
      "凶猛",
      "好奇",
      "优雅",
      "孤独",
      "机器人",
      "小猪佩奇",
    ],
    intonation => [
      "[breath]",
      "[noise]",
      "[laughter]",
      "[cough]",
      "[clucking]",
      "[accent]",
      "[quick_breath]",
      "[hissing]",
      "[sigh]",
      "[vocalized-noise]",
      "[lipsmack]",
      "[mn]",
    ],
  };

  List<String> get emojiOptions => switch (this) {
    intonation => [
      "😮‍💨",
      "🔊",
      "😂",
      "🤧",
      "🐔",
      "🗣️",
      "😤",
      "🐍",
      "😔",
      "🎤",
      "😗",
      "🤔",
    ],
    _ => [],
  };
}
