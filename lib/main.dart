import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/database/database_exports.dart';
import 'core/di/di_exports.dart';
import 'core/localization/localization_exports.dart';
import 'core/notifications/notifications_exports.dart';
import 'core/security/security_exports.dart';
import 'core/sharing/sharing_exports.dart';
import 'features/home/home_exports.dart';
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

      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {
        // Ignore — see comment above.
      }

      await setupLocator();
      // Must be ready before DocumentLocalStore.init() below, which
      // schedules/reconciles every active document's expiry reminders as
      // soon as it hydrates.
      await sl<ExpiryNotificationService>().init();
      // Hydrates the in-memory document/category caches from sqflite
      // before the first frame — see AppDatabase/CategoryLocalStore/
      // DocumentLocalStore (core/database, features/home) for why this is
      // safe to block runApp() on: it's a local, fast read.
      await sl<AppDatabase>().init();
      await sl<CategoryLocalStore>().init();
      await sl<DocumentLocalStore>().init();
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
            builder: (context, child) {
              // Re-runs on every locale change (this builder sits below
              // MaterialApp's own Localizations widget), so newly scheduled
              // expiry reminders always use the app's current language —
              // see ExpiryNotificationService.updateLocalizedStrings.
              sl<ExpiryNotificationService>().updateLocalizedStrings(
                AppLocalizations.of(context),
              );
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Theme.of(context).brightness == .dark
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: Theme.of(context).brightness,
                ),
                child: ShareIntentListener(
                  child: ExpiryDigestListener(
                    child: AppLockGate(child: child ?? const SizedBox.shrink()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
