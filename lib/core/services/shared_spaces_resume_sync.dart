import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/categories/domain/usecases/category_usecases.dart';
import '../background/document_sync_background_service.dart';
import 'session_manager.dart';

/// Syncs every shared category's space when the app returns to the
/// foreground -- the other sync triggers (right after joining, right
/// after a local mutation, the Share screen's own "Sync now") cover the
/// device that made a change; this is what lets the OTHER members'
/// devices pick that change up without them having to open the Share
/// screen and tap anything, just by reopening the app. See
/// docs/space_sharing_ux_plan.txt's sync triggers.
class SharedSpacesResumeSync {
  final CategoryUseCases _categoryUseCases;
  final DocumentSyncBackgroundService _syncBackgroundService;
  AppLifecycleListener? _listener;

  SharedSpacesResumeSync({
    required CategoryUseCases categoryUseCases,
    required DocumentSyncBackgroundService syncBackgroundService,
  }) : _categoryUseCases = categoryUseCases,
       _syncBackgroundService = syncBackgroundService;

  void init() {
    _listener = AppLifecycleListener(onResume: _syncAllSharedSpaces);
  }

  void dispose() => _listener?.dispose();

  void _syncAllSharedSpaces() => unawaited(_run());

  Future<void> _run() async {
    final token = SessionController.instance.userToken;
    if (token == null) return;
    final spaceIds = {
      for (final category in _categoryUseCases.categories)
        if (category.spaceId != null) category.spaceId!,
    };
    // Sequential, not parallel: DocumentSyncBackgroundService only tracks
    // one in-flight run at a time, so firing these together would just
    // have every call after the first see it already running and skip.
    for (final spaceId in spaceIds) {
      await _syncBackgroundService.runSpaceSync(
        token: token,
        spaceId: spaceId,
        isPersonalSpace: false,
      );
    }
  }
}
