import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Full pinch-zoom/pan PDF viewer (wraps pdfx's `PdfViewPinch`, which
/// already owns its own zoom/pan/multi-page-swipe gestures — don't nest
/// this inside another zoom widget, they'll fight over the same gestures).
/// Shared by the document viewer's inline page list and the full-screen
/// file preview screen so both get identical PDF zoom behavior from one
/// `PdfControllerPinch` setup instead of two slightly different ones.
class PdfZoomView extends StatefulWidget {
  final String path;
  final Widget fallback;

  /// Called whenever the page centered in the viewport changes, with the
  /// document's total page count alongside it -- the only way to surface a
  /// real "page N of M" indicator, since [path] may be a multi-page PDF and
  /// this widget owns the only [PdfControllerPinch] that knows that count.
  final void Function(int page, int? pagesCount)? onPageChanged;

  const PdfZoomView({
    super.key,
    required this.path,
    required this.fallback,
    this.onPageChanged,
  });

  @override
  State<PdfZoomView> createState() => _PdfZoomViewState();
}

class _PdfZoomViewState extends State<PdfZoomView> {
  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: PdfDocument.openFile(widget.path),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _controller,
      onPageChanged: (page) =>
          widget.onPageChanged?.call(page, _controller.pagesCount),
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error) => widget.fallback,
      ),
    );
  }
}
