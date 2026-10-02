import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/entities/bulk_import_candidate.dart';
import '../domain/repositories/bulk_import_repository.dart';
import '../../documents/domain/entities/attachment_item.dart';
import '../../documents/domain/entities/document_item.dart';

/// One instance owns one session. Never deletes source files.
class BulkImportLocalDataSource implements BulkImportRepository {
  BulkImportLocalDataSource({Future<Directory> Function()? rootDirectory})
    : _rootDirectory = rootDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _rootDirectory;
  final String _sessionId =
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
  int _sequence = 0;
  static const supportedExtensions = [
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
    'jpg',
    'jpeg',
    'heic',
    'heif',
    'webp',
    'bmp',
    'tif',
    'tiff',
    // 'png' and 'gif' intentionally excluded from Bulk Import discovery --
    // see GalleryDiscoveryDataSource. Not used by single-document Add
    // Document, which keeps its own separate extension list.
  ];

  Future<Directory> _sessionDirectory() async {
    final root = await _rootDirectory();
    return Directory(p.join(root.path, 'import_staging', _sessionId));
  }

  /// Called once at startup, before any live import sessions exist.
  static Future<void> cleanupStaleSessions({
    Future<Directory> Function()? rootDirectory,
  }) async {
    try {
      final root = await (rootDirectory ?? getApplicationDocumentsDirectory)();
      final staging = Directory(p.join(root.path, 'import_staging'));
      if (!await staging.exists()) return;
      await for (final entry in staging.list(followLinks: false)) {
        if (entry is! Directory) continue;
        try {
          await entry.delete(recursive: true);
        } on FileSystemException {
          // Retry next launch if a platform file handle is still open.
        }
      }
    } catch (_) {
      // Cleanup must not prevent startup.
    }
  }

  @override
  Future<BulkPickResult> stage(
    List<({String? path, String name})> files, {
    required int limit,
  }) async {
    final candidates = <BulkImportCandidate>[];
    var skipped = 0;
    var overLimit = 0;
    for (final file in files) {
      if (candidates.length >= limit) {
        overLimit++;
        continue;
      }
      final extension = p.extension(file.name).toLowerCase();
      if (file.path == null ||
          !supportedExtensions.contains(extension.replaceFirst('.', ''))) {
        skipped++;
        continue;
      }
      File? staged;
      try {
        final directory = await _sessionDirectory();
        await directory.create(recursive: true);
        final id = '${_sessionId}_${_sequence++}';
        staged = File(p.join(directory.path, '$id$extension'));
        await File(file.path!).copy(staged.path);
        final title = p.basenameWithoutExtension(file.name).trim();
        candidates.add(
          BulkImportCandidate(
            id: id,
            attachment: AttachmentItem(
              path: staged.path,
              type: isImagePath(staged.path)
                  ? AttachmentType.image
                  : AttachmentType.file,
            ),
            title: title.isEmpty ? 'Untitled document' : title,
            categoryId: uncategorizedCategoryId,
          ),
        );
      } on FileSystemException {
        skipped++;
        try {
          if (staged != null) await _deleteIfExists(staged);
        } on FileSystemException {
          // An incomplete copy will be removed with this session.
        }
      }
    }
    return BulkPickResult(
      List.unmodifiable(candidates),
      skipped: skipped,
      overLimit: overLimit,
    );
  }

  @override
  Future<String> promote(BulkImportCandidate candidate) async {
    final root = await _rootDirectory();
    final directory = Directory(p.join(root.path, 'documents'));
    await directory.create(recursive: true);
    final target = File(
      p.join(
        directory.path,
        'bulk_${candidate.id}${p.extension(candidate.attachment.path)}',
      ),
    );
    try {
      await File(candidate.attachment.path).copy(target.path);
      return target.path;
    } catch (_) {
      await _deleteIfExists(target);
      rethrow;
    }
  }

  @override
  Future<void> removeStaged(BulkImportCandidate candidate) async {
    final session = await _sessionDirectory();
    if (p.dirname(candidate.attachment.path) == session.path) {
      await _deleteIfExists(File(candidate.attachment.path));
    }
  }

  @override
  Future<void> removePromoted(String path) async {
    final root = await _rootDirectory();
    if (p.dirname(path) == p.join(root.path, 'documents') &&
        p.basename(path).startsWith('bulk_${_sessionId}_')) {
      await _deleteIfExists(File(path));
    }
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> discard() async {
    final directory = await _sessionDirectory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
