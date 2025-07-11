enum UserType {
  user,
  powerUser,
  expert;

  bool isGreaterThan(UserType other) {
    return index > other.index;
  }

  String displayName() {
    switch (this) {
      case UserType.user:
        return "普通用户";
      case UserType.powerUser:
        return "高级用户";
      case UserType.expert:
        return "专家用户";
    }
  }
}
