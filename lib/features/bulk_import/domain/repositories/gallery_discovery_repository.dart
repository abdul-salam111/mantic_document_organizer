import '../entities/discovered_asset.dart';

enum DiscoveryPermission { granted, limited, denied }

abstract interface class GalleryDiscoveryRepository {
  Future<DiscoveryPermission> requestPermission();

  /// Passive check -- never shows a system prompt, unlike
  /// [requestPermission]. Used by AutoImportService to decide whether its
  /// automatic scan can run without first surprising the user with a
  /// permission dialog they haven't consented to yet.
  Future<bool> hasPermission();

  /// Opens the OS settings screen for this app's photo library permission.
  Future<void> openSettings();

  /// Metadata-only enumeration, cheap-filtered (type/size) and date-filtered
  /// to assets newer than [since] (or the default scan window when null).
  /// Examines at most [maxExamined] assets regardless of how many pass the
  /// filters, so a single call has a bounded, predictable cost.
  Future<List<DiscoveredAsset>> findCandidates({
    required DateTime? since,
    required int maxExamined,
  });
}
