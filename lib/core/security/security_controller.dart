import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:local_auth/local_auth.dart';

import '../local_storage/local_storage_exports.dart';

/// What to actually call the biometric method in the UI. iOS/macOS report
/// the exact hardware and those are Apple's own trademarked names (Face
/// ID / Touch ID); other platforms mostly report a strength class rather
/// than a specific modality, so [fingerprint] — overwhelmingly the common
/// case on Android — is used there, falling back to [generic] when
/// detection is inconclusive.
enum BiometricKind { faceId, touchId, fingerprint, generic }

/// Icon to represent [kind] — centralized so Settings, the
/// resume-from-background lock screen, and the splash retry prompt all
/// stay visually consistent.
IconData biometricIconFor(BiometricKind kind) => switch (kind) {
  BiometricKind.faceId => Icons.face,
  BiometricKind.touchId ||
  BiometricKind.fingerprint ||
  BiometricKind.generic => Iconsax.finger_scan,
};

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

  BiometricKind? _cachedBiometricKind;

  /// Which biometric method this device actually has, for picking the
  /// right label/icon in the UI (e.g. "Face ID" rather than a generic
  /// "Fingerprint" on an iPhone that has no Touch ID hardware at all).
  /// Memoized — the device's hardware doesn't change mid-session.
  Future<BiometricKind> primaryBiometricKind() async {
    if (_cachedBiometricKind != null) return _cachedBiometricKind!;

    List<BiometricType> available;
    try {
      available = await _localAuth.getAvailableBiometrics();
    } catch (_) {
      available = const [];
    }

    // defaultTargetPlatform (not dart:io's Platform) — safe to evaluate
    // on every platform including web.
    final isApplePlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final BiometricKind kind;
    if (isApplePlatform) {
      if (available.contains(BiometricType.face)) {
        kind = BiometricKind.faceId;
      } else if (available.contains(BiometricType.fingerprint)) {
        kind = BiometricKind.touchId;
      } else {
        kind = BiometricKind.generic;
      }
    } else if (available.contains(BiometricType.fingerprint)) {
      kind = BiometricKind.fingerprint;
    } else {
      kind = BiometricKind.generic;
    }

    _cachedBiometricKind = kind;
    return kind;
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
