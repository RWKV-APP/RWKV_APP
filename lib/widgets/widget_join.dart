// Flutter imports:
import 'package:flutter/widgets.dart';

List<Widget> joinWidgets(
  List<Widget> values,
  Widget Function(int previousIndex) convert,
) {
  final result = <Widget>[];
  final itemCount = values.length;
  for (int i = 0; i < itemCount; i++) {
    result.add(values[i]);
    if (i >= itemCount - 1) continue;
    result.add(convert(i));
  }
  return result;
}
