import 'package:flutter/material.dart';

import '../local_storage/local_storage_exports.dart';

/// Controls and persists how many days before a document's expiry date
/// [ExpiryNotificationService] schedules its "expiring soon" reminder —
/// a single, app-wide preference (not per-document), picked from
/// [availableDaysOptions].
///
/// A `ChangeNotifier`, mirroring ThemeController/NetworkPreferenceController:
/// register it once as a DI singleton and provide that same instance at
/// the root of the widget tree via `ChangeNotifierProvider.value` — see
/// main.dart.
class ReminderPreferenceController extends ChangeNotifier {
  static const String _storageKey = 'expiryReminderDaysBefore';
  static const int defaultDaysBefore = 7;
  static const List<int> availableDaysOptions = [1, 3, 7, 14, 30];

  int _daysBefore = defaultDaysBefore;
  int get daysBefore => _daysBefore;

  /// Loads the persisted preference. Call this once before the app's
  /// first frame — and before [ExpiryNotificationService.init]/
  /// `DocumentUseCases.init()`, both of which read [daysBefore] while
  /// scheduling every active document's reminder (see main.dart).
  Future<void> loadReminderPreference() async {
    final value = await storage.readValues(_storageKey);
    final parsed = value == null ? null : int.tryParse(value);
    _daysBefore = availableDaysOptions.contains(parsed)
        ? parsed!
        : defaultDaysBefore;
    notifyListeners();
  }

  Future<void> setDaysBefore(int days) async {
    if (_daysBefore == days) return;
    // Update in-memory state and notify immediately so the UI reacts
    // without waiting on disk I/O. Persistence is best-effort: if it
    // fails, the chosen setting still applies for the rest of this
    // session (matches ThemeController/NetworkPreferenceController).
    _daysBefore = days;
    notifyListeners();
    try {
      await storage.setValues(_storageKey, days.toString());
    } catch (_) {
      // Ignore — see comment above.
    }
  }
}
