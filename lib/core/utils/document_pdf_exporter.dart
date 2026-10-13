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

    final images = await _loadImages(imagePaths);
    final pageWidth = _sharedPageWidth(images);
    final pdfDocument = pw.Document();
    for (final image in images) {
      _addImagePage(pdfDocument, image, pageWidth: pageWidth);
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
  ///
  /// When [paths] is just one already-a-PDF file, there's nothing to
  /// combine it *with* — rasterizing it to a JPEG per page and redrawing
  /// those into a new PDF would only lose quality (vector text turned to a
  /// fixed-DPI raster, then JPEG-compressed) for no benefit, so that single
  /// file is copied through untouched instead. This is the common case: a
  /// document that's just one file picked straight from Files already
  /// is "a PDF", so sharing it "as a PDF" should hand back the exact file
  /// the user picked.
  static Future<String> combine(List<String> paths, String title) async {
    if (paths.length == 1 && isPdfPath(paths.single)) {
      return _copyToOutput(paths.single, title);
    }

    // Drop any source file that rasterized to zero pages (unsupported type,
    // unreadable PDF).
    final grouped = (await DocumentPageRasterizer.toImagePathsGrouped(paths))
        .where((group) => group.isNotEmpty)
        .toList(growable: false);

    if (grouped.isEmpty) {
      throw StateError('No pages to export');
    }

    final imagePaths = [for (final group in grouped) ...group];
    final images = await _loadImages(imagePaths);
    final pageWidth = _sharedPageWidth(images);

    final pdfDocument = pw.Document();
    for (final image in images) {
      _addImagePage(pdfDocument, image, pageWidth: pageWidth);
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
      final pdfDocument = pw.Document();
      final image = pw.MemoryImage(await File(imagePaths[i]).readAsBytes());
      _addImagePage(
        pdfDocument,
        image,
        pageWidth: _soloPageWidth(image),
      );
      final file = File(
        p.join(directory.path, '${sanitized}_page_${i + 1}.pdf'),
      );
      await file.writeAsBytes(await pdfDocument.save());
      files.add(file.path);
    }
    return files;
  }

  /// Reads every path's bytes once up front, so [export]/[combine] can
  /// settle on one shared page width before any page gets added — see
  /// [_sharedPageWidth].
  static Future<List<pw.MemoryImage>> _loadImages(List<String> paths) async {
    return [
      for (final path in paths) pw.MemoryImage(await File(path).readAsBytes()),
    ];
  }

  /// Adds [image] as a full-bleed page at [pageWidth], with its height
  /// following its own aspect ratio — the look scanner apps like
  /// CamScanner give a multi-photo PDF, with no blank margins around the
  /// actual content.
  ///
  /// Every page sharing the same [pageWidth] (see [_sharedPageWidth])
  /// matters as much as the full-bleed look itself: two photos of the same
  /// physical document (e.g. an ID card's front and back) are rarely
  /// captured at pixel-identical crops, so sizing each page to *its own*
  /// aspect ratio independently used to give pages slightly different
  /// widths — which a PDF viewer centers, so adjacent pages' left/right
  /// edges visibly didn't line up when scrolling. A shared width keeps
  /// every page's edges aligned; only the height (which a reader expects
  /// to vary page to page) still follows each image.
  static void _addImagePage(
    pw.Document pdfDocument,
    pw.MemoryImage image, {
    required double pageWidth,
  }) {
    pdfDocument.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, _heightFor(image, pageWidth)),
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }

  /// The common page width for a whole [export]/[combine] job: the widest
  /// of every page's own width, each scaled so that *that* image's longer
  /// edge matches A4's (keeping the overall output at a familiar,
  /// printable scale) — i.e. the same per-image scale [exportEachPage]
  /// uses via [_soloPageWidth], just taken as a max across the whole set
  /// instead of applied independently per page.
  static double _sharedPageWidth(List<pw.MemoryImage> images) {
    var widest = 0.0;
    for (final image in images) {
      final width = _soloPageWidth(image);
      if (width > widest) widest = width;
    }
    return widest > 0 ? widest : PdfPageFormat.a4.width;
  }

  /// [image]'s own width, scaled so its longer edge matches A4's — used
  /// directly by [exportEachPage] (each page is its own standalone file,
  /// so there's no shared width to match) and as the per-candidate input
  /// to [_sharedPageWidth].
  static double _soloPageWidth(pw.MemoryImage image) {
    final width = image.width;
    final height = image.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return PdfPageFormat.a4.width;
    }
    final longEdge = width > height ? width : height;
    return width * PdfPageFormat.a4.height / longEdge;
  }

  /// [image]'s height once scaled to [pageWidth], preserving its own
  /// aspect ratio.
  static double _heightFor(pw.MemoryImage image, double pageWidth) {
    final width = image.width;
    final height = image.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return pageWidth * PdfPageFormat.a4.height / PdfPageFormat.a4.width;
    }
    return pageWidth * height / width;
  }

  /// Copies [path] byte-for-byte into the app's temp directory under
  /// [title]'s sanitized name — the lossless equivalent of [combine]'s
  /// normal rasterize-and-redraw path, for when there's genuinely nothing
  /// to combine [path] with.
  static Future<String> _copyToOutput(String path, String title) async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, '${_sanitize(title)}.pdf'));
    await File(path).copy(file.path);
    return file.path;
  }

  static String _sanitize(String title) {
    final sanitized = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'document' : sanitized;
  }
}