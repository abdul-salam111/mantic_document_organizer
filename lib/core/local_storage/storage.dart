import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  // Make the class a singleton
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;

  LocalStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> setValues(String key, String value) async {
    await _storage.write(key: key, value: value);
    return true;
  }

  readValues(String key) {
    return _storage.read(key: key);
  }

  Future<bool> clearValues(String key) async {
    await _storage.delete(key: key);
    return true;
  }
}

// Global getter
final LocalStorage storage = LocalStorage();

/// Generic, project-agnostic storage keys. Add project-specific keys here
/// as needed — don't leave previous-project business keys (e.g. sector/town/
/// salesman fields) in the base template; see TEMPLATE_REVIEW.md §1.4.
class StorageKeys {
  static const String loggedIn = 'loggedIn';
  static const String token = "token";
  static const String refreshToken = 'refreshToken';
  static const String userId = 'userId';
  static const String userDetails = 'userDetails';
  static const String hasSeenOnboarding = 'hasSeenOnboarding';
  static const String hasSeenBulkImportPrompt = 'hasSeenBulkImportPrompt';
  static const String bulkImportDiscoveryWatermark =
      'bulkImportDiscoveryWatermark';
  static const String autoImportFileSystemWatermark =
      'autoImportFileSystemWatermark';
  static const String hasRunInitialAutoImport = 'hasRunInitialAutoImport';
  static const String pendingBackupSetup = 'pendingBackupSetup';
  static const String backupSpaceId = 'backupSpaceId';
  static const String backupEnabled = 'backupEnabled';
  // A deep-linked invitation/join-link token caught while signed out (see
  // DeepLinkService) -- redeemed right after the next successful sign-in.
  static const String pendingSpaceJoinToken = 'pendingSpaceJoinToken';
  static const String pendingSpaceJoinKind = 'pendingSpaceJoinKind';
  // Prefix for a per-space key (`'$joinLinkTokenPrefix$spaceId'`) caching
  // that space's reusable join-link raw token -- the backend only ever
  // returns it once, right when the link is created (see
  // ShareCategoryViewModel._ensureJoinLink).
  static const String joinLinkTokenPrefix = 'joinLinkToken:';
}

extension LocalStorageGetters on LocalStorage {
  Future<String?> get userId async {
    return await readValues(StorageKeys.userId);
  }

  Future<String?> get userToken async {
    return await readValues(StorageKeys.token);
  }

  Future<bool> get hasSeenOnboarding async {
    return (await readValues(StorageKeys.hasSeenOnboarding)) == 'true';
  }
}
