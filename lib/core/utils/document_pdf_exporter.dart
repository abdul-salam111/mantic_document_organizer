import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
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

  /// Height of the visual gap inserted between two files in the combined
  /// PDF, in PDF points (1 pt = 1/72 inch). 15 px at the PDF library's
  /// default 72 dpi maps 1:1 to points, so 15 here == 15 px on screen at
  /// 100% zoom.
  static const double _fileGap = 15;

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
      await _addImagePage(pdfDocument, path);
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
  /// A [_fileGap]-point blank page is inserted between each source file so
  /// two adjacent files don't visually butt up against each other.
  static Future<String> combine(List<String> paths, String title) async {
    // Drop any source file that rasterized to zero pages (unsupported type,
    // unreadable PDF) — otherwise an empty group would produce a gap page
    // sitting next to nothing.
    final grouped = (await DocumentPageRasterizer.toImagePathsGrouped(paths))
        .where((group) => group.isNotEmpty)
        .toList(growable: false);

    if (grouped.isEmpty) {
      throw StateError('No pages to export');
    }

    final pdfDocument = pw.Document();
    for (var i = 0; i < grouped.length; i++) {
      for (final imagePath in grouped[i]) {
        await _addImagePage(pdfDocument, imagePath);
      }
      // Gap between files, not after the last one.
      if (i < grouped.length - 1) {
        _addGapPage(pdfDocument, _fileGap);
      }
    }

    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, '${_sanitize(title)}.pdf'));
    await file.writeAsBytes(await pdfDocument.save());
    return file.path;
  }

  /// Merges [imagePaths] into a single PDF written into the app's
  /// permanent attachment storage (`<app documents>/documents/`, same
  /// folder [AttachmentLocalDataSource] persists picked files into) --
  /// for collapsing a multi-page scan's separate image files into the
  /// one PDF it's actually saved as. Unlike [export]/[combine], this
  /// result is meant to be kept, not shared, so it's written next to the
  /// other persisted attachments instead of the temp directory.
  ///
  /// Unlike [_addImagePage]'s usual per-image aspect ratio, every page here
  /// shares the *same* page size (taken from the first image). The in-app
  /// PDF viewer (pdfx's `PdfViewPinch`, see `PdfZoomView`) assumes every
  /// page is sized like page 1 until it individually re-measures each one,
  /// so a page whose real size differs renders briefly cropped/mis-scaled
  /// against that wrong assumption. Images that don't match the first
  /// page's aspect ratio are letterboxed (`BoxFit.contain`) instead of
  /// stretched to fill it.
  static Future<String> mergeForStorage(List<String> imagePaths) async {
    final pdfDocument = pw.Document();
    PdfPageFormat? format;
    for (final path in imagePaths) {
      final image = await _loadImage(path, downsample: true);
      format ??= _pageFormatFor(image);
      pdfDocument.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final appDocuments = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDocuments.path, 'documents'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(
      p.join(dir.path, 'merged_${DateTime.now().microsecondsSinceEpoch}.pdf'),
    );
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
      await _addImagePage(pdfDocument, imagePaths[i]);
      final file = File(
        p.join(directory.path, '${sanitized}_page_${i + 1}.pdf'),
      );
      await file.writeAsBytes(await pdfDocument.save());
      files.add(file.path);
    }
    return files;
  }

  /// Adds a blank page [gap] points tall, with the same width as A4 so it
  /// reads as a separator strip rather than a full sheet. This is the
  /// simplest way to force a visual gap between two files in the `pdf`
  /// package — pages are independent canvases, so there's no "draw
  /// something between page N and page N+1" API; a thin blank page is
  /// the idiomatic equivalent.
  static void _addGapPage(pw.Document pdfDocument, double gap) {
    pdfDocument.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(PdfPageFormat.a4.width, gap),
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.SizedBox(),
      ),
    );
  }

  /// Adds [path] as its own full-bleed page, sized to *its* aspect ratio
  /// instead of being letterboxed onto a fixed A4 canvas — the look scanner
  /// apps like CamScanner give a multi-photo PDF, where every page's shape
  /// just follows whatever was scanned (a wide receipt gets a wide page, a
  /// tall ID card gets a tall one) rather than all pages sharing one
  /// generic paper size with blank margins around the actual content.
  static Future<void> _addImagePage(pw.Document pdfDocument, String path) async {
    final image = await _loadImage(path);
    pdfDocument.addPage(
      pw.Page(
        pageFormat: _pageFormatFor(image),
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }

  /// Caps an embedded page image's long edge at this many pixels when
  /// [_loadImage] is asked to downsample -- camera captures/picked photos
  /// can easily be 3000-4000px+ on a side, deliberately kept untouched at
  /// pick time for OCR accuracy (see
  /// AttachmentLocalDataSource.pickFromGallery's own comment), but that's
  /// far more pixel data than a phone screen needs, or than pdfx's
  /// PdfViewPinch (the in-app viewer -- see PdfZoomView) can open/scroll
  /// smoothly. OCR already runs against each attachment's original
  /// full-resolution file before [mergeForStorage] ever merges them
  /// (AddDocumentViewModel._runOcrAndAi), so downsampling here doesn't
  /// touch extraction accuracy -- only how heavy the stored,
  /// in-app-viewed PDF ends up being.
  static const int _maxStoredImageDimension = 2000;
  static const int _storedImageQuality = 85;

  /// Loads [path] as a [pw.MemoryImage]. With [downsample] true, re-encodes
  /// it first if it exceeds [_maxStoredImageDimension] on its long edge --
  /// only [mergeForStorage] asks for this; [export]/[combine]/
  /// [exportEachPage] are explicit share/export actions where keeping full
  /// fidelity (for printing/archival elsewhere) matters more than this
  /// app's own in-app render cost.
  static Future<pw.MemoryImage> _loadImage(
    String path, {
    bool downsample = false,
  }) async {
    final bytes = await File(path).readAsBytes();
    if (!downsample) return pw.MemoryImage(bytes);

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return pw.MemoryImage(bytes);
    final longEdge = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    if (longEdge <= _maxStoredImageDimension) return pw.MemoryImage(bytes);

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height
          ? _maxStoredImageDimension
          : null,
      height: decoded.height > decoded.width
          ? _maxStoredImageDimension
          : null,
    );
    return pw.MemoryImage(
      Uint8List.fromList(img.encodeJpg(resized, quality: _storedImageQuality)),
    );
  }

  /// A page format matching [image]'s own aspect ratio, scaled so its
  /// longer edge matches A4's — keeping multi-page output at a familiar,
  /// printable scale — rather than [PdfPageFormat.a4]'s fixed portrait
  /// rectangle every image used to be centered/letterboxed onto regardless
  /// of its actual shape.
  static PdfPageFormat _pageFormatFor(pw.MemoryImage image) {
    final width = image.width;
    final height = image.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return PdfPageFormat.a4;
    }
    final longEdge = width > height ? width : height;
    final scale = PdfPageFormat.a4.height / longEdge;
    return PdfPageFormat(width * scale, height * scale);
  }

  static String _sanitize(String title) {
    final sanitized = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'document' : sanitized;
  }
}