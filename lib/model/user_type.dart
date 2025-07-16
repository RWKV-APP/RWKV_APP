import 'package:zone/gen/l10n.dart';

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
        return S.current.beginner;
      case UserType.powerUser:
        return S.current.power_user;
      case UserType.expert:
        return S.current.expert;
    }
  }
}
