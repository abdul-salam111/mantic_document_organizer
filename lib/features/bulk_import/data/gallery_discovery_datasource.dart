import 'package:photo_manager/photo_manager.dart' as pm;

import '../domain/entities/discovered_asset.dart';
import '../domain/repositories/gallery_discovery_repository.dart';

/// Wraps `photo_manager` (photo library, both platforms) so no
/// platform-specific type escapes past this datasource -- domain/
/// presentation only ever see [DiscoveredAsset].
///
/// Deliberately does not also scan Android's Downloads/Documents folders.
/// Doing so would require `MANAGE_EXTERNAL_STORAGE` ("all files access"):
/// scoped storage only grants an app its own files plus *media*
/// (photos/video/audio) owned by other apps, not arbitrary documents like
/// a browser-downloaded PDF. Google Play restricts that permission to apps
/// whose core purpose is broad file management (file explorers, backup,
/// antivirus) and manually reviews/rejects apps that request it for a
/// secondary feature -- which this would be. See
/// docs/auto_import_feature_draft.md for the full history.
class GalleryDiscoveryDataSource implements GalleryDiscoveryRepository {
  static const minDimension = 256;
  static const defaultScanWindow = Duration(days: 365);
  static const _pageSize = 80;

  @override
  Future<DiscoveryPermission> requestPermission() async {
    final state = await pm.PhotoManager.requestPermissionExtend();
    switch (state) {
      case pm.PermissionState.authorized:
        return DiscoveryPermission.granted;
      case pm.PermissionState.limited:
        return DiscoveryPermission.limited;
      case pm.PermissionState.denied:
      case pm.PermissionState.restricted:
      case pm.PermissionState.notDetermined:
        return DiscoveryPermission.denied;
    }
  }

  @override
  Future<bool> hasPermission() async {
    final state = await pm.PhotoManager.getPermissionState(
      requestOption: const pm.PermissionRequestOption(),
    );
    return state == pm.PermissionState.authorized ||
        state == pm.PermissionState.limited;
  }

  @override
  Future<void> openSettings() => pm.PhotoManager.openSetting();

  @override
  Future<List<DiscoveredAsset>> findCandidates({
    required DateTime? since,
    required int maxExamined,
  }) async {
    final paths = await pm.PhotoManager.getAssetPathList(
      type: pm.RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return const [];
    final album = paths.first;
    final cutoff = since ?? DateTime.now().subtract(defaultScanWindow);
    final found = <DiscoveredAsset>[];
    var examined = 0;
    var page = 0;
    while (examined < maxExamined) {
      final remaining = maxExamined - examined;
      final batch = await album.getAssetListPaged(
        page: page,
        size: remaining < _pageSize ? remaining : _pageSize,
      );
      if (batch.isEmpty) break;
      for (final asset in batch) {
        examined++;
        // Videos are already excluded by requesting `RequestType.image`
        // above; this is a defensive re-check, not the primary filter.
        if (asset.type != pm.AssetType.image) continue;
        if (asset.isLivePhoto) continue; // Animated (iOS Live Photo).
        if (asset.width < minDimension || asset.height < minDimension) {
          continue; // Icons/stickers/thumbnails, not photographed documents.
        }
        // modifiedDateTime (not createDateTime/EXIF "date taken") on
        // purpose: a photo copied/restored/AirDropped in from elsewhere
        // keeps its original, possibly old, capture date, which would
        // otherwise make it look already-seen to the watermark filter below
        // even though it's brand new to this device. modifiedDateTime
        // reflects when it actually landed here.
        final takenAt = asset.modifiedDateTime;
        if (!takenAt.isAfter(cutoff)) continue;
        found.add(
          DiscoveredAsset(
            id: asset.id,
            takenAt: takenAt,
            resolvePath: () async => (await asset.file)?.path,
          ),
        );
      }
      page++;
    }
    return found;
  }
}
