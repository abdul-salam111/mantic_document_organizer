import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/constants_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';

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
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  const DocumentCoverThumbnail({
    super.key,
    required this.document,
    required this.color,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.iconSize,
  });

  Widget _iconFallback() => Container(
    width: width,
    height: height,
    alignment: .center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: .circular(borderRadius),
    ),
    child: FaIcon(iconForKey(document.iconKey), size: iconSize, color: color),
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
          width: width,
          height: height,
          fit: .cover,
          errorBuilder: (context, error, stackTrace) => _iconFallback(),
        ),
      );
    }

    if (isPdfPath(path)) {
      return ClipRRect(
        borderRadius: .circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: PdfPageThumbnail(path: path, fallback: _iconFallback()),
        ),
      );
    }

    return _iconFallback();
  }
}
