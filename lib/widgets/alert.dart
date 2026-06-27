import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/func/shortcuts.dart';

enum AlertPosition {
  top,
  bottom,
  center,
}

enum _AlertNotifyStatus {
  success,
  warning,
  error,
  info,
}

enum _AlertDisplayStatus {
  deploy,
  show,
  hide,
}

@immutable
final class _AlertItem {
  final int id;
  final String message;
  final _AlertNotifyStatus status;
  final _AlertDisplayStatus displayStatus;
  final AlertPosition position;
  final Color? color;

  const _AlertItem({
    required this.id,
    required this.message,
    required this.status,
    required this.displayStatus,
    required this.position,
    this.color,
  });

  _AlertItem copyWith({
    _AlertDisplayStatus? displayStatus,
  }) {
    return _AlertItem(
      id: id,
      message: message,
      status: status,
      displayStatus: displayStatus ?? this.displayStatus,
      position: position,
      color: color,
    );
  }
}

class Alert extends StatelessWidget {
  static AlertPosition defaultPosition = AlertPosition.top;

  static Color? Function()? defaultColor;
  static Color? Function()? defaultSuccessColor;
  static Color? Function()? defaultWarningColor;
  static Color? Function()? defaultErrorColor;
  static Color? Function()? defaultInfoColor;

  static ThemeMode? preferredThemeMode;
  static double topAdjustment = 0.0;
  static double centerAdjustment = 0.0;
  static double bottomAdjustment = 0.0;

  const Alert({super.key});

