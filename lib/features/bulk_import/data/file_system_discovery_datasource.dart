import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;

import '../domain/entities/discovered_asset.dart';
import '../domain/repositories/gallery_discovery_repository.dart';
import 'bulk_import_local_datasource.dart';

/// Scans shared, non-gallery storage locations (Downloads, Documents) for
/// files Bulk Import can import — Android only. Requires
/// `MANAGE_EXTERNAL_STORAGE` ("all files access"); see
/// docs/auto_import_feature_draft.md and [GalleryDiscoveryDataSource]'s own
/// doc comment for why that permission was avoided before — re-added here
/// as a deliberate, user-confirmed choice despite the Play Store policy
/// risk documented there.
///
/// Deliberately does not walk DCIM/Pictures/Movies or this app's own
/// sandboxed directories, so it never re-examines photos
/// [GalleryDiscoveryDataSource] already covers, or files this app staged/
/// saved itself.
class FileSystemDiscoveryDataSource implements GalleryDiscoveryRepository {
  static const _roots = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Documents',
  ];
  static const _defaultScanWindow = Duration(days: 365);

  @override
  Future<DiscoveryPermission> requestPermission() async {
    final status = await ph.Permission.manageExternalStorage.request();
    return status.isGranted
        ? DiscoveryPermission.granted
        : DiscoveryPermission.denied;
  }

  @override
  Future<bool> hasPermission() async =>
      (await ph.Permission.manageExternalStorage.status).isGranted;

  @override
  Future<void> openSettings() => ph.openAppSettings();

  @override
  Future<List<DiscoveredAsset>> findCandidates({
    required DateTime? since,
    required int maxExamined,
  }) async {
    final cutoff = since ?? DateTime.now().subtract(_defaultScanWindow);
    final matches = <({String path, DateTime modified})>[];
    var examined = 0;
    for (final root in _roots) {
      if (examined >= maxExamined) break;
      final directory = Directory(root);
      if (!await directory.exists()) continue;
      try {
        await for (final entry in directory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (examined >= maxExamined) break;
          if (entry is! File) continue;
          examined++;
          final extension = entry.path.split('.').last.toLowerCase();
          if (!BulkImportLocalDataSource.supportedExtensions.contains(
            extension,
          )) {
            continue;
          }
          FileStat stat;
          try {
            stat = await entry.stat();
          } catch (_) {
            continue;
          }
          if (!stat.modified.isAfter(cutoff)) continue;
          matches.add((path: entry.path, modified: stat.modified));
        }
      } catch (_) {
        // Unreadable directory (permission edge case, removable media
        // unmounted mid-scan, etc.) -- skip it, keep scanning other roots.
      }
    }
    matches.sort((a, b) => b.modified.compareTo(a.modified));
    return [
      for (final entry in matches)
        DiscoveredAsset(
          id: entry.path,
          takenAt: entry.modified,
          resolvePath: () async => entry.path,
        ),
    ];
  }
}
