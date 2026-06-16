// Flutter imports:
import 'package:flutter/services.dart';

final RegExp albatrossHostCharacterPattern = RegExp(r'[A-Za-z0-9.\-:\[\]]');

List<TextInputFormatter> buildAlbatrossHostInputFormatters() {
  return <TextInputFormatter>[
    FilteringTextInputFormatter.allow(albatrossHostCharacterPattern),
    LengthLimitingTextInputFormatter(253),
  ];
}

List<TextInputFormatter> buildAlbatrossPortInputFormatters() {
  return <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(5),
  ];
}
