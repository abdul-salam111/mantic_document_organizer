import '../entities/discovered_asset.dart';
import '../repositories/gallery_discovery_repository.dart';

class GalleryDiscoveryUseCases {
  final GalleryDiscoveryRepository _repository;
  GalleryDiscoveryUseCases(this._repository);

  Future<DiscoveryPermission> requestPermission() =>
      _repository.requestPermission();

  Future<bool> hasPermission() => _repository.hasPermission();

  Future<void> openSettings() => _repository.openSettings();

  Future<List<DiscoveredAsset>> findCandidates({
    required DateTime? since,
    required int maxExamined,
  }) => _repository.findCandidates(since: since, maxExamined: maxExamined);
}
