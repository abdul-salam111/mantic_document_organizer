import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_plugin.dart';

/// Progress + result notification for AutoImportService's one-time,
/// in-app background scan — a separate channel/id from
/// [ExpiryNotificationService]'s `document_expiry` channel, sharing the one
/// [AppNotificationPlugin] instance (see its doc comment for why).
class AutoImportNotifications {
  AutoImportNotifications(this._notificationPlugin) {
    _tapSubscription = _notificationPlugin.onTap.listen(_handleTap);
  }

  final AppNotificationPlugin _notificationPlugin;
  late final StreamSubscription<NotificationResponse> _tapSubscription;

  static const String _channelId = 'auto_import_progress';
  static const String _channelName = 'Document Auto-Import';
  static const String _channelDescription =
      'Progress while Dockitly automatically looks for documents';
  static const int _notificationId = 0x7fffffe0;
  static const String _reviewPayload = 'auto_import_review';

  /// Set by AutoImportService; called when the "N documents found" (tap to
  /// review) notification is tapped while the app process is already alive.
  void Function()? onReviewTapped;

  Future<void> showScanning({
    required int examined,
    required int totalEstimate,
  }) {
    final bounded = totalEstimate <= 0 ? 1 : totalEstimate;
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: 'Looking for documents…',
      body: 'Checked $examined so far',
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
          progress: examined.clamp(0, bounded),
          indeterminate: totalEstimate <= 0,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> showFound(int count) {
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: count == 1 ? '1 document found' : '$count documents found',
      body: 'Tap to review and add them to your library',
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
      payload: _reviewPayload,
    );
  }

  Future<void> dismissQuiet() =>
      _notificationPlugin.plugin.cancel(id: _notificationId);

  // Unlike ExpiryNotificationService's digest tap, a cold-start tap on this
  // notification has nothing to resume -- the found candidates only ever
  // live in that scan's in-memory BulkImportViewModel, which a terminated
  // process has already lost. So, unlike that service, there's no
  // `consumeInitialLaunchTap`-equivalent here; [onTap] (while the process
  // stays alive) is the only path that can do anything useful.
  void _handleTap(NotificationResponse response) {
    if (response.payload == _reviewPayload) onReviewTapped?.call();
  }

  void dispose() => _tapSubscription.cancel();
}
