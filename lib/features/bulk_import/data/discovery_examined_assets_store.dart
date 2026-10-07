import '../../../core/database/app_database.dart';
import '../domain/repositories/discovery_examined_assets_repository.dart';

/// Backs [DiscoveryExaminedAssetsRepository] with [AppDatabase]'s
/// `discovery_examined_assets` table -- sqflite, not
/// `flutter_secure_storage` (which [DiscoveryWatermarkStore] uses), since
/// this grows into a real, if capped, set of rows rather than a single
/// small value. [source] scopes every call to one discovery source, the
/// same way [DiscoveryWatermarkStore.storageKey] does for the watermark.
class DiscoveryExaminedAssetsStore implements DiscoveryExaminedAssetsRepository {
  DiscoveryExaminedAssetsStore({
    required AppDatabase database,
    required String source,
  }) : _database = database,
       _source = source;

  static const String gallerySource = 'gallery';
  static const String fileSystemSource = 'filesystem';

  final AppDatabase _database;
  final String _source;

  @override
  Future<List<String>> filterUnexamined(List<String> assetIds) =>
      _database.filterUnexaminedDiscoveryAssets(_source, assetIds);

  @override
  Future<void> markExamined(List<String> assetIds) =>
      _database.markDiscoveryAssetsExamined(_source, assetIds);
}
