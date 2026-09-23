import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/di/di_exports.dart';
import 'core/localization/localization_exports.dart';
import 'core/security/security_exports.dart';
import 'routes/routes_exports.dart';
import 'core/theme/theme_exports.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Framework errors: exceptions thrown while building/laying out/
      // painting a widget.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      // Errors from outside the Flutter framework (e.g. platform channel
      // callbacks, isolate errors)
      
      PlatformDispatcher.instance.onError = (error, stack) {
        _reportError(error, stack);
        return true; // handled — don't crash the app
      };

      await setupLocator();
      await sl<ThemeController>().loadTheme();
      await sl<LocaleController>().loadLocale();
      await sl<SecurityController>().loadSecurity();
      runApp(const MyApp());
    },
    // Errors from uncaught async code (e.g. a Future that's never
    // awaited) that fall outside both hooks above.
    _reportError,
  );
}

void _reportError(Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('Uncaught error: $error\n$stack');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(
          value: sl<ThemeController>(),
        ),
        ChangeNotifierProvider<LocaleController>.value(
          value: sl<LocaleController>(),
        ),
        ChangeNotifierProvider<SecurityController>.value(
          value: sl<SecurityController>(),
        ),
      ],
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, themeController, localeController, _) {
          return MaterialApp.router(
            title: 'Mantic Doc Org',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeController.themeMode,
            locale: localeController.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: AppRoutes.router,
            debugShowCheckedModeBanner: false,
            // Fallback status bar contrast for any screen without its own
            // AppBar (e.g. HomeView) — those otherwise inherit whatever
            // overlay style the previous screen left behind, which can
            // leave the status bar icons invisible against the new
            // background. Screens that do have a CustomAppBar still win
            // here since Material's AppBar nests its own AnnotatedRegion
            // underneath this one.
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Theme.of(context).brightness == .dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: Theme.of(context).brightness,
              ),
              child: AppLockGate(child: child ?? const SizedBox.shrink()),
            ),
          );
        },
      ),
    );
  }
}
