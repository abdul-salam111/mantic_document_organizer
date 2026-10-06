import 'dart:io';
import 'package:content_resolver/content_resolver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/document_item.dart';

abstract interface class AttachmentLocalDataSource {
  Future<AttachmentSelection> pickFromCamera();
  Future<AttachmentSelection> pickFromGallery();
  Future<AttachmentSelection> pickFile();
  Future<AttachmentSelection> addSharedFiles(List<String> sourcePaths);
}

class DeviceAttachmentDataSource implements AttachmentLocalDataSource {
  /// Every attachment source (scanner, gallery, file browser) hands back a
  /// path that's only guaranteed to live in a cache/temp location the OS is
  /// free to reclaim at any time — none of them write into this app's own
  /// permanent storage on their own. [_persistAttachment] copies into
  /// `<app documents>/documents/` so a saved document's files actually
  /// survive (see ICON_TYPE_AND_ATTACHMENT_STORAGE_NOTES.txt for the full
  /// reasoning). Computed once per pick call and passed down rather than
  /// re-resolved per file.
  Future<Directory> _attachmentsDirectory() async {
    final appDocuments = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocuments.path}/documents');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _persistAttachment(
    String sourcePath,
    Directory dir,
    int index,
  ) async {
    final dotIndex = sourcePath.lastIndexOf('.');
    final extension = dotIndex == -1 ? '' : sourcePath.substring(dotIndex);
    final destinationPath =
        '${dir.path}/doc_${DateTime.now().microsecondsSinceEpoch}_$index$extension';
    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  /// Opens Google ML Kit's document scanner (VisionKit on iOS) — a
  /// fullscreen native flow with its own live edge detection, cropping,
  /// filtering and multi-page capture, so none of that needs building here.
  /// Returns true if the scan genuinely failed (not just cancelled), so the
  /// caller can surface a toast.
  @override
  Future<AttachmentSelection> pickFromCamera() async {
    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 10,
        // Package default is 0.9 (iOS only — Android's ML Kit ignores this
        // and always returns its own fixed-quality JPEG). Documents need
        // their text to stay sharp/legible, so don't give up any quality
        // here either.
        quality: 1,
        // Left at the package default (false) deliberately: true swaps in a
        // faster single-shutter-tap flow, but on Android the plugin
        // implements that by dropping GmsDocumentScannerOptions down to
        // SCANNER_MODE_BASE, which silently removes ML Kit's post-capture
        // filter/color-mode step (and its ML cleanup) along with multi-page
        // capture and in-scanner gallery import — see
        // FlutterDocScannerPlugin.kt's fastSinglePageMode branch. Leaving
        // this false keeps SCANNER_MODE_FULL (filters + multi-page) on
        // Android; on iOS it keeps VisionKit's own auto-detecting capture
        // UI instead of the plugin's manual-shutter screen.
      );
      if (result == null || result.images.isEmpty) {
        return const AttachmentSelection();
      }
      final dir = await _attachmentsDirectory();
      final newAttachments = <AttachmentItem>[];
      for (var i = 0; i < result.images.length; i++) {
        final path = await _localizeScan(result.images[i], dir, i);
        final attachment = AttachmentItem(
          path: path,
          type: AttachmentType.image,
        );

        newAttachments.add(attachment);
      }
      return AttachmentSelection(items: newAttachments);
    } on DocScanException catch (e) {
      return AttachmentSelection(
        scanFailed: e.code != DocScanException.codeCancelled,
      );
    }
  }

  /// Each scanned page comes back as either a content:// URI (ML Kit's own
  /// FileProvider-backed cache) or a file:// URI — either way, `File()`
  /// can't be handed the raw URI string directly: a content:// URI isn't a
  /// real filesystem path at all, and a file:// URI's `file://` prefix is
  /// part of the string, not something `File()` strips on its own. iOS
  /// returns a plain path with no scheme, which needs no conversion. Either
  /// way, the result is written straight into [documentsDir] — this is the
  /// one attachment source that already copied its source file, so it
  /// writes its permanent copy directly instead of copying twice.
  Future<String> _localizeScan(
    String uriOrPath,
    Directory documentsDir,
    int i,
  ) async {
    final destinationPath =
        '${documentsDir.path}/scan_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
    final uri = Uri.tryParse(uriOrPath);
    if (uri != null && uri.scheme == 'content') {
      await ContentResolver.resolveContentToFile(uriOrPath, destinationPath);
      return destinationPath;
    }
    final sourcePath = (uri != null && uri.scheme == 'file')
        ? uri.toFilePath()
        : uriOrPath;
    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  /// Multi-select — matches the reference design's gallery picker, which
  /// lets several photos be attached in one go.
  @override
  Future<AttachmentSelection> pickFromGallery() async {
    // No imageQuality cap — documents (receipts, IDs, bills) need their
    // text to stay sharp/legible, which a lossy JPEG re-encode pass
    // directly works against. Leaving it unset keeps the picked image at
    // its original quality, same as the camera scan path below.
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return const AttachmentSelection();
    final dir = await _attachmentsDirectory();
    final newAttachments = <AttachmentItem>[];
    for (var i = 0; i < picked.length; i++) {
      final path = await _persistAttachment(picked[i].path, dir, i);
      final attachment = AttachmentItem(path: path, type: AttachmentType.image);

      newAttachments.add(attachment);
    }
    return AttachmentSelection(items: newAttachments);
  }

  static const _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tif',
    'tiff',
  };

  /// Non-image extensions the system file browser is restricted to —
  /// png/jpg/etc. belong to the Camera and Gallery buttons instead, so
  /// the picker itself is scoped to these rather than just filtering
  /// afterward (that left images visibly selectable in the browser,
  /// which just got filtered back out post-pick and confused users).
  /// Not exhaustive, but covers what "a document" realistically means.
  static const _documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'rtf',
    'csv',
    'odt',
    'ods',
    'odp',
    'epub',
    'md',
    'json',
    'xml',
    'zip',
    'rar',
    '7z',
  ];

  bool _isImage(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (extension != null) return _imageExtensions.contains(extension);
    // Fallback for platforms/providers that don't populate `extension`.
    final name = file.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    return _imageExtensions.contains(name.substring(dot + 1));
  }

  /// Returns true if one or more selected files were skipped for being
  /// images — shouldn't normally happen now that the picker itself is
  /// restricted to [_documentExtensions], but some Android file manager
  /// providers ignore that restriction, so this stays as a backstop (the
  /// caller can surface it as a toast).
  @override
  Future<AttachmentSelection> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _documentExtensions,
    );
    if (result.isEmpty) return const AttachmentSelection();
    var skippedImage = false;
    final dir = await _attachmentsDirectory();
    final newAttachments = <AttachmentItem>[];
    for (var i = 0; i < result.length; i++) {
      final file = result[i];
      final path = file.path;
      if (path == null) continue;
      if (_isImage(file)) {
        skippedImage = true;
        continue;
      }
      final persistedPath = await _persistAttachment(path, dir, i);
      final attachment = AttachmentItem(
        path: persistedPath,
        type: AttachmentType.file,
      );

      newAttachments.add(attachment);
    }
    return AttachmentSelection(
      items: newAttachments,
      skippedImages: skippedImage,
    );
  }

  /// Ingests files shared into the app from another app (email, WhatsApp,
  /// Gallery, ... — see ShareIntentService) through the same persist +
  /// OCR/AI pipeline as the in-app pick methods above, just sourced
  /// externally instead of from the camera/gallery/file picker.
  @override
  Future<AttachmentSelection> addSharedFiles(List<String> sourcePaths) async {
    if (sourcePaths.isEmpty) return const AttachmentSelection();
    final dir = await _attachmentsDirectory();
    final newAttachments = <AttachmentItem>[];
    for (var i = 0; i < sourcePaths.length; i++) {
      final persistedPath = await _persistAttachment(sourcePaths[i], dir, i);
      final attachment = AttachmentItem(
        path: persistedPath,
        type: isImagePath(persistedPath)
            ? AttachmentType.image
            : AttachmentType.file,
      );

      newAttachments.add(attachment);
    }
    return AttachmentSelection(items: newAttachments);
  }
}
