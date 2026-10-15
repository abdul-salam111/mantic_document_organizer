import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_plugin.dart';

/// Progress + result notification for `BulkImportCommitService` -- the
/// in-app background save that runs once the user taps "Import" on
/// BulkImportReviewView. Separate channel/id from [AutoImportNotifications]
/// (that one covers *finding* candidates; this one covers *saving* the
/// ones the user already confirmed), sharing the one [AppNotificationPlugin]
/// instance the same way.
class BulkImportCommitNotifications {
  BulkImportCommitNotifications(this._notificationPlugin) {
    _tapSubscription = _notificationPlugin.onTap.listen(_handleTap);
  }

  final AppNotificationPlugin _notificationPlugin;
  late final StreamSubscription<NotificationResponse> _tapSubscription;

  static const String _channelId = 'bulk_import_commit_progress';
  static const String _channelName = 'Document Import';
  static const String _channelDescription =
      'Progress while Dockitly saves the documents you confirmed';
  static const int _notificationId = 0x7fffffd0;
  static const String _reviewPayload = 'bulk_import_commit_review';

  /// Set by BulkImportCommitService; called when the result notification is
  /// tapped (only shown when something still needs attention) while the app
  /// process is already alive.
  void Function()? onReviewTapped;

  Future<void> showImporting({required int completed, required int total}) {
    final bounded = total <= 0 ? 1 : total;
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: 'Importing documents…',
      body: '$completed of $total saved',
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
          progress: completed.clamp(0, bounded),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> showResult({required int imported, required int failedCount}) {
    final title = imported == 1
        ? '1 document imported'
        : '$imported documents imported';
    final body = failedCount == 0
        ? 'Added to your library'
        : failedCount == 1
        ? '1 document needs attention — tap to review'
        : '$failedCount documents need attention — tap to review';
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: title,
      body: body,
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
      payload: failedCount > 0 ? _reviewPayload : null,
    );
  }

  void _handleTap(NotificationResponse response) {
    if (response.payload == _reviewPayload) onReviewTapped?.call();
  }

  void dispose() => _tapSubscription.cancel();
}
