import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_plugin.dart';

/// Progress notification for `BulkImportSeedService` -- the in-app
/// background OCR + AI-grouping step that runs right after the user picks
/// files from Profile's "Import documents" (camera/gallery/file). Unlike
/// [AutoImportNotifications]/[BulkImportCommitNotifications], there's no
/// "tap to review" notification here: the service opens the review screen
/// directly the moment grouping finishes, so this only ever shows the
/// ongoing "in progress" state and is dismissed once that's done. Separate
/// channel/id from those two, sharing the one [AppNotificationPlugin]
/// instance the same way.
class BulkImportSeedNotifications {
  BulkImportSeedNotifications(this._notificationPlugin);

  final AppNotificationPlugin _notificationPlugin;

  static const String _channelId = 'bulk_import_seed_progress';
  static const String _channelName = 'Document Import';
  static const String _channelDescription =
      'Progress while Dockitly organizes the files you picked';
  static const int _notificationId = 0x7fffffc0;

  Future<void> showOrganizing({required int examined, required int total}) {
    final bounded = total <= 0 ? 1 : total;
    return _notificationPlugin.plugin.show(
      id: _notificationId,
      title: 'Organizing your documents…',
      body: 'Checked $examined of $total',
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
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> dismissQuiet() =>
      _notificationPlugin.plugin.cancel(id: _notificationId);
}
