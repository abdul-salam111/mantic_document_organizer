import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Renders one page of a PDF file as a small raster thumbnail. Kept
/// deliberately low-resolution (see [_renderWidth]) since this only ever
/// needs to fill a card-sized box, not a full-screen preview (that's
/// document_viewer's job) — opening/rendering/closing the document on
/// every build would be wasteful, so the render is done once and cached
/// in state.
class PdfPageThumbnail extends StatefulWidget {
  final String path;
  final int pageNumber;
  final Widget fallback;
  final BoxFit fit;

  const PdfPageThumbnail({
    super.key,
    required this.path,
    required this.fallback,
    this.pageNumber = 1,
    this.fit = BoxFit.cover,
  });

  @override
  State<PdfPageThumbnail> createState() => _PdfPageThumbnailState();
}

class _PdfPageThumbnailState extends State<PdfPageThumbnail> {
  static const double _renderWidth = 160;

  late Future<Uint8List?> _page = _render();

  @override
  void didUpdateWidget(covariant PdfPageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A list that inserts/reorders items without a distinct Key per item
    // reuses this State for whatever now occupies this slot — recompute
    // rather than keep showing the previous page's already-rendered image.
    if (oldWidget.path != widget.path ||
        oldWidget.pageNumber != widget.pageNumber) {
      _page = _render();
    }
  }

  Future<Uint8List?> _render() async {
    try {
      final document = await PdfDocument.openFile(widget.path);
      final page = await document.getPage(widget.pageNumber);
      final scale = _renderWidth / page.width;
      final image = await page.render(
        width: _renderWidth,
        height: page.height * scale,
      );
      await page.close();
      await document.close();
      return image?.bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _page,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback;
        return Image.memory(bytes, fit: widget.fit);
      },
    );
  }
}
