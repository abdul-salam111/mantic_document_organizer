import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../features/documents/domain/entities/document_item.dart';

/// Turns a mix of image/PDF attachment paths into plain image files — an
/// image path is returned as-is; a PDF path is rendered page-by-page into
/// scratch JPEGs. Shared by every share-sheet action that needs "just the
/// pages as pictures" (Share as Images, Save to Gallery, and the
/// per-page-PDF/combined-PDF exporters in [DocumentPdfExporter], which draw
/// these images back into PDF pages).
class DocumentPageRasterizer {
  const DocumentPageRasterizer._();

  /// pdfx's `page.width`/`page.height` reflect the PDF's own source pixel
  /// size, which is often low-DPI — rendering at a multiple of that gives a
  /// sharper image (mirrors OcrService's own render scale).
  static const double _renderScale = 2.5;

  static Future<List<String>> toImagePaths(List<String> paths) async {
    final result = <String>[];
    for (final path in paths) {
      if (isImagePath(path)) {
        result.add(path);
      } else if (isPdfPath(path)) {
        result.addAll(await _renderPages(path));
      }
    }
    return result;
  }

  /// Renders every page of [path] to a scratch JPEG, one page at a time —
  /// Android disallows rendering multiple PDF pages concurrently (same
  /// constraint OcrService and document_cover_thumbnail already work
  /// around), so this never renders pages in parallel.
  static Future<List<String>> _renderPages(String path) async {
    final document = await PdfDocument.openFile(path);
    final tempDir = await getTemporaryDirectory();
    final pages = <String>[];

    for (var i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final image = await page.render(
        width: page.width * _renderScale,
        height: page.height * _renderScale,
      );
      await page.close();

      final bytes = image?.bytes;
      if (bytes == null) continue;

      final file = File(
        '${tempDir.path}/page_${DateTime.now().microsecondsSinceEpoch}_$i.jpg',
      );
      await file.writeAsBytes(bytes);
      pages.add(file.path);
    }
    await document.close();
    return pages;
  }
}
