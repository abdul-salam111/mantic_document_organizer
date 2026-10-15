import 'dart:async';

import 'package:flutter/material.dart';

import '../di/di_exports.dart';
import '../../features/bulk_import/presentation/viewmodel/bulk_import_viewmodel.dart';
import '../../routes/routes_exports.dart';
import 'share_intent_service.dart';

/// Wraps the whole app (via `MaterialApp.router`'s `builder`, alongside
/// AppLockGate) and routes any file "shared into Docketly" from another app
/// (see [ShareIntentService]) into Add Document -- or, when more than one
/// file arrived at once, into Bulk Import's review screen instead, so a
/// batch of unrelated photos gets grouped/categorized per document rather
/// than dumped onto a single one.
///
/// The cold-start share is deliberately not consumed until the router has
/// actually navigated away from Splash, rather than on this widget's own
/// first frame (which mounts while still showing Splash): Splash's own
/// delayed redirect (see SplashViewModel) uses `goNamed`, which replaces
/// the entire nav stack unconditionally once its delay elapses, so a push
/// fired any earlier would just get wiped out from under the user a moment
/// later. Actively checking the resolved path (rather than assuming the
/// router's first change notification IS that redirect) is what makes this
/// safe regardless of how many notifications fire before/around it.
class ShareIntentListener extends StatefulWidget {
  final Widget child;

  const ShareIntentListener({super.key, required this.child});

  @override
  State<ShareIntentListener> createState() => _ShareIntentListenerState();
}

class _ShareIntentListenerState extends State<ShareIntentListener> {
  late final StreamSubscription<List<String>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = sl<ShareIntentService>().sharedFilePaths.listen(
      _openAddDocument,
    );

    void checkPastSplash() {
      final path =
          AppRoutes.router.routerDelegate.currentConfiguration.uri.path;
      if (path == RoutePaths.splash) return;
      AppRoutes.router.routerDelegate.removeListener(checkPastSplash);
      sl<ShareIntentService>().consumeInitialShare().then(_openAddDocument);
    }

    AppRoutes.router.routerDelegate.addListener(checkPastSplash);
    checkPastSplash();
  }

  void _openAddDocument(List<String> paths) {
    if (paths.isEmpty) return;
    if (paths.length <= 1) {
      AppNavigator.pushNamed(RouteNames.addDocument, extra: paths);
      return;
    }
    unawaited(_openBulkImportReview(paths));
  }

  Future<void> _openBulkImportReview(List<String> paths) async {
    final vm = sl<BulkImportViewModel>();
    final found = await vm.seedFromSharedFiles(paths);
    if (!mounted) {
      vm.dispose();
      return;
    }
    if (!found) {
      vm.dispose();
      return;
    }
    AppNavigator.pushNamed(RouteNames.bulkImportReview, extra: vm);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
