import '../../features/documents/domain/entities/document_item.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// On-device text extraction for a document's attachments. OCR stays native:
/// Android uses ML Kit directly from the app and iOS uses Apple's Vision
/// framework. Keeping the channel here prevents the UI and domain layers from
/// depending on either native SDK or a CocoaPods-only Flutter plugin.
class OcrService {
  static const _channel = MethodChannel('mantic.document.organizer/ocr');

  /// How many pages of a PDF to OCR — a relevant date/name could be on any
  /// page, but an unbounded loop risks pathological cost on a large
  /// attached PDF, so this is a deliberate cap, not a limitation of the
  /// recognizer itself.
  static const int _maxPdfPages = 5;

  /// pdfx's `page.width`/`page.height` reflect the PDF's own source pixel
  /// size, which is often low (roughly 72-96 DPI-equivalent) — too soft
  /// for OCR on dense print. Rendering at a multiple of that gives the
  /// recognizer a sharper bitmap to work with, at the cost of a larger
  /// per-page bitmap (still bounded by [_maxPdfPages]).
  static const double _pdfRenderScale = 2.5;

  /// Never throws — returns '' for any failure or unsupported file type,
  /// so callers can treat OCR as always-succeeds-or-empty and never need
  /// their own try/catch around this.
  Future<String> extractText(String path) async {
    try {
      if (isImagePath(path)) return await _extractFromImage(path);
      if (isPdfPath(path)) return await _extractFromPdf(path);
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<String> _extractFromImage(String path) async {
    if (!Platform.isAndroid && !Platform.isIOS) return '';
    return await _channel.invokeMethod<String>('recognizeText', {
          'path': path,
        }) ??
        '';
  }

  /// Renders each page to a scratch JPEG (pdfx's default render format —
  /// verified against the package source, not assumed) and OCRs that, one
  /// page at a time — this codebase already documents that Android
  /// disallows parallel PDF rendering (see
  /// document_cover_thumbnail.dart's _PdfCover), so pages are never
  /// rendered concurrently here either.
  Future<String> _extractFromPdf(String path) async {
    final document = await PdfDocument.openFile(path);
    final pageCount = document.pagesCount < _maxPdfPages
        ? document.pagesCount
        : _maxPdfPages;
    final tempDir = await getTemporaryDirectory();
    final pageTexts = <String>[];

    for (var i = 1; i <= pageCount; i++) {
      final page = await document.getPage(i);
      final image = await page.render(
        width: page.width * _pdfRenderScale,
        height: page.height * _pdfRenderScale,
      );
      await page.close();

      final bytes = image?.bytes;
      if (bytes == null) continue;

      final scratchFile = File(
        '${tempDir.path}/ocr_scratch_${DateTime.now().microsecondsSinceEpoch}_$i.jpg',
      );
      try {
        await scratchFile.writeAsBytes(bytes);
        final text = await _extractFromImage(scratchFile.path);
        if (text.trim().isNotEmpty) pageTexts.add(text);
      } finally {
        if (await scratchFile.exists()) await scratchFile.delete();
      }
    }

    await document.close();
    return pageTexts.join('\n\n');
  }

  void dispose() {}
}
