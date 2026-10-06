import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

/// Saves plain image files into the device's photo library via
/// `photo_manager` — the "Save to Gallery" share sheet action. Kept
/// separate from [DocumentPageRasterizer] (which only turns PDFs into
/// images): this is the one place that talks to the photo library SDK, same
/// reasoning as every other SDK-specific wrapper at this app's core/
/// boundary (c.f. GalleryDiscoveryDataSource, which reads from the same
/// library for Bulk Import).
class GallerySaverService {
  /// Throws [StateError] if the user hasn't granted photo library access —
  /// callers already funnel every action through `persistAction`, which
  /// turns any thrown error into the generic failure toast.
  Future<void> saveImages(List<String> paths) async {
    final state = await PhotoManager.requestPermissionExtend();
    final granted =
        state == PermissionState.authorized ||
        state == PermissionState.limited;
    if (!granted) {
      throw StateError('Photo library permission denied');
    }
    for (final path in paths) {
      await PhotoManager.editor.saveImageWithPath(path, title: p.basename(path));
    }
  }
}
