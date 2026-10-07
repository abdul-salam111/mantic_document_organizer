import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_plugin.dart';

/// Progress + result notification for a background backup/sync run,
/// triggered from Profile -> Sync & backup's "Back up now"/"Retry" --
/// mirrors [AutoImportNotifications]'s shape, on its own channel/id, still
/// sharing the one [AppNotificationPlugin] instance (see its doc comment
/// for why).
class DocumentSyncNotifications {
  DocumentSyncNotifications(this._notificationPlugin) {
    _tapSubscription = _notificationPlugin.onTap.listen(_handleTap);
  }

  final AppNotificationPlugin _notificationPlugin;
  late final StreamSubscription<NotificationResponse> _tapSubscription;

  static const String _channelId = 'document_sync_progress';
  static const String _channelName = 'Document Backup & Sync';
  static const String _channelDescription =
      'Progress while Dockitly backs up and syncs your documents';
  static const int _notificationId = 0x7fffffd0;
  static const String _openPayload = 'document_sync_open';

  /// Set by DocumentSyncBackgroundService; called when the completed/failed
  /// notification is tapped while the app process is already alive.
  void Function()? onOpenTapped;

  Future<void> showSyncing({
    required int current,
    required int total,
    required String label,
  }) {
    final bounded = total <= 0 ? 1 : total;
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: 'Backing up your documents…',
      body: total > 0 ? '$label ($current of $total)' : label,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          ongoing: true,
          showProgress: true,
          maxProgress: bounded,
          progress: current.clamp(0, bounded),
          indeterminate: total <= 0,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> showCompleted() {
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: 'Backup complete',
      body: 'Your documents are up to date. Tap to view.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _openPayload,
    );
  }

  Future<void> showFailed(String message) {
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: 'Backup ran into a problem',
      body: message,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _openPayload,
    );
  }

  void _handleTap(NotificationResponse response) {
    if (response.payload == _openPayload) onOpenTapped?.call();
  }

  void dispose() => _tapSubscription.cancel();
}
