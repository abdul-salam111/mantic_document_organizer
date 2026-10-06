import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Owns the single `flutter_local_notifications` plugin instance for the
/// whole app. The plugin only supports one `initialize()` call and one
/// `onDidReceiveNotificationResponse` callback -- every notification-sending
/// service (e.g. [ExpiryNotificationService], `AutoImportNotifications`)
/// takes this as a constructor dependency instead of creating its own
/// plugin instance, and claims its own notification(s) by filtering
/// [onTap]'s payload rather than calling `initialize` itself.
class AppNotificationPlugin {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<NotificationResponse> _responses =
      StreamController<NotificationResponse>.broadcast();

  /// Every tap on any notification shown through [plugin], regardless of
  /// which service created it -- each listener filters by its own payload.
  Stream<NotificationResponse> get onTap => _responses.stream;

  bool _initialized = false;

  /// Idempotent -- safe for more than one service's own `init()` to call
  /// without double-registering the plugin or re-prompting for permission.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _responses.add,
    );
    if (Platform.isAndroid) {
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// The cold-start case -- a notification tap that launched the app from
  /// fully terminated arrives here, not through [onTap] (nothing is
  /// listening yet at that point). Each caller checks its own payload.
  Future<NotificationResponse?> consumeLaunchResponse() async {
    final details = await plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse;
  }
}
