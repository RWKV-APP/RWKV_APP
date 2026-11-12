// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_theme.dart';

enum AppHomeLayout { gallery, tiles, ledger, feature }

enum AppSurface { flat, lined, outline, raised, cast, bevel }

enum AppStyle {
  classic('Classic'),
  anthropic(
    'Anthropic frontend-design',
    light: AppTheme.tinted(
      storageId: 'anthropic-light',
      isLight: true,
      accent: Color(0xFF873B51),
      canvas: Color(0xFFF9F4ED),
      panel: Color(0xFFEFE7DC),
      card: Color(0xFFFFFBF5),
      bubble: Color(0xFFECDCE1),
    ),
    dark: AppTheme.tinted(
      storageId: 'anthropic-dark',
      isLight: false,
      accent: Color(0xFFF2ADC1),
      canvas: Color(0xFF211921),
      panel: Color(0xFF2A2028),
      card: Color(0xFF31242E),
      bubble: Color(0xFF492D3D),
    ),
    layout: .ledger,
    radius: 3,
    composerRadius: 9,
    gap: 14,
    rowInset: 16,
    headingSize: 36,
    headingWeight: .w600,
    headingTracking: -.9,
    headingFamily: 'serif',
    surface: .lined,
  ),
  proMax(
    'UI UX Pro Max',
    light: AppTheme.tinted(
      storageId: 'proMax-light',
      isLight: true,
      accent: Color(0xFF2257AD),
      canvas: Color(0xFFF1F6FF),
      panel: Color(0xFFE5EEFB),
      card: Color(0xFFFAFCFF),
      bubble: Color(0xFFD9E8FC),
    ),
    dark: AppTheme.tinted(
      storageId: 'proMax-dark',
      isLight: false,
      accent: Color(0xFFADC8FF),
      canvas: Color(0xFF101B32),
      panel: Color(0xFF15223C),
      card: Color(0xFF1A2C4A),
      bubble: Color(0xFF283F66),
    ),
    layout: .tiles,
    radius: 12,
    composerRadius: 14,
    gap: 12,
    rowInset: 14,
    headingSize: 30,
    headingWeight: .w700,
    surface: .outline,
  ),
  taste(
    'Taste',
    light: AppTheme.tinted(
      storageId: 'taste-light',
      isLight: true,
      accent: Color(0xFF6134B0),
      canvas: Color(0xFFF7F1FB),
      panel: Color(0xFFEEE5F6),
      card: Color(0xFFFFF9FF),
      bubble: Color(0xFFEDE0FC),
    ),
    dark: AppTheme.tinted(
      storageId: 'taste-dark',
      isLight: false,
      accent: Color(0xFFD3B4FF),
      canvas: Color(0xFF1D1429),
      panel: Color(0xFF251B35),
      card: Color(0xFF30203F),
      bubble: Color(0xFF432C59),
    ),
    layout: .feature,
    radius: 8,
    composerRadius: 18,
    gap: 14,
    rowInset: 16,
    headingSize: 42,
    headingWeight: .w800,
    headingTracking: -1.4,
    surface: .raised,
  ),
  impeccable(
    'Impeccable',
    light: AppTheme.tinted(
      storageId: 'impeccable-light',
      isLight: true,
      accent: Color(0xFF146149),
      canvas: Color(0xFFF8FBF6),
      panel: Color(0xFFEBF1E9),
      card: Color(0xFFFEFFFB),
      bubble: Color(0xFFDAEBE2),
    ),
    dark: AppTheme.tinted(
      storageId: 'impeccable-dark',
      isLight: false,
      accent: Color(0xFFA6E1C1),
      canvas: Color(0xFF14211C),
      panel: Color(0xFF1B2B23),
      card: Color(0xFF22352C),
      bubble: Color(0xFF2D463A),
    ),
    layout: .ledger,
    radius: 7,
    composerRadius: 12,
    gap: 10,
    rowInset: 14,
    headingSize: 32,
    headingWeight: .w700,
    headingTracking: -.6,
    surface: .outline,
  ),
  emil(
    'Emil’s skills',
    light: AppTheme.tinted(
      storageId: 'emil-light',
      isLight: true,
      accent: Color(0xFF5351A0),
      canvas: Color(0xFFF7F6FE),
      panel: Color(0xFFECECF8),
      card: Color(0xFFFDFCFF),
      bubble: Color(0xFFE6E4FA),
    ),
    dark: AppTheme.tinted(
      storageId: 'emil-dark',
      isLight: false,
      accent: Color(0xFFCCC4FF),
      canvas: Color(0xFF1B1A2B),
      panel: Color(0xFF24223A),
      card: Color(0xFF2C2944),
      bubble: Color(0xFF3D3858),
    ),
    radius: 22,
    composerRadius: 30,
    gap: 12,
    rowInset: 16,
    headingSize: 28,
    headingWeight: .w600,
    headingTracking: -.4,
    surface: .raised,
    motionMs: 155,
  ),
  hallmark(
    'Hallmark',
    light: AppTheme.tinted(
      storageId: 'hallmark-light',
      isLight: true,
      accent: Color(0xFF873A0F),
      canvas: Color(0xFFEAE6DF),
      panel: Color(0xFFDCD7CE),
      card: Color(0xFFF3F0E8),
      bubble: Color(0xFFE8D4C2),
    ),
    dark: AppTheme.tinted(
      storageId: 'hallmark-dark',
      isLight: false,
      accent: Color(0xFFFFB17A),
      canvas: Color(0xFF211F1C),
      panel: Color(0xFF2A2722),
      card: Color(0xFF35302A),
      bubble: Color(0xFF4D3729),
    ),
    layout: .tiles,
    radius: 0,
    composerRadius: 0,
    gap: 12,
    rowInset: 14,
    headingSize: 35,
    headingWeight: .w800,
    headingTracking: -.5,
    headingFamily: 'sans-serif-condensed',
    surface: .cast,
  ),
  vercel(
    'Vercel web-design-guidelines',
    light: AppTheme.tinted(
      storageId: 'vercel-light',
      isLight: true,
      accent: Color(0xFF171717),
      canvas: Color(0xFFFCFCFC),
      panel: Color(0xFFF4F4F4),
      card: Color(0xFFFFFFFF),
      bubble: Color(0xFFECECEC),
    ),
    dark: AppTheme.tinted(
      storageId: 'vercel-dark',
      isLight: false,
      accent: Color(0xFFF5F5F5),
      canvas: Color(0xFF121212),
      panel: Color(0xFF191919),
      card: Color(0xFF232323),
      bubble: Color(0xFF303030),
    ),
    layout: .tiles,
    radius: 5,
    composerRadius: 6,
    gap: 8,
    rowInset: 12,
    headingSize: 32,
    headingWeight: .w700,
    headingTracking: -1,
    surface: .outline,
    motionMs: 110,
  ),
  uiSkills(
    'UI Skills',
    light: AppTheme.tinted(
      storageId: 'uiSkills-light',
      isLight: true,
      accent: Color(0xFF345572),
      canvas: Color(0xFFF4F7F8),
      panel: Color(0xFFEBEFF2),
      card: Color(0xFFF9FCFD),
      bubble: Color(0xFFE1E9EE),
    ),
    dark: AppTheme.tinted(
      storageId: 'uiSkills-dark',
      isLight: false,
      accent: Color(0xFFB9D5EB),
      canvas: Color(0xFF182229),
      panel: Color(0xFF202C34),
      card: Color(0xFF283740),
      bubble: Color(0xFF354752),
    ),
    layout: .ledger,
    radius: 10,
    composerRadius: 10,
    gap: 8,
    rowInset: 10,
    headingSize: 25,
    headingWeight: .w600,
    surface: .flat,
    motionMs: 100,
  ),
  smartisan(
    'Smartisan UI',
    light: AppTheme.tinted(
      storageId: 'smartisan-light',
      isLight: true,
      accent: Color(0xFFB43330),
      canvas: Color(0xFFF6F5F3),
      panel: Color(0xFFEDEAE6),
      card: Color(0xFFFCFBFA),
      bubble: Color(0xFFEFE0DB),
    ),
    dark: AppTheme.tinted(
      storageId: 'smartisan-dark',
      isLight: false,
      accent: Color(0xFFFFA39D),
      canvas: Color(0xFF211D1D),
      panel: Color(0xFF2C2726),
      card: Color(0xFF37302F),
      bubble: Color(0xFF503834),
    ),
    radius: 10,
    composerRadius: 16,
    gap: 10,
    rowInset: 12,
    headingSize: 30,
    headingWeight: .w700,
    surface: .bevel,
    motionMs: 180,
  ),
  ;

