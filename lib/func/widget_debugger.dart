import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zone/widgets/layout_debugger.dart';

extension WidgetDebugger on Widget {
  Widget get debug {
    return debugWith();
  }

  Widget debugWith({Widget? widget}) {
    // return this;
    if (!kDebugMode) return this;
    return LayoutDebugger(
      name: runtimeType.toString(),
      debugWidget: widget,
      child: this,
    );
  }
}
