import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/widgets/widgets_exports.dart';
import '../../viewmodel/home_viewmodel.dart';

/// The document's own first attached file rendered as its visual identity
/// — an image is shown directly, a PDF's first page is rasterized via
/// pdfx — falling back to the category icon only when there's no
/// attachment or the file type has no renderer (matches document_viewer's
/// own honest no-preview fallback for those types, e.g. docx/xlsx). Shared
/// by every document card (list/grid tiles, Home's Recent Files) so they
/// don't each reimplement the same image/pdf/icon branching.
class DocumentCoverThumbnail extends StatelessWidget {
  final DocumentItem document;
  final Color color;
  final double size;
  final double borderRadius;
  final double iconSize;

  const DocumentCoverThumbnail({
    super.key,
    required this.document,
    required this.color,
    required this.size,
    required this.borderRadius,
    required this.iconSize,
  });

  Widget _iconFallback() => Container(
    width: size,
    height: size,
    alignment: .center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: .circular(borderRadius),
    ),
    child: FaIcon(document.icon, size: iconSize, color: color),
  );

  @override
  Widget build(BuildContext context) {
    final path = document.filePaths.isEmpty ? null : document.filePaths.first;
    if (path == null) return _iconFallback();

    if (isImagePath(path)) {
      return ClipRRect(
        borderRadius: .circular(borderRadius),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: .cover,
          errorBuilder: (context, error, stackTrace) => _iconFallback(),
        ),
      );
    }

    if (isPdfPath(path)) {
      return ClipRRect(
        borderRadius: .circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child: _PdfCover(path: path, fallback: _iconFallback()),
        ),
      );
    }

    return _iconFallback();
  }
}

/// Renders a PDF's first page as a small raster thumbnail. Kept deliberately
/// low-resolution (see [_renderWidth]) since this only ever needs to fill a
/// card-sized square, not a full-screen preview (that's document_viewer's
/// job) — opening/rendering/closing the document on every build would be
/// wasteful, so the render is done once and cached in state.
class _PdfCover extends StatefulWidget {
  final String path;
  final Widget fallback;

  const _PdfCover({required this.path, required this.fallback});

  @override
  State<_PdfCover> createState() => _PdfCoverState();
}

class _PdfCoverState extends State<_PdfCover> {
  static const double _renderWidth = 160;

  late final Future<Uint8List?> _cover = _renderFirstPage();

  Future<Uint8List?> _renderFirstPage() async {
    try {
      final document = await PdfDocument.openFile(widget.path);
      final page = await document.getPage(1);
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
      future: _cover,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback;
        return Image.memory(bytes, fit: .cover);
      },
    );
  }
}
