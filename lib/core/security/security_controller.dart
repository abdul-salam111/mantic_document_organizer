import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../local_storage/local_storage_exports.dart';

/// Controls and persists whether biometric app-lock is enabled, and
/// performs the biometric prompt itself via `local_auth`.
///
/// A `ChangeNotifier` (not GetX) to stay consistent with the rest of the
/// app's state management, mirroring ThemeController/LocaleController:
/// register it once as a DI singleton and provide that same instance at
/// the root of the widget tree via `ChangeNotifierProvider.value` — see
/// main.dart — so AppLockGate and SettingsView share one source of truth.
class SecurityController extends ChangeNotifier {
  static const String _storageKey = 'biometricLockEnabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isBiometricLockEnabled = false;
  bool get isBiometricLockEnabled => _isBiometricLockEnabled;

  /// Loads the persisted preference. Call this once before the app's
  /// first frame (e.g. in `main()` before `runApp`) so AppLockGate knows
  /// whether to lock on cold start.
  Future<void> loadSecurity() async {
    final value = await storage.readValues(_storageKey);
    _isBiometricLockEnabled = value == 'true';
    notifyListeners();
  }

  /// Whether this device actually has usable biometrics set up. Check
  /// this before letting the user turn the toggle on.
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric UI. Returns whether it succeeded — used
  /// both to gate turning the toggle on and to unlock the app from
  /// AppLockGate.
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricLockEnabled(bool enabled) async {
    // Update in-memory state and notify immediately so the UI reacts
    // without waiting on disk I/O. Persistence is best-effort: if it
    // fails, the chosen setting still applies for the rest of this
    // session (matches ThemeController/LocaleController).
    _isBiometricLockEnabled = enabled;
    notifyListeners();
    try {
      await storage.setValues(_storageKey, enabled.toString());
    } catch (_) {
      // Ignore — see comment above.
    }
  }
}
