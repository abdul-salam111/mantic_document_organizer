import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/utils/persist_action.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../domain/entities/document_item.dart';
import '../../../domain/usecases/document_processing_usecases.dart';

/// Full-screen, swipeable, pinch-zoomable view of a document's attached
/// files at their original size. Opened by tapping a page in the document
/// viewer's own page list — [initialIndex] is which page to open on, and
/// [filePaths] is the same set the viewer itself shows, so swiping here
/// moves between the rest of them.
class FilePreviewView extends StatefulWidget {
  final List<String> filePaths;
  final int initialIndex;

  const FilePreviewView({
    super.key,
    required this.filePaths,
    required this.initialIndex,
  });

  @override
  State<FilePreviewView> createState() => _FilePreviewViewState();
}

class _FilePreviewViewState extends State<FilePreviewView> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;
  final _processing = sl<DocumentProcessingUseCases>();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: widget.filePaths.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.filePaths.length}',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      // PhotoViewGallery — not a hand-rolled PageView+InteractiveViewer —
      // owns both the swipe-between-files paging and each page's
      // pinch-zoom. Those two gestures fight over the same pointers when
      // hand-rolled (pinching on the image itself loses the gesture arena
      // to the ancestor PageView's drag recognizer, so zoom only ever
      // triggered off the image, never on it); this package exists
      // specifically to resolve that arena conflict correctly.
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.filePaths.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        builder: (context, index) => _buildPageOptions(widget.filePaths[index]),
      ),
      bottomNavigationBar: _FilePreviewActionBar(
        onShare: () => _share(context),
        onSaveToGallery: () => _saveToGallery(context),
      ),
    );
  }

  String get _currentPath => widget.filePaths[_currentIndex];

  Future<void> _share(BuildContext context) =>
      persistAction(context, () => _processing.shareFile(_currentPath));

  Future<void> _saveToGallery(BuildContext context) async {
    final saved = await persistAction(
      context,
      () => _processing.saveToGallery([_currentPath]),
    );
    if (saved && context.mounted) {
      AppToastsUtils.success(AppLocalizations.of(context).savedToGalleryToast);
    }
  }

  PhotoViewGalleryPageOptions _buildPageOptions(String path) {
    // pdfx's PdfViewPinch already owns its own pinch-zoom/pan/multi-page
    // gestures, so this page opts out of PhotoView's own gesture handling
    // (disableGestures) rather than fight it for the same pointers, and
    // just rides along in the gallery's page view for swipe-between-files.
    if (isPdfPath(path)) {
      return PhotoViewGalleryPageOptions.customChild(
        disableGestures: true,
        child: PdfZoomView(path: path, fallback: _UnsupportedFile(path: path)),
      );
    }
    if (isImagePath(path)) {
      return PhotoViewGalleryPageOptions(
        imageProvider: FileImage(File(path)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        errorBuilder: (context, error, stackTrace) =>
            _UnsupportedFile(path: path),
      );
    }
    return PhotoViewGalleryPageOptions.customChild(
      disableGestures: true,
      child: _UnsupportedFile(path: path),
    );
  }
}

class _UnsupportedFile extends StatelessWidget {
  final String path;

  const _UnsupportedFile({required this.path});

  String get _fileName => path.replaceAll('\\', '/').split('/').last;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const .all(24),
      child: Column(
        mainAxisSize: .min,
        children: [
          const Icon(Iconsax.document_text, size: 56, color: Colors.white70),
          heightBox(12),
          Text(
            _fileName,
            textAlign: .center,
            maxLines: 2,
            overflow: .ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: .w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Share/save actions for the file currently on screen — this view only
/// ever has these two (unlike the document viewer's own bottom bar, which
/// also edits/renames/moves the whole document), so it's a small bespoke
/// bar rather than reusing _DocumentActionBar, and matches this screen's
/// own black/white full-screen styling instead of the themed surface colors
/// that bar uses.
class _FilePreviewActionBar extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onSaveToGallery;

  const _FilePreviewActionBar({
    required this.onShare,
    required this.onSaveToGallery,
  });

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: ColoredBox(
        color: Colors.black,
        child: Row(
          children: [
            _FilePreviewActionItem(
              icon: Iconsax.share,
              label: "Share this File",
              onTap: onShare,
            ),
            _FilePreviewActionItem(
              icon: Iconsax.gallery_add,
              label: "Save to Gallery",
              onTap: onSaveToGallery,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePreviewActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilePreviewActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const .symmetric(vertical: 12),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            heightBox(4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
