import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../local_storage/local_storage_exports.dart';
import 'notification_plugin.dart';

/// A single gentle nudge about documents that haven't reached the user's
/// connected backup yet -- scheduled for tomorrow morning rather than right
/// after saving (nobody wants a notification seconds after adding a
/// document), and collapsed into one slot no matter how many documents are
/// added in a row: rescheduling the same fixed id is the debounce, the same
/// trick ExpiryNotificationService's weekly digest uses for its own single
/// notification.
///
/// A no-op whenever backup was never connected on this device -- "pending
/// sync" is otherwise this app's permanent, universal local-only state (see
/// [AppDatabase.pendingDocumentIds]), and reminding about it would mean
/// nagging every local-only user who never opted into backup at all.
class SyncReminderService {
  SyncReminderService(this._notificationPlugin, this._database) {
    _tapSubscription = _notificationPlugin.onTap.listen(_handleTap);
  }

  final AppNotificationPlugin _notificationPlugin;
  final AppDatabase _database;
  FlutterLocalNotificationsPlugin get _plugin => _notificationPlugin.plugin;
  late final StreamSubscription<NotificationResponse> _tapSubscription;

  static const int _reminderHour = 9;
  static const String _channelId = 'document_sync_reminder';
  static const String _channelName = 'Backup Reminders';
  static const String _channelDescription =
      "A gentle reminder about documents waiting to back up";
  static const int _notificationId = 0x7fffffc0;
  static const String _openPayload = 'sync_reminder_open';

  /// Set by DocumentSyncBackgroundService; called when this notification is
  /// tapped while the app process is already alive.
  void Function()? onOpenTapped;

  /// Reconciles the one reminder slot against the device's current
  /// pending-sync state -- cancels it when nothing's pending (including
  /// when backup was never connected), or (re)schedules it for tomorrow
  /// morning otherwise. The document repository calls this after every
  /// add/update/restore and after every sync run completes, so it's always
  /// catching up to the latest state rather than tracked as its own flag.
  Future<void> refresh() async {
    final hasPending = _database.pendingDocumentIds.value.isNotEmpty;
    if (!hasPending || !await _backupConnected()) {
      await _plugin.cancel(id: _notificationId);
      return;
    }

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final when = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      _reminderHour,
    );
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'A document is waiting to back up',
      body: "You've added documents that haven't synced to your backup yet.",
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Being off by a few minutes doesn't matter for an overnight nudge --
      // avoids needing the exact-alarm permission entirely.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _openPayload,
    );
  }

  Future<bool> _backupConnected() async {
    final spaceId = await storage.readValues(StorageKeys.backupSpaceId);
    return spaceId != null && spaceId.isNotEmpty;
  }

  void _handleTap(NotificationResponse response) {
    if (response.payload == _openPayload) onOpenTapped?.call();
  }

  void dispose() => _tapSubscription.cancel();
}
