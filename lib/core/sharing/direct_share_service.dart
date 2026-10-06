import 'dart:io';

import 'package:flutter/services.dart';

/// Launches one specific installed app directly with files attached — e.g.
/// tapping a "WhatsApp" icon should open WhatsApp's own share/attach screen,
/// not a generic OS chooser. Android only: there's no equivalent OS-level
/// API on iOS (UIActivityViewController never lets a caller pick a specific
/// target), so [shareToApp] always reports failure there, and every other
/// failure mode (app not installed, nothing resolved, any exception) also
/// just reports false rather than throwing — callers are expected to fall
/// back to the normal OS share sheet (see
/// DocumentProcessingRepositoryImpl.shareDirect) rather than branch on why
/// the direct attempt didn't work.
class DirectShareService {
  static const _channel = MethodChannel('mantic.document.organizer/share');

  Future<bool> shareToApp({
    required List<String> paths,
    required String packageName,
  }) async {
    if (!Platform.isAndroid || paths.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('shareToApp', {
            'paths': paths,
            'package': packageName,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
