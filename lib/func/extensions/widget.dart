// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo/halo.dart';

extension WidgetDebugger on Widget {
  // TODO: @wangce 如何更优雅地做这件事儿
  Widget get qwe {
    if (!kDebugMode) {
      return this;
    }
    return _WidgetDebugger(child: this);
  }
}

class _WidgetDebugger extends StatelessWidget {
  final Widget child;
  const _WidgetDebugger({required this.child});

  @override
  Widget build(BuildContext context) {
    return child.debug;
  }
}
