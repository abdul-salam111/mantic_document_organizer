import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Renders one page of a PDF file as a raster thumbnail, at [renderWidth]
/// (default [_defaultRenderWidth] -- deliberately low-res, for a
/// card-sized box). Pass a larger [renderWidth] for a bigger display box
/// (e.g. full device width) -- the default would upscale and look
/// pixelated at that size. Opening/rendering/closing the document on every
/// build would be wasteful, so the render is done once and cached in
/// state.
class PdfPageThumbnail extends StatefulWidget {
  final String path;
  final int pageNumber;
  final Widget fallback;
  final BoxFit fit;
  final double renderWidth;

  /// Called once the document is opened for rendering, with its total page
  /// count -- for callers that want to show e.g. a "N pages" badge next to
  /// a single-page thumbnail without opening the document a second time.
  final ValueChanged<int>? onPagesCount;

  static const double _defaultRenderWidth = 160;

  const PdfPageThumbnail({
    super.key,
    required this.path,
    required this.fallback,
    this.pageNumber = 1,
    this.fit = BoxFit.cover,
    this.renderWidth = _defaultRenderWidth,
    this.onPagesCount,
  });

  @override
  State<PdfPageThumbnail> createState() => _PdfPageThumbnailState();
}

class _PdfPageThumbnailState extends State<PdfPageThumbnail> {
  late Future<Uint8List?> _page = _render();

  @override
  void didUpdateWidget(covariant PdfPageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A list that inserts/reorders items without a distinct Key per item
    // reuses this State for whatever now occupies this slot — recompute
    // rather than keep showing the previous page's already-rendered image.
    if (oldWidget.path != widget.path ||
        oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.renderWidth != widget.renderWidth) {
      _page = _render();
    }
  }

  Future<Uint8List?> _render() async {
    try {
      final document = await PdfDocument.openFile(widget.path);
      widget.onPagesCount?.call(document.pagesCount);
      final page = await document.getPage(widget.pageNumber);
      final scale = widget.renderWidth / page.width;
      final image = await page.render(
        width: widget.renderWidth,
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