  const AppStyle(
    this.label, {
    this.light = AppTheme.light,
    this.dark = AppTheme.lightsOut,
    this.layout = .gallery,
    this.surface = .flat,
    this.radius = 12,
    this.composerRadius = 25,
    this.gap = 12,
    this.rowInset = 8,
    this.headingSize = 24,
    this.headingWeight = .bold,
    this.headingTracking = 0,
    this.headingFamily,
    this.motionMs = 200,
  });

  final String label;
  final AppTheme light;
  final AppTheme dark;
  final AppHomeLayout layout;
  final AppSurface surface;
  final double radius;
  final double composerRadius;
  final double gap;
  final double rowInset;
  final double headingSize;
  final FontWeight headingWeight;
  final double headingTracking;
  final String? headingFamily;
  final int motionMs;

  bool get isClassic => this == classic;
  bool get centered => layout == .gallery;
  double get navigationRadius => isClassic ? 100 : radius;
  double get bubbleRadius => isClassic ? 12 : radius;
  double get rowPadding => isClassic ? 12 : rowInset;

  String displayName(S s) => isClassic ? s.theme_classic : label;

  String? headingFont(TargetPlatform platform) {
    if (platform != TargetPlatform.windows) return headingFamily;
    return switch (headingFamily) {
      'serif' => 'Georgia',
      'sans-serif-condensed' => 'Bahnschrift',
      _ => headingFamily,
    };
  }

