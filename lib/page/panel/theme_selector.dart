// ignore: unused_import
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:halo_state/halo_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/route/method.dart';
import 'package:zone/route/router.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/form_item.dart';
import 'package:zone/model/custom_theme.dart' as custom_theme;

class ThemeSelector extends ConsumerWidget {
  static final _shown = qs(false);

  static Future<void> show() async {
    qq;
    if (_shown.q) return;
    _shown.q = true;
    final context = getContext();
    if (context == null) return;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .75,
          maxChildSize: .85,
          minChildSize: .5,
          expand: false,
          snap: false,
          builder: (context, scrollController) {
            return ThemeSelector(scrollController);
          },
        );
      },
    );
    _shown.q = false;
  }

  final ScrollController? scrollController;

  const ThemeSelector(this.scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final customTheme = ref.watch(P.app.customTheme);
    final qb = ref.watch(P.app.qb);
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final preferredDarkCustomTheme = ref.watch(P.preference.preferredDarkCustomTheme);
    final primary = Theme.of(context).colorScheme.primary;
    final themeMode = ref.watch(P.preference.themeMode);

    final items = <Widget>[
      FormItem(
        icon: Icon(Icons.dark_mode_outlined, color: qb.q(.667), size: 16),
        title: s.dark_mode,
        subtitle: s.force_dark_mode,
        showArrow: false,
        isSectionStart: true,
        onTap: null,
        trailing: Switch.adaptive(
          value: preferredThemeMode == ThemeMode.dark,
          onChanged: _onDarkModeSwitchChanged,
        ),
      ),
      FormItem(
        icon: Icon(Icons.auto_mode, color: qb.q(.667), size: 16),
        title: s.system_mode,
        subtitle: s.color_theme_follow_system,
        showArrow: false,
        isSectionStart: false,
        isSectionEnd: true,
        onTap: null,
        trailing: Switch.adaptive(
          value: preferredThemeMode == ThemeMode.system,
          onChanged: _onAutoModeSwitchChanged,
        ),
      ),
      12.h,
      Row(
        mainAxisAlignment: MAA.start,
        children: [
          4.w,
          Expanded(
            child: T(
              s.dark_mode_theme,
              s: TS(w: FW.w500, c: qb.q(.8), s: 12),
            ),
          ),
        ],
      ),
      12.h,
      FormItem(
        title: s.theme_dim,
        showArrow: false,
        isSectionStart: true,
        onTap: _onDimPressed,
        trailing: IconButton(
          icon: Icon(
            preferredDarkCustomTheme is custom_theme.Dim ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
            color: preferredDarkCustomTheme is custom_theme.Dim ? primary : qb.q(.33),
          ),
          onPressed: _onDimPressed,
        ),
      ),
      FormItem(
        title: s.theme_lights_out,
        showArrow: false,
        isSectionStart: false,
        isSectionEnd: true,
        onTap: _onLightsOutPressed,
        trailing: IconButton(
          icon: Icon(
            preferredDarkCustomTheme is custom_theme.LightsOut ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
            color: preferredDarkCustomTheme is custom_theme.LightsOut ? primary : qb.q(.33),
          ),
          onPressed: _onLightsOutPressed,
        ),
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: customTheme.setting,
        appBar: AppBar(
          title: T(s.appearance),
          automaticallyImplyLeading: false,
          backgroundColor: customTheme.setting,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  pop();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
        body: ListView.builder(
          controller: scrollController,
          padding: const EI.o(
            l: 12,
            r: 12,
          ),
          itemBuilder: (context, index) {
            return items[index];
          },
          itemCount: items.length,
        ),
      ),
    );
  }

  void _onLightsOutPressed() async {
    P.preference.preferredDarkCustomTheme.q = custom_theme.LightsOut();
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.preferredDarkCustomTheme", P.app.customTheme.q.toString());
  }

  void _onDimPressed() async {
    P.preference.preferredDarkCustomTheme.q = custom_theme.Dim();
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.preferredDarkCustomTheme", P.app.customTheme.q.toString());
  }

  void _onAutoModeSwitchChanged(bool value) async {
    qq;
    if (value) {
      P.app.preferredThemeMode.q = ThemeMode.system;
    } else {
      P.app.preferredThemeMode.q = ThemeMode.light;
    }
    P.preference.themeMode.q = P.app.preferredThemeMode.q;
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.themeMode", P.preference.themeMode.q.name);
  }

  void _onDarkModeSwitchChanged(bool value) async {
    if (value) {
      P.app.preferredThemeMode.q = ThemeMode.dark;
    } else {
      P.app.preferredThemeMode.q = ThemeMode.light;
    }
    P.preference.themeMode.q = P.app.preferredThemeMode.q;
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.themeMode", P.preference.themeMode.q.name);
  }
}
