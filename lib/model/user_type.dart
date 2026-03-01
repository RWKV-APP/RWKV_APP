// Project imports:
import 'package:zone/gen/l10n.dart';

enum UserType {
  user,
  powerUser,
  expert
  ;

  bool isGreaterThan(UserType other) {
    return index > other.index;
  }

  String displayName() {
    switch (this) {
      case .user:
        return S.current.beginner;
      case .powerUser:
        return S.current.power_user;
      case .expert:
        return S.current.expert;
    }
  }
}
