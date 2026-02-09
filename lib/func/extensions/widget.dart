import 'package:flutter/material.dart';
import 'package:halo/halo.dart';

extension WidgetDebugger on Widget {
  Widget get qwe {
    return this;
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
