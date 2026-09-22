import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/di_exports.dart';
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
    return ChangeNotifierProvider<ThemeController>.value(
      value: sl<ThemeController>(),
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp.router(
            title: 'Provider and Clean MVVM Structure',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeController.themeMode,
            routerConfig: AppRoutes.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
