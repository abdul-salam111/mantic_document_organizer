import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'document_page_rasterizer.dart';

/// Combines a [DocumentItem]'s scanned image pages into a single, shareable
/// PDF. The document viewer's existing "Share" action already sends
/// [DocumentItem.filePaths] as-is, which for a multi-page scan means several
/// separate image files landing in the OS share sheet instead of one
/// document — this exists to give the user an actual single PDF file
/// instead.
///
/// Only rasterizes [DocumentItem.filePaths] entries that are images (see
/// [isImagePath]); any entry that's already a PDF or an unsupported type is
/// skipped rather than merged in, since merging real PDF byte streams needs
/// a different library than page-drawing does — out of scope for what this
/// is for (turning a stack of scanned photos into one file).
class DocumentPdfExporter {
  const DocumentPdfExporter._();

  /// Builds the combined PDF in the app's temp directory and returns its
  /// path. Throws [StateError] if [document] has no image pages to
  /// rasterize (callers should only offer this action when one exists).
  static Future<String> export(DocumentItem document) async {
    final imagePaths = document.filePaths.where(isImagePath).toList();
    if (imagePaths.isEmpty) {
      throw StateError('${document.title} has no image pages to export');
    }

    final pdfDocument = pw.Document();
    for (final path in imagePaths) {
      final image = pw.MemoryImage(await File(path).readAsBytes());
      pdfDocument.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, '${_sanitize(document.title)}.pdf'));
    await file.writeAsBytes(await pdfDocument.save());
    return file.path;
  }

  /// Combines an arbitrary set of attachment paths into a single PDF —
  /// the share sheet's "Share as PDF" action. Unlike [export], real PDF
  /// pages in [paths] aren't skipped: they're rasterized first (via
  /// [DocumentPageRasterizer], same tradeoff as [export]'s own doc comment
  /// — no library here can merge real PDF byte streams) so a selection
  /// mixing scanned photos and an existing PDF attachment still produces
  /// one combined file.
  static Future<String> combine(List<String> paths, String title) async {
    final imagePaths = await DocumentPageRasterizer.toImagePaths(paths);
    if (imagePaths.isEmpty) {
      throw StateError('No pages to export');
    }

    final pdfDocument = pw.Document();
    for (final path in imagePaths) {
      final image = pw.MemoryImage(await File(path).readAsBytes());
      pdfDocument.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, '${_sanitize(title)}.pdf'));
    await file.writeAsBytes(await pdfDocument.save());
    return file.path;
  }

  /// Exports every page in [paths] as its own separate single-page PDF
  /// file — the share sheet's "Export Each Page as PDF" action. A real PDF
  /// attachment is split page-by-page the same way [combine] merges one in:
  /// each of its pages is rasterized, then wrapped as its own PDF.
  static Future<List<String>> exportEachPage(
    List<String> paths,
    String title,
  ) async {
    final imagePaths = await DocumentPageRasterizer.toImagePaths(paths);
    if (imagePaths.isEmpty) {
      throw StateError('No pages to export');
    }

    final directory = await getTemporaryDirectory();
    final sanitized = _sanitize(title);
    final files = <String>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final image = pw.MemoryImage(await File(imagePaths[i]).readAsBytes());
      final pdfDocument = pw.Document()
        ..addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) =>
                pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ),
        );
      final file = File(
        p.join(directory.path, '${sanitized}_page_${i + 1}.pdf'),
      );
      await file.writeAsBytes(await pdfDocument.save());
      files.add(file.path);
    }
    return files;
  }

  static String _sanitize(String title) {
    final sanitized = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'document' : sanitized;
  }
}
