import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/language.dart';
import 'package:zone/route/router.dart';
import 'package:zone/state/p.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:zone/widgets/debugger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await _loadEnv();
  HF.init();
  await P.init();
  if (kDebugMode) {
    await _debugAppRunner();
  } else {
    await _sentryAppRunner();
  }
  // runApp(const _TestApp());
  await HF.wait(50);
  FlutterNativeSplash.remove();
}

// ignore: unused_element
class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}

FV _loadEnv() async {
  try {
    await dotenv.load(fileName: ".env");
    Config.xApiKey = dotenv.env["x-api-key"] ?? "";
  } catch (e) {
    qqe(e);
    if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
  }
}

FV _sentryAppRunner() async {
  await SentryFlutter.init(
    _configureSentry,
    appRunner: () {
      runApp(const _StateWrapper());
    },
  );
}

FV _debugAppRunner() async {
  runApp(const _StateWrapper());
}

FutureOr<void> _configureSentry(SentryFlutterOptions options) {
  options.dsn = 'https://320015d75031601a48829d02f17a8394@o4506895545597952.ingest.us.sentry.io/4508996340482048';
  options.tracesSampleRate = kDebugMode ? 1.0 : .05;
  options.profilesSampleRate = kDebugMode ? 1.0 : .05;
  options.debug = kDebugMode;
  options.diagnosticLevel = SentryLevel.warning;
  if (kReleaseMode) {
    options.environment = 'production';
  } else if (kProfileMode) {
    options.environment = 'testing';
  } else {
    options.environment = 'development';
  }
}

final _supportedLocales = Language.values.where((e) => e != Language.none).map((e) => e.locale).toList();

class _StateWrapper extends ConsumerWidget {
  const _StateWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    P.app.firstContextGot(context);
    return const StateWrapper(child: _App());
  }
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ref.watch(P.app.isDesktop);
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final customTheme = ref.watch(P.app.customTheme);
    final brightness = customTheme.light ? Brightness.light : Brightness.dark;
    final demoTypeColorScheme = customTheme.light ? P.app.demoType.q.colorScheme : P.app.demoType.q.colorSchemeDark;
    final modalBarrierColor = customTheme.pagerDim.q(.25);
    final bottomSheetTheme = BottomSheetThemeData(backgroundColor: customTheme.setting, modalBarrierColor: modalBarrierColor);
    final appBarTheme = AppBarTheme(scrolledUnderElevation: 0, backgroundColor: customTheme.scaffold);

    final themeData = ThemeData(
      fontFamilyFallback: isDesktop ? Config.fontFamilyFallback : null,
      brightness: brightness,
      colorScheme: demoTypeColorScheme,
      appBarTheme: appBarTheme,
      scaffoldBackgroundColor: customTheme.scaffold,
      bottomSheetTheme: bottomSheetTheme,
    );

    return MaterialApp.router(
      color: customTheme.scaffold,
      supportedLocales: _supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: preferredThemeMode,
      theme: themeData,
      darkTheme: themeData,
      debugShowCheckedModeBanner: kDebugMode,
      routerConfig: kRouter,
      builder: _builder,
    );
  }

  Widget _builder(BuildContext context, Widget? child) {
    final customTheme = P.app.customTheme.q;
    return _LocaleWrapper(
      child: _TextScaleWrapper(
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, top: 0, bottom: 0, child: C(color: customTheme.scaffold)),
            if (child != null) child,
            const Alert(),
            if (kDebugMode) const Debugger(),
          ],
        ),
      ),
    );
  }
}

class _TextScaleWrapper extends ConsumerWidget {
  final Widget child;

  const _TextScaleWrapper({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredTextScaleFactor = ref.watch(P.preference.preferredTextScaleFactor);
    if (preferredTextScaleFactor == P.preference.textScaleFactorSystem) return child;
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: preferredTextScaleFactor,
      maxScaleFactor: preferredTextScaleFactor,
      child: child,
    );
  }
}

class _LocaleWrapper extends ConsumerWidget {
  final Widget child;

  const _LocaleWrapper({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(P.preference.preferredLanguage);
    Locale locale = language.resolved.locale;
    return Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }
}
