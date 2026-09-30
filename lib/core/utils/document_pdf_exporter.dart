import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
    final file = File(p.join(directory.path, '${_fileName(document)}.pdf'));
    await file.writeAsBytes(await pdfDocument.save());
    return file.path;
  }

  static String _fileName(DocumentItem document) {
    final sanitized = document.title.trim().replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );
    return sanitized.isEmpty ? 'document' : sanitized;
  }
}
