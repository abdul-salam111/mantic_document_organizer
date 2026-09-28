import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/home/viewmodel/home_viewmodel.dart' show DocumentItem;
import '../localization/localization_exports.dart';

/// Local (on-device, no backend) reminders for a document's expiry date —
/// schedules up to two notifications per document, [daysBefore] days before
/// [DocumentItem.expiryDate] and on the day itself, both at [_reminderHour]
/// local time. [DocumentLocalStore] is the single call site for every
/// document mutation (add/update/trash/restore/delete), so it owns calling
/// [scheduleForDocument]/[cancelForDocument] here — nothing else in the app
/// needs to know this exists.
class ExpiryNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _reminderHour = 9;
  static const int daysBefore = 7;
  static const String _channelId = 'document_expiry';
  static const String _channelName = 'Document Expiry Reminders';

  /// How far ahead [scheduleWeeklyDigest] looks when counting documents as
  /// "expiring soon" — matches the roadmap's "expire this month" framing.
  static const int digestWindowDays = 30;
  static const int _digestWeekday = DateTime.monday;
  static const String _digestPayload = 'expiring_soon_digest';

  /// Fixed, arbitrary ID reserved for the one digest notification — distinct
  /// from [_reminderNotificationId]/[_expiryNotificationId]'s per-document
  /// hash-derived IDs (a collision between the two schemes is astronomically
  /// unlikely, the same tolerance the per-document IDs already accept).
  static const int _digestNotificationId = 0x7ffffff0;

  String _expiringSoonTitle = 'Document expiring soon';
  String _expiresTodayTitle = 'Document expires today';
  String Function(String title) _expiringSoonBody = (title) =>
      '"$title" expires in $daysBefore days';
  String Function(String title) _expiresTodayBody = (title) =>
      '"$title" expires today';
  String _expiringSoonDigestTitle = 'Documents expiring soon';
  String Function(int count) _expiringSoonDigestBody = (count) => count == 1
      ? '1 document expires this month'
      : '$count documents expire this month';

  final StreamController<void> _digestTapped =
      StreamController<void>.broadcast();

  /// Fires whenever the weekly digest notification is tapped while the app
  /// process is already alive (foreground or backgrounded) — see
  /// [consumeInitialDigestTap] for the cold-start/terminated case, which
  /// this can't cover since nothing is listening yet at that point.
  Stream<void> get onDigestTapped => _digestTapped.stream;

  /// Called once, from the app's root widget (see MyApp.build's
  /// MaterialApp.builder — it re-runs on every locale change), so newly
  /// scheduled reminders use the app's current language. A reminder already
  /// scheduled before a locale change keeps the language it was scheduled
  /// in — the same limitation any OS-level pre-scheduled notification has.
  void updateLocalizedStrings(AppLocalizations l10n) {
    _expiringSoonTitle = l10n.documentExpiringSoonTitle;
    _expiresTodayTitle = l10n.documentExpiresTodayTitle;
    _expiringSoonBody = (title) =>
        l10n.documentExpiringSoonBody(title, daysBefore);
    _expiresTodayBody = (title) => l10n.documentExpiresTodayBody(title);
    _expiringSoonDigestTitle = l10n.expiringSoonDigestTitle;
    _expiringSoonDigestBody = (count) => l10n.expiringSoonDigestBody(count);
  }

  /// Initializes the plugin and the local timezone database, and requests
  /// notification permission — called once at startup (see main.dart),
  /// before any [scheduleForDocument] call.
  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Unrecognized/unavailable timezone name — reminders still fire, just
      // anchored to UTC instead of the device's actual local time.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Cancels then (re)schedules [document]'s reminders — safe to call on
  /// every add/update/restore, since a document that's no longer expirable,
  /// or whose reminder time has already passed, simply ends up with nothing
  /// scheduled for it.
  Future<void> scheduleForDocument(DocumentItem document) async {
    await cancelForDocument(document.id);
    final expiryDate = document.expiryDate;
    if (!document.isExpirable || expiryDate == null) return;

    final now = DateTime.now();
    final expiryDay = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    final reminderDay = expiryDay.subtract(const Duration(days: daysBefore));

    if (reminderDay.isAfter(now)) {
      await _schedule(
        id: _reminderNotificationId(document.id),
        title: _expiringSoonTitle,
        body: _expiringSoonBody(document.title),
        day: reminderDay,
      );
    }
    if (expiryDay.isAfter(now)) {
      await _schedule(
        id: _expiryNotificationId(document.id),
        title: _expiresTodayTitle,
        body: _expiresTodayBody(document.title),
        day: expiryDay,
      );
    }
  }

  /// Cancels both of [documentId]'s reminders, if any are scheduled —
  /// called before every reschedule, and whenever a document leaves active
  /// use (trashed/deleted) so it stops reminding about something the user
  /// can no longer act on.
  Future<void> cancelForDocument(String documentId) async {
    await _plugin.cancel(id: _reminderNotificationId(documentId));
    await _plugin.cancel(id: _expiryNotificationId(documentId));
  }

  /// Recomputes and (re)schedules the single weekly "N documents expire
  /// this month" summary notification — cancelled entirely when nothing in
  /// [activeDocuments] qualifies. [DocumentLocalStore] calls this alongside
  /// [scheduleForDocument]/[cancelForDocument] on every document mutation
  /// and at app startup, so its content is refreshed constantly; between
  /// those points it's a real OS-level weekly repeat
  /// ([DateTimeComponents.dayOfWeekAndTime]), so — like every other
  /// reminder in this class — its content can go stale if the app isn't
  /// opened for a while, the same tradeoff [_schedule]'s single-shot
  /// reminders already accept.
  Future<void> scheduleWeeklyDigest(List<DocumentItem> activeDocuments) async {
    final now = DateTime.now();
    final windowEnd = now.add(const Duration(days: digestWindowDays));
    final count = activeDocuments.where((d) {
      final expiry = d.expiryDate;
      return d.isExpirable &&
          expiry != null &&
          expiry.isAfter(now) &&
          expiry.isBefore(windowEnd);
    }).length;

    await _plugin.cancel(id: _digestNotificationId);
    if (count == 0) return;

    await _plugin.zonedSchedule(
      id: _digestNotificationId,
      title: _expiringSoonDigestTitle,
      body: _expiringSoonDigestBody(count),
      scheduledDate: _nextDigestSlot(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:
              "Reminds you before a saved document's expiry date",
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: _digestPayload,
    );
  }

  /// Next occurrence of [_digestWeekday] at [_reminderHour] local time,
  /// strictly in the future.
  tz.TZDateTime _nextDigestSlot() {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _reminderHour,
    );
    while (next.weekday != _digestWeekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == _digestPayload) _digestTapped.add(null);
  }

  /// Checked once at startup (see main.dart) for the case where tapping the
  /// digest notification is what launched the app from fully terminated —
  /// [onDigestTapped] only covers taps while the process is already alive,
  /// since nothing is listening to it yet at cold start.
  Future<bool> consumeInitialDigestTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true &&
        details?.notificationResponse?.payload == _digestPayload;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime day,
  }) {
    final scheduledDate = tz.TZDateTime.from(
      DateTime(day.year, day.month, day.day, _reminderHour),
      tz.local,
    );
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:
              "Reminds you before a saved document's expiry date",
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Being off by a few minutes doesn't matter for a "expires in 7 days"
      // reminder — avoids needing the exact-alarm permission entirely.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  int _reminderNotificationId(String documentId) =>
      documentId.hashCode & 0x7ffffffe;

  int _expiryNotificationId(String documentId) =>
      (documentId.hashCode & 0x7ffffffe) + 1;
}
