import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../local_storage/local_storage_exports.dart';

/// Controls and persists whether syncing/uploading/downloading documents
/// is allowed over mobile data. Disabled by default, so a backup/restore
/// never burns the user's cellular data plan without them opting in —
/// when disabled, those operations only proceed on Wi-Fi/Ethernet.
///
/// A `ChangeNotifier`, mirroring ThemeController/SecurityController:
/// register it once as a DI singleton and provide that same instance at
/// the root of the widget tree via `ChangeNotifierProvider.value` — see
/// main.dart.
class NetworkPreferenceController extends ChangeNotifier {
  static const String _storageKey = 'syncOverMobileDataEnabled';

  final Connectivity _connectivity;

  NetworkPreferenceController({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  bool _isMobileDataSyncEnabled = false;
  bool get isMobileDataSyncEnabled => _isMobileDataSyncEnabled;

  /// Loads the persisted preference. Call this once before the app's
  /// first frame (e.g. in `main()` before `runApp`).
  Future<void> loadNetworkPreference() async {
    final value = await storage.readValues(_storageKey);
    _isMobileDataSyncEnabled = value == 'true';
    notifyListeners();
  }

  Future<void> setMobileDataSyncEnabled(bool enabled) async {
    // Update in-memory state and notify immediately so the UI reacts
    // without waiting on disk I/O. Persistence is best-effort: if it
    // fails, the chosen setting still applies for the rest of this
    // session (matches ThemeController/SecurityController).
    _isMobileDataSyncEnabled = enabled;
    notifyListeners();
    try {
      await storage.setValues(_storageKey, enabled.toString());
    } catch (_) {
      // Ignore — see comment above.
    }
  }

  /// Whether a sync/upload/download may proceed on the current
  /// connection, given this preference. True whenever mobile data sync is
  /// enabled, or the device is currently on Wi-Fi/Ethernet.
  Future<bool> canSyncOnCurrentConnection() async {
    if (_isMobileDataSyncEnabled) return true;
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }
}
