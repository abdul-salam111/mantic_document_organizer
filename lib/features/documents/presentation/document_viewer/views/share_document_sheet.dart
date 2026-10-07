import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../domain/entities/document_item.dart';

enum ShareSheetAction {
  osShareSheet,
  shareAsPdf,
  shareAsImages,
  exportPagesAsPdf,
  saveToGallery,
}

class ShareSheetResult {
  final ShareSheetAction action;
  final List<String> paths;

  const ShareSheetResult({required this.action, required this.paths});
}

/// Full-screen file-selection + share sheet opened from the document
/// viewer's Share button. Picks nothing itself — every tap just pops a
/// [ShareSheetResult] describing what the caller should do, the same
/// "sheet is a picker, the page performs the action" split this screen
/// already uses for its move/rename sheets.
class ShareDocumentSheet extends StatefulWidget {
  final DocumentItem document;

  const ShareDocumentSheet({super.key, required this.document});

  @override
  State<ShareDocumentSheet> createState() => _ShareDocumentSheetState();
}

class _ShareDocumentSheetState extends State<ShareDocumentSheet> {
  // Used for any file until its real ratio resolves (or if it never does)
  // — close to a portrait scan/photo so a tile doesn't flash an odd shape.
  static const double _fallbackAspectRatio = 0.75;

  late Set<int> _selected = {
    for (var i = 0; i < widget.document.filePaths.length; i++) i,
  };

  // Keyed by index rather than resolved per-tile: centralizing it here
  // (instead of each tile resolving its own) lets the single-file and
  // multi-file layouts below both do real arithmetic with the ratio —
  // sizing a tile to fill the sheet's width, or picking a shared strip
  // height — rather than only being able to hand it to an AspectRatio
  // widget.
  final Map<int, double> _aspectRatios = {};
  bool _selectAllMode = true;
  bool _previewsStarted = false;

  /// Resolved one file at a time, not concurrently — PDF rendering can't
  /// run in parallel on Android (same constraint documented on
  /// DocumentPageRasterizer/OcrService), and this reads page size through
  /// the same pdfx document-open path.
  Future<void> _resolveAspectRatios() async {
    for (var i = 0; i < widget.document.filePaths.length; i++) {
      final ratio = await _probeAspectRatio(widget.document.filePaths[i]);
      if (!mounted) return;
      if (ratio != null) setState(() => _aspectRatios[i] = ratio);
    }
  }

  List<String> get _selectedPaths => [
    for (var i = 0; i < widget.document.filePaths.length; i++)
      if (_selected.contains(i)) widget.document.filePaths[i],
  ];

  void _toggle(int index) {
    setState(() {
      if (!_selected.remove(index)) _selected.add(index);
    });
  }

  void _setSelectionMode(bool selectAll) {
    if (_selectAllMode == selectAll) return;
    setState(() {
      _selectAllMode = selectAll;
      if (selectAll) {
        _selected = {
          for (var i = 0; i < widget.document.filePaths.length; i++) i,
        };
      } else {
        _selected.clear();
      }
    });
    if (!selectAll && !_previewsStarted) {
      _previewsStarted = true;
      unawaited(_resolveAspectRatios());
    }
  }

  void _finish(ShareSheetAction action) {
    final paths = _selectedPaths;
    if (paths.isEmpty) {
      AppToastsUtils.warning(
        AppLocalizations.of(context).noFilesSelectedToast,
      );
      return;
    }
    Navigator.of(context).pop(ShareSheetResult(action: action, paths: paths));
  }

