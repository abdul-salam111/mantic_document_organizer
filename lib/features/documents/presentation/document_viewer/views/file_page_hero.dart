import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/widgets/widgets_exports.dart';
import '../../../domain/entities/document_item.dart';

/// Tag for the [Hero] that flies a single attached file between its small
/// preview in the document viewer's page list and its own full-screen page
/// in `FilePreviewView`. Keyed by the file's own path rather than the
/// owning document's id — stable/unique per attachment, and lets both
/// sides build the tag without either needing to know the document.
String filePageHeroTag(String path) => 'document-page-$path';

/// Wraps [child] in that [Hero]. Both the viewer's page list and
/// `FilePreviewView` use this (the former via this widget, the latter via
/// `PhotoViewHeroAttributes`, which mirrors the same [Hero] parameters)
/// so the tag and the mid-flight content are never built differently on
/// either end.
class FilePageHero extends StatelessWidget {
  final String path;
  final Widget child;

  const FilePageHero({super.key, required this.path, required this.child});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: filePageHeroTag(path),
      flightShuttleBuilder: (flightContext, _, _, _, _) =>
          filePageHeroFlightContent(flightContext, path),
      child: child,
    );
  }
}

/// The mid-flight content for [path], shared by [FilePageHero] and
/// `FilePreviewView`'s own `PhotoViewHeroAttributes.flightShuttleBuilder`.
/// Deliberately a cheap, static render rather than whichever of the two
/// real widgets this flight is between — the page list's capped-resolution
/// `Image.file`, or `FilePreviewView`'s live, interactive `PdfZoomView` for
/// a PDF — so the flight never has to instantiate (and immediately
/// discard) a second copy of either just for its own ~300ms.
Widget filePageHeroFlightContent(BuildContext context, String path) {
  if (isImagePath(path)) {
    return Image.file(
      File(path),
      fit: .contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
  if (isPdfPath(path)) {
    return ColoredBox(
      color: Colors.black,
      child: PdfPageThumbnail(
        path: path,
        fit: .contain,
        renderWidth:
            MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context),
        fallback: const SizedBox.shrink(),
      ),
    );
  }
  return const SizedBox.shrink();
}
