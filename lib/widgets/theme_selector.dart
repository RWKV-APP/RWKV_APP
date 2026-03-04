// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/form_item.dart';

class ThemeSelector extends ConsumerWidget {
  static final _shown = qs(false);

  static Future<void> show() async {
    qq;
    if (_shown.q) return;
    _shown.q = true;
    final context = getContext();
    if (context == null || !context.mounted) {
      _shown.q = false;
      return;
    }
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
    final appTheme = ref.watch(P.app.theme);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Scaffold(
        backgroundColor: appTheme.settingBg,
        appBar: AppBar(
          title: Text(s.appearance),
          automaticallyImplyLeading: false,
          backgroundColor: appTheme.settingBg,
          actions: [
            Padding(
              padding: const .only(right: 8),
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
          padding: const .only(left: 12, right: 12),
          itemBuilder: (context, index) {
            return const ThemeColorSettingSection();
          },
          itemCount: 1,
        ),
      ),
    );
  }
}

class ThemeColorSettingSection extends ConsumerWidget {
  final bool showDarkThemeTitle;

  const ThemeColorSettingSection({
    super.key,
    this.showDarkThemeTitle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final preferredDarkCustomTheme = ref.watch(P.preference.preferredDarkCustomTheme);
    final isLight = appTheme.isLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormItem(
          icon: Icon(Icons.dark_mode_outlined, color: qb.q(.667), size: 16),
          title: s.dark_mode,
          subtitle: s.force_dark_mode,
          showArrow: false,
          isSectionStart: true,
          onTap: null,
          trailing: Switch.adaptive(
            value: !isLight,
            onChanged: _onDarkModeSwitchChanged,
            activeThumbColor: appTheme.themePrimary,
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
            activeThumbColor: appTheme.themePrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (showDarkThemeTitle)
          Row(
            mainAxisAlignment: .start,
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  s.dark_mode_theme,
                  style: TS(w: .w500, c: qb.q(.8), s: 12),
                ),
              ),
            ],
          ),
        if (showDarkThemeTitle) const SizedBox(height: 12),
        FormItem(
          title: s.theme_dim,
          showArrow: false,
          isSectionStart: true,
          onTap: _onDimPressed,
          trailing: IconButton(
            icon: Icon(
              preferredDarkCustomTheme == .dim ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: preferredDarkCustomTheme == .dim ? appTheme.themePrimary : qb.q(.33),
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
              preferredDarkCustomTheme == .lightsOut ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: preferredDarkCustomTheme == .lightsOut ? appTheme.themePrimary : qb.q(.33),
            ),
            onPressed: _onLightsOutPressed,
          ),
        ),
      ],
    );
  }

  void _onLightsOutPressed() async {
    P.preference.preferredDarkCustomTheme.q = .lightsOut;
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.preferredDarkCustomTheme", P.app.theme.q.toString());
  }

  void _onDimPressed() async {
    P.preference.preferredDarkCustomTheme.q = .dim;
    final sp = await SharedPreferences.getInstance();
    await sp.setString("halo_state.preferredDarkCustomTheme", P.app.theme.q.toString());
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
