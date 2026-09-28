import 'dart:async';

import 'package:flutter/material.dart';

import '../di/di_exports.dart';
import '../../routes/routes_exports.dart';
import 'expiry_notification_service.dart';

/// Wraps the whole app (via MaterialApp.router's builder, alongside
/// ShareIntentListener/AppLockGate) and routes a tap on the weekly
/// "N documents expire this month" digest notification (see
/// [ExpiryNotificationService.scheduleWeeklyDigest]) straight to the
/// Expiring Soon list.
///
/// Same cold-start-vs-Splash-redirect race avoidance as ShareIntentListener
/// (core/sharing) — see that class's doc comment for the full reasoning;
/// the short version is that Splash's delayed `goNamed` unconditionally
/// replaces the nav stack, so a push fired before it resolves would just
/// get wiped out from under the user a moment later.
class ExpiryDigestListener extends StatefulWidget {
  final Widget child;

  const ExpiryDigestListener({super.key, required this.child});

  @override
  State<ExpiryDigestListener> createState() => _ExpiryDigestListenerState();
}

class _ExpiryDigestListenerState extends State<ExpiryDigestListener> {
  late final StreamSubscription<void> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = sl<ExpiryNotificationService>().onDigestTapped.listen(
      (_) => _openExpiringSoon(),
    );

    void checkPastSplash() {
      final path =
          AppRoutes.router.routerDelegate.currentConfiguration.uri.path;
      if (path == RoutePaths.splash) return;
      AppRoutes.router.routerDelegate.removeListener(checkPastSplash);
      sl<ExpiryNotificationService>().consumeInitialDigestTap().then((
        launchedByDigest,
      ) {
        if (launchedByDigest) _openExpiringSoon();
      });
    }

    AppRoutes.router.routerDelegate.addListener(checkPastSplash);
    checkPastSplash();
  }

  void _openExpiringSoon() => AppNavigator.pushNamed(RouteNames.expiringSoon);

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
