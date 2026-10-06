import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../domain/entities/document_item.dart';

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
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.filePaths.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) =>
            _ZoomableFile(path: widget.filePaths[index]),
      ),
    );
  }
}

class _ZoomableFile extends StatefulWidget {
  final String path;

  const _ZoomableFile({required this.path});

  @override
  State<_ZoomableFile> createState() => _ZoomableFileState();
}

class _ZoomableFileState extends State<_ZoomableFile> {
  final _zoomController = TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  void _syncZoomState() {
    final isZoomed = _zoomController.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed != _isZoomed && mounted) setState(() => _isZoomed = isZoomed);
  }

  void _resetZoom() {
    _zoomController.value = _zoomController.value.clone()..setIdentity();
    if (_isZoomed) setState(() => _isZoomed = false);
  }

  @override
  Widget build(BuildContext context) {
    // pdfx's PdfViewPinch already owns its own pinch-zoom/pan — wrapping it
    // in another InteractiveViewer here would just fight it for the same
    // gestures, so a PDF page skips this file's zoom handling entirely.
    if (isPdfPath(widget.path)) {
      return PdfZoomView(
        path: widget.path,
        fallback: _UnsupportedFile(path: widget.path),
      );
    }

    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: InteractiveViewer(
        transformationController: _zoomController,
        panEnabled: _isZoomed,
        minScale: 1,
        maxScale: 5,
        onInteractionEnd: (_) => _syncZoomState(),
        child: Center(
          child: isImagePath(widget.path)
              ? Image.file(
                  File(widget.path),
                  fit: .contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _UnsupportedFile(path: widget.path),
                )
              : _UnsupportedFile(path: widget.path),
        ),
      ),
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
