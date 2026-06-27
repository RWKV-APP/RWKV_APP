import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Size size)? onChange;
  final void Function(Rect rect)? onRectChange;

  const MeasureSize({
    super.key,
    this.onChange,
    this.onRectChange,
    required Widget super.child,
  }) : assert(onChange != null || onRectChange != null);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(
      onChange: onChange,
      onRectChange: onRectChange,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
    renderObject.onRectChange = onRectChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;
  void Function(Size size)? onChange;
  void Function(Rect rect)? onRectChange;

  _MeasureSizeRenderObject({
    required this.onChange,
    required this.onRectChange,
  });

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child!.size;
    if (oldSize == newSize) return;
    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange?.call(newSize);
      final rectChange = onRectChange;
      if (rectChange == null) return;
      final offset = localToGlobal(Offset.zero);
      rectChange(offset & newSize);
    });
  }
}
