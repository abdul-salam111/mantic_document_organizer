import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../local_storage/local_storage_exports.dart';
import 'notification_plugin.dart';

/// A gentle, recurring nudge about documents that haven't reached the
/// user's connected backup yet -- collapsed into one slot no matter how
/// many documents are added in a row: rescheduling the same fixed id is
/// the debounce, the same trick ExpiryNotificationService's weekly digest
/// uses for its own single notification.
///
/// [refresh] is called from every document add/update/restore and after
/// every sync run completes (including at app startup, since a completed
/// sync reaches here too -- see DocumentRepositoryImpl.init), so it would
/// run very often while the app is in regular use. It only ever touches
/// the notification's scheduled time when nothing is currently pending in
/// the OS's own notification queue for [_notificationId] -- otherwise a
/// still-pending reminder's fire time would get pushed back to
/// "[_reminderIntervalDays] days from now" on every single call, which in
/// practice meant it could never fire for anyone who kept opening the app:
/// each open re-armed it further into the future before it ever got the
/// chance to go off. Checking first means a reminder that's already
/// waiting is left alone, and a new one is only armed once the previous
/// one has actually fired (or none was ever scheduled) -- giving a real
/// "every couple of days while still unsynced" cadence instead of a
/// one-shot that silently stops repeating.
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

  /// How long a fired reminder stays quiet before it's allowed to be
  /// re-armed -- gentle enough not to nag, frequent enough that an
  /// unsynced document doesn't go unmentioned for weeks.
  static const int _reminderIntervalDays = 2;

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
  /// when backup was never connected); otherwise arms it for
  /// [_reminderIntervalDays] from now, but only if nothing's already
  /// waiting in that slot (see class doc for why that check matters). The
  /// document repository calls this after every add/update/restore and
  /// after every sync run completes, so it's always catching up to the
  /// latest state rather than tracked as its own flag.
  Future<void> refresh() async {
    final hasPending = _database.pendingDocumentIds.value.isNotEmpty;
    if (!hasPending || !await _backupConnected()) {
      await _plugin.cancel(id: _notificationId);
      return;
    }

    final alreadyArmed = await _plugin.pendingNotificationRequests();
    if (alreadyArmed.any((request) => request.id == _notificationId)) {
      return;
    }

    final next = DateTime.now().add(
      const Duration(days: _reminderIntervalDays),
    );
    final when = DateTime(next.year, next.month, next.day, _reminderHour);
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