  /// A single file fills the sheet's width, like one big page preview; more
  /// than one falls back to a horizontal strip sized so about two tiles are
  /// visible at once (each still sized to its own file's aspect ratio) —
  /// either way every tile is sized far larger than a cropped filmstrip
  /// thumbnail so the page is actually legible, matching the reference.
  Widget _buildThumbnails(
    BuildContext context,
    AppLocalizations l10n,
    List<String> paths,
  ) {
    const horizontalPadding = 20.0;
    const tileGap = 10.0;

    if (paths.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            l10n.noPreviewAvailable,
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
        ),
      );
    }

    final screenSize = MediaQuery.sizeOf(context);
    final contentWidth = screenSize.width - horizontalPadding * 2;

    if (paths.length == 1) {
      final ratio = _aspectRatios[0] ?? _fallbackAspectRatio;
      final height = (contentWidth / ratio).clamp(
        140.0,
        screenSize.height * 0.28,
      );
      return Padding(
        padding: const .symmetric(horizontal: horizontalPadding),
        child: _ShareFileTile(
          path: paths[0],
          isSelected: _selected.contains(0),
          onTap: () => _toggle(0),
          width: contentWidth,
          height: height,
        ),
      );
    }

    final stripHeight = (screenSize.height * 0.4).clamp(160.0, 210.0);
    final maxTileWidth = contentWidth * 0.78;
    final minTileWidth = stripHeight * 0.45;

    return SizedBox(
      height: stripHeight,
      child: ListView.separated(
        scrollDirection: .horizontal,
        padding: const .symmetric(horizontal: horizontalPadding),
        itemCount: paths.length,
        separatorBuilder: (_, _) => widthBox(tileGap),
        itemBuilder: (context, index) {
          final ratio = _aspectRatios[index] ?? _fallbackAspectRatio;
          final width = (stripHeight * ratio).clamp(
            minTileWidth,
            maxTileWidth,
          );
          return _ShareFileTile(
            path: paths[index],
            isSelected: _selected.contains(index),
            onTap: () => _toggle(index),
            width: width,
            height: stripHeight,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paths = widget.document.filePaths;
    final enabled = _selected.isNotEmpty;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.share, style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                      const SizedBox(height: 4),
                      Text(widget.document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.selectAll),
                          icon: const Icon(Icons.done_all_rounded),
                        ),
                        const ButtonSegment(
                          value: false,
                          label: Text('Select Files'),
                          icon: Icon(Icons.checklist_rounded),
                        ),
                      ],
                      selected: {_selectAllMode},
                      onSelectionChanged: (values) =>
                          _setSelectionMode(values.single),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: context.primary,
                        selectedForegroundColor: colors.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    child: Text(
                      l10n.selectedCount(_selected.length),
                      style: context.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  if (!_selectAllMode) ...[
                    _buildThumbnails(context, l10n, paths),
                    const SizedBox(height: 20),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        _ShareOptionTile(
                          icon: Iconsax.document_forward,
                          label: l10n.shareAsPdfOption,
                          accent: colors.primary,
                          onTap: enabled ? () => _finish(ShareSheetAction.shareAsPdf) : null,
                        ),
                        _ShareOptionTile(
                          icon: Iconsax.gallery_export,
                          label: l10n.shareAsImagesOption,
                          accent: const Color(0xFF00897B),
                          onTap: enabled ? () => _finish(ShareSheetAction.shareAsImages) : null,
                        ),
                        _ShareOptionTile(
                          icon: Iconsax.document_copy,
                          label: l10n.exportEachPageAsPdfOption,
                          accent: const Color(0xFF7E57C2),
                          onTap: enabled ? () => _finish(ShareSheetAction.exportPagesAsPdf) : null,
                        ),
                        _ShareOptionTile(
                          icon: Iconsax.gallery_add,
                          label: l10n.saveToGalleryOption,
                          accent: const Color(0xFFBF6C10),
                          onTap: enabled ? () => _finish(ShareSheetAction.saveToGallery) : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The file's real width/height, as a ratio — an image is probed via its
/// own [FileImage] provider (Flutter's image cache keys on that provider,
/// so this doesn't cost a second decode on top of whatever later displays
/// the same file); a PDF has no such built-in widget, so that case just
/// asks pdfx for the page's own size. Returns null (caller falls back to a
/// default ratio) for anything unreadable rather than throwing.
Future<double?> _probeAspectRatio(String path) async {
  try {
    if (isImagePath(path)) {
      final stream = FileImage(File(path)).resolve(const ImageConfiguration());
      final completer = Completer<ImageInfo>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          completer.complete(info);
          stream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          completer.completeError(error, stackTrace);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      final info = await completer.future;
      final ratio = info.image.width / info.image.height;
      return (ratio.isFinite && ratio > 0) ? ratio : null;
    }
    if (isPdfPath(path)) {
      final document = await PdfDocument.openFile(path);
      final page = await document.getPage(1);
      final ratio = page.width / page.height;
      await page.close();
      await document.close();
      return (ratio.isFinite && ratio > 0) ? ratio : null;
    }
  } catch (_) {
    // Falls through to null — _ShareFileThumbnail's own fallback icon is
    // what actually shows for this file anyway.
  }
  return null;
}

/// One selectable file preview, sized to its caller's exact [width]/
/// [height] — see _ShareDocumentSheetState._buildThumbnails for how those
/// are computed from the file's own aspect ratio.
class _ShareFileTile extends StatelessWidget {
  final String path;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _ShareFileTile({
    required this.path,
    required this.isSelected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  // The border lives on the outer Container's decoration, which paints
  // *behind* its child by default — an edge-to-edge thumbnail would just
  // paint over it. Padding (equal to the border width) between that
  // Container and the inner ClipRRect keeps a visible ring around the
  // thumbnail instead of being covered by it.
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isSelected ? 1 : 0.4,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          padding: const .all(_borderWidth),
          decoration: BoxDecoration(
            borderRadius: .circular(12),
            border: Border.all(
              color: isSelected ? context.primary : context.border,
              width: _borderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: .circular(12 - _borderWidth),
            child: Stack(
              fit: .expand,
              children: [
                _ShareFileThumbnail(path: path),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: .center,
                      decoration: BoxDecoration(
                        color: context.primary,
                        shape: .circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: context.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ShareFileThumbnail extends StatelessWidget {
  final String path;

  const _ShareFileThumbnail({required this.path});

  Widget _fallback(BuildContext context) => ColoredBox(
    color: context.surface,
    child: Icon(Iconsax.document_text, color: context.textSecondary),
  );

  @override
  Widget build(BuildContext context) {
    if (isImagePath(path)) {
      return Image.file(
        File(path),
        // .contain, not .cover — the tile's own aspect ratio already
        // matches the file's (see _ShareFileTileState), so this only
        // matters while that's still resolving, and contain guarantees
        // nothing is ever cropped off a page in the meantime.
        fit: .contain,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }
    if (isPdfPath(path)) {
      return PdfPageThumbnail(
        path: path,
        fit: .contain,
        fallback: _fallback(context),
      );
    }
    return _fallback(context);
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: context.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 24, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: context.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                  color: context.textSecondary, size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
