import '../../../core/local_storage/local_storage_exports.dart';
import '../domain/repositories/discovery_watermark_repository.dart';

/// Persists the newest discovered-asset timestamp so a repeat scan
/// (Profile -> Find more documents) only examines what's new since last time.
class DiscoveryWatermarkStore implements DiscoveryWatermarkRepository {
  @override
  Future<DateTime?> read() async {
    final raw = await storage.readValues(
      StorageKeys.bulkImportDiscoveryWatermark,
    );
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> write(DateTime value) => storage.setValues(
    StorageKeys.bulkImportDiscoveryWatermark,
    value.toIso8601String(),
  );
}