  static AppStyle fromId(Object? id) {
    for (final style in values) {
      if (style.name == id) return style;
    }
    return classic;
  }

  BoxDecoration box(AppTheme palette, BorderRadius corners, {Color? fill}) {
    final color = fill ?? palette.settingItem;
    final rule = palette.qb0.withValues(alpha: .15);
    final shadow = Colors.black.withValues(alpha: palette.isLight ? .11 : .30);
    final border = switch (surface) {
      .flat || .raised => null,
      .lined => Border.all(color: palette.primary.withValues(alpha: .30)),
      .outline || .bevel => Border.all(color: rule),
      .cast => Border.all(color: palette.qb0.withValues(alpha: .38)),
    };

    return BoxDecoration(
      color: color,
      borderRadius: corners,
      border: border,
      gradient: surface == .bevel
          ? LinearGradient(
              begin: .topCenter,
              end: .bottomCenter,
              colors: [
                Color.alphaBlend(Colors.white.withValues(alpha: .07), color),
                Color.alphaBlend(Colors.black.withValues(alpha: palette.isLight ? .04 : .10), color),
              ],
            )
          : null,
      boxShadow: switch (surface) {
        .raised => [BoxShadow(color: shadow, blurRadius: 9, offset: const Offset(0, 3))],
        .cast => [BoxShadow(color: palette.qb0.withValues(alpha: .34), offset: const Offset(3, 3))],
        .bevel => [BoxShadow(color: shadow, blurRadius: 3, offset: const Offset(0, 2))],
        _ => null,
      },
    );
  }

  ThemeData applyTo(ThemeData base, {required bool customFont}) {
    if (isClassic) return base;
    final scheme = base.colorScheme.copyWith(
      secondaryContainer: base.colorScheme.surfaceContainerHigh,
      onSecondaryContainer: base.colorScheme.onSurface,
    );
    final corners = BorderRadius.circular(radius);
    final shape = RoundedRectangleBorder(borderRadius: corners);
    final text = base.textTheme;
    TextStyle? title(TextStyle? style) => style?.copyWith(
      fontWeight: headingWeight,
      letterSpacing: headingTracking * (style.fontSize ?? headingSize) / headingSize,
      fontFamily: customFont ? null : headingFont(base.platform),
    );
    final themedText = text.copyWith(
      headlineLarge: title(text.headlineLarge),
      headlineMedium: title(text.headlineMedium),
      headlineSmall: title(text.headlineSmall),
      titleLarge: title(text.titleLarge),
      titleMedium: title(text.titleMedium)?.copyWith(
        letterSpacing: 0,
        fontWeight: headingWeight == .w800 ? .w700 : headingWeight,
      ),
      labelLarge: text.labelLarge?.copyWith(letterSpacing: .25),
    );
    final button = ButtonStyle(
      shape: WidgetStatePropertyAll(shape),
      animationDuration: Duration(milliseconds: motionMs),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return scheme.primary.withValues(alpha: .22);
        if (states.contains(WidgetState.pressed)) return scheme.primary.withValues(alpha: .15);
        return null;
      }),
    );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: themedText,
      appBarTheme: base.appBarTheme.copyWith(centerTitle: centered, titleTextStyle: themedText.titleLarge),
      cardTheme: CardThemeData(color: scheme.surfaceContainer, shape: shape),
      dialogTheme: DialogThemeData(shape: shape),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: .vertical(top: .circular(radius))),
      ),
      chipTheme: base.chipTheme.copyWith(shape: shape),
      popupMenuTheme: base.popupMenuTheme.copyWith(shape: shape),
      filledButtonTheme: FilledButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(style: button),
      textButtonTheme: TextButtonThemeData(style: button),
      elevatedButtonTheme: ElevatedButtonThemeData(style: button),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(borderRadius: corners),
        focusedBorder: OutlineInputBorder(
          borderRadius: corners,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .25),
        selectionHandleColor: scheme.primary,
      ),
    );
  }
}