  static Future<void> success(
    String msg, {
    bool noDuplicate = true,
    AlertPosition? position,
    Color? color,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch;
    return _AlertStates.show(
      id: id,
      message: msg,
      notifyStatus: _AlertNotifyStatus.success,
      position: position ?? defaultPosition,
      noDuplicate: noDuplicate,
      color: color ?? defaultSuccessColor?.call() ?? defaultColor?.call(),
    );
  }

  static Future<void> warning(
    String msg, {
    bool noDuplicate = true,
    AlertPosition? position,
    Color? color,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch;
    return _AlertStates.show(
      id: id,
      message: msg,
      notifyStatus: _AlertNotifyStatus.warning,
      position: position ?? defaultPosition,
      noDuplicate: noDuplicate,
      color: color ?? defaultWarningColor?.call() ?? defaultColor?.call(),
    );
  }

  static Future<void> error(
    String msg, {
    bool noDuplicate = true,
    AlertPosition? position,
    Color? color,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch;
    return _AlertStates.show(
      id: id,
      message: msg,
      notifyStatus: _AlertNotifyStatus.error,
      position: position ?? defaultPosition,
      noDuplicate: noDuplicate,
      color: color ?? defaultErrorColor?.call() ?? defaultColor?.call(),
    );
  }

  static Future<void> info(
    String msg, {
    bool noDuplicate = true,
    AlertPosition? position,
    Color? color,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch;
    return _AlertStates.show(
      id: id,
      message: msg,
      notifyStatus: _AlertNotifyStatus.info,
      position: position ?? defaultPosition,
      noDuplicate: noDuplicate,
      color: color ?? defaultInfoColor?.call() ?? defaultColor?.call(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _AlertStates.container,
      child: const IgnorePointer(child: _AlertHud()),
    );
  }
}

class _AlertStates {
  static final items = StateProvider<List<_AlertItem>>((ref) => []);
  static final container = ProviderContainer();

  static FV show({
    required int id,
    required String message,
    required _AlertNotifyStatus notifyStatus,
    AlertPosition position = AlertPosition.top,
    bool noDuplicate = true,
    Color? color,
  }) async {
    final current = container.read(items);

    if (noDuplicate) {
      final containMessage = current.any((e) => e.message == message);
      if (containMessage) return;
    }

    final nextDeploy = [
      ...current,
      _AlertItem(
        id: id,
        message: message,
        status: notifyStatus,
        displayStatus: _AlertDisplayStatus.deploy,
        position: position,
        color: color,
      ),
    ];
    container.read(items.notifier).state = nextDeploy;

    await HF.wait(10);
    _updateDisplayStatus(id, _AlertDisplayStatus.show);

    await HF.wait(1900 + math.min(4000, message.length * 20).toInt());
    _updateDisplayStatus(id, _AlertDisplayStatus.hide);

    await HF.wait(250);
    final currentBeforeRemove = container.read(items);
    final nextRemove = currentBeforeRemove.where((e) => e.id != id).toList();
    nextRemove.sort((left, right) => left.id - right.id);
    container.read(items.notifier).state = nextRemove;
  }

  static void _updateDisplayStatus(int id, _AlertDisplayStatus displayStatus) {
    final current = container.read(items);
    final index = current.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final next = [...current];
    next[index] = next[index].copyWith(displayStatus: displayStatus);
    next.sort((left, right) => left.id - right.id);
    container.read(items.notifier).state = next;
  }
}

class _AlertHud extends ConsumerWidget {
  const _AlertHud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(_AlertStates.items);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final paddingTop = MediaQuery.paddingOf(context).top;
    final paddingBottom = MediaQuery.paddingOf(context).bottom;

    final themeMode = Alert.preferredThemeMode ?? ThemeMode.system;

    return Material(
      color: kC,
      child: Stack(
        children: items.indexMap((index, value) {
          final isLight = switch (themeMode) {
            ThemeMode.system => View.of(context).platformDispatcher.platformBrightness == Brightness.light,
            ThemeMode.light => true,
            ThemeMode.dark => false,
          };

          final item = items[index];
          final message = item.message;
          final notifyStatus = item.status;
          late final Color color;
          late final IconData iconData;

          switch (notifyStatus) {
            case _AlertNotifyStatus.warning:
              color = item.color ?? Colors.yellow[800]!;
              iconData = Icons.info_outline_rounded;
            case _AlertNotifyStatus.error:
              color = item.color ?? kCR;
              iconData = Icons.error_outline;
            case _AlertNotifyStatus.success:
              color = item.color ?? kCG;
              iconData = Icons.check_circle_outline_rounded;
            case _AlertNotifyStatus.info:
              color = item.color ?? kCB;
              iconData = Icons.info_outline_rounded;
          }

          final alignment = switch (item.position) {
            AlertPosition.top => Alignment.topCenter,
            AlertPosition.bottom => Alignment.bottomCenter,
            AlertPosition.center => Alignment.center,
          };

          final double? top = switch (item.position) {
            AlertPosition.top => item.displayStatus == _AlertDisplayStatus.show ? paddingTop + 12 : paddingTop - 50,
            AlertPosition.bottom => null,
            AlertPosition.center => item.displayStatus == _AlertDisplayStatus.show ? -10 : 10,
          };

          final double? bottom = switch (item.position) {
            AlertPosition.top => null,
            AlertPosition.bottom => item.displayStatus == _AlertDisplayStatus.show ? paddingBottom + 34 : paddingBottom - 50,
            AlertPosition.center => null,
          };

          final key = Key("Alert${item.id}");
          final duration = item.displayStatus == _AlertDisplayStatus.show ? 250.ms : 150.ms;
          const iconHorizontalDistance = 8.0;
          final borderWidth = isLight ? 0.0 : 1.0;

          return AP(
            key: key,
            duration: duration,
            curve: item.displayStatus == _AlertDisplayStatus.show ? Curves.easeOutBack : Curves.easeInBack,
            top: top != null ? top + Alert.topAdjustment + Alert.centerAdjustment : null,
            bottom: bottom != null ? bottom + Alert.bottomAdjustment : null,
            height: screenHeight,
            width: screenWidth,
            child: AO(
              duration: duration,
              curve: item.displayStatus == _AlertDisplayStatus.show ? Curves.easeOutBack : Curves.easeInBack,
              opacity: item.displayStatus == _AlertDisplayStatus.show ? 1 : 0,
              child: C(
                decoration: const BD(color: kC),
                child: Stack(
                  children: [
                    Positioned(
                      child: Align(
                        alignment: alignment,
                        child: C(
                          padding: const EI.a(12),
                          decoration: BD(
                            color: isLight ? kW : kB,
                            borderRadius: 10.r,
                            border: Border.all(
                              color: color.q(0.33),
                              width: borderWidth,
                            ),
                            boxShadow: [
                              if (isLight)
                                BoxShadow(
                                  color: kB.q(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(iconData, color: color),
                              iconHorizontalDistance.w,
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth * 0.85 - 16 - iconHorizontalDistance - borderWidth * 2,
                                ),
                                child: T(
                                  message,
                                  s: TS(c: color, w: .w600),
                                  maxLines: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
