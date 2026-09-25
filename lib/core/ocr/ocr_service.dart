import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../features/home/viewmodel/home_viewmodel.dart'
    show isImagePath, isPdfPath;

/// On-device text extraction (Google ML Kit — fully offline, no API key)
/// for a document's attachments. Hides every ML Kit/pdfx SDK type behind a
/// plain [String] return so callers (AddDocumentViewModel) never see
/// [TextRecognizer]/[RecognizedText]/[InputImage] directly — same shape as
/// [SecurityController] wrapping `local_auth`.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

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
    final inputImage = InputImage.fromFilePath(path);
    final result = await _recognizer.processImage(inputImage);
    return _orderedText(result.blocks);
  }

  /// ML Kit's own block order (its internal layout-clustering heuristic)
  /// can scramble busy/multi-column layouts like ID cards — verified
  /// against a real scan where an unrelated line jumped to the very top of
  /// the output. Re-sorting blocks top-to-bottom, falling back to
  /// left-to-right for blocks that start at roughly the same height (so
  /// two side-by-side columns don't get interleaved line-by-line), gives a
  /// more reliable reading order without a heavier layout-analysis pass.
  String _orderedText(List<TextBlock> blocks) {
    if (blocks.isEmpty) return '';
    final heights = blocks.map((b) => b.boundingBox.height).toList()..sort();
    // Half the median block height is a "same visual row" tolerance that
    // scales with the image's own resolution, instead of a fixed pixel
    // threshold that would be wrong for a smaller/larger photo.
    final rowThreshold = heights[heights.length ~/ 2] / 2;

    final sorted = List<TextBlock>.of(blocks)
      ..sort((a, b) {
        final topDelta = a.boundingBox.top - b.boundingBox.top;
        if (topDelta.abs() < rowThreshold) {
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        }
        return topDelta < 0 ? -1 : 1;
      });
    return sorted.map((b) => b.text).join('\n');
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

  void dispose() => _recognizer.close();
}
