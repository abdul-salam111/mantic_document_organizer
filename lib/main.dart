import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/background/auto_import_service.dart';
import 'core/database/database_exports.dart';
import 'core/di/di_exports.dart';
import 'core/localization/localization_exports.dart';
import 'core/networks/networks_exports.dart';
import 'core/notifications/notifications_exports.dart';
import 'core/security/security_exports.dart';
import 'core/sharing/sharing_exports.dart';
import 'features/categories/domain/usecases/category_usecases.dart';
import 'features/documents/domain/usecases/document_usecases.dart';
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
      // Shared flutter_local_notifications plugin -- must be initialized
      // before any service that sends notifications through it.
      await sl<AppNotificationPlugin>().init();
      // Must be ready before DocumentUseCases.init() below, which
      // schedules/reconciles every active document's expiry reminders as
      // soon as it hydrates.
      await sl<ExpiryNotificationService>().init();
      // Initialize infrastructure, then hydrate repositories through domain use cases.
      await sl<AppDatabase>().init();
      await sl<CategoryUseCases>().init();
      await sl<DocumentUseCases>().init();
      await sl<ThemeController>().loadTheme();
      await sl<LocaleController>().loadLocale();
      await sl<SecurityController>().loadSecurity();
      await sl<NetworkPreferenceController>().loadNetworkPreference();
      // Fire-and-forget: runs in the background after the app is already
      // showing, covering only "permission was granted in a previous
      // session but the scan never finished" -- the real first run is
      // triggered by AutoImportConsentSheet right after the user grants
      // permission. Must never block runApp().
      unawaited(sl<AutoImportService>().maybeRunInitialScan());
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
        ChangeNotifierProvider<NetworkPreferenceController>.value(
          value: sl<NetworkPreferenceController>(),
        ),
      ],
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, themeController, localeController, _) {
          return MaterialApp.router(
            title: 'Dockitly',
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
