import '../../../core/local_storage/local_storage_exports.dart';
import '../domain/repositories/discovery_watermark_repository.dart';

/// Persists the newest discovered-asset timestamp so a repeat scan
/// (Profile -> Find more documents, or AutoImportService's automatic scan)
/// only examines what's new since last time. [storageKey] defaults to the
/// gallery source's own key; the filesystem discovery source gets its own
/// instance constructed with a different key, so the two sources never
/// clobber each other's watermark.
class DiscoveryWatermarkStore implements DiscoveryWatermarkRepository {
  DiscoveryWatermarkStore({
    String storageKey = StorageKeys.bulkImportDiscoveryWatermark,
  }) : _storageKey = storageKey;

  final String _storageKey;

  @override
  Future<DateTime?> read() async {
    final raw = await storage.readValues(_storageKey);
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> write(DateTime value) =>
      storage.setValues(_storageKey, value.toIso8601String());
}
