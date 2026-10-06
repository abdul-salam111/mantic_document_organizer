import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../domain/entities/document_item.dart';

/// Android package names for the apps shown directly in the share row — see
/// [DirectShareService] for how these turn into a real direct-to-app share
/// (with an OS-share-sheet fallback on anything that isn't Android or
/// doesn't have the app installed).
const String _whatsAppPackage = 'com.whatsapp';
const String _gmailPackage = 'com.google.android.gm';
const String _drivePackage = 'com.google.android.apps.docs';
const String _messengerPackage = 'com.facebook.orca';

enum ShareSheetAction {
  directApp,
  osShareSheet,
  shareAsPdf,
  shareAsImages,
  exportPagesAsPdf,
  saveToGallery,
}

class ShareSheetResult {
  final ShareSheetAction action;
  final List<String> paths;
  final String? packageName;

  const ShareSheetResult({
    required this.action,
    required this.paths,
    this.packageName,
  });
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

  @override
  void initState() {
    super.initState();
    _resolveAspectRatios();
  }

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

  bool get _allSelected =>
      widget.document.filePaths.isNotEmpty &&
      _selected.length == widget.document.filePaths.length;

  void _toggle(int index) {
    setState(() {
      if (!_selected.remove(index)) _selected.add(index);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected = {
          for (var i = 0; i < widget.document.filePaths.length; i++) i,
        };
      }
    });
  }

  void _finish(ShareSheetAction action, {String? packageName}) {
    final paths = _selectedPaths;
    if (paths.isEmpty) {
      AppToastsUtils.warning(
        AppLocalizations.of(context).noFilesSelectedToast,
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(ShareSheetResult(action: action, paths: paths, packageName: packageName));
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

    return SafeArea(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.document.title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.titleMedium.copyWith(fontWeight: .bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // A single full-width thumbnail can run up to 42% of the screen
          // height (see _buildThumbnails) — combined with the share-apps
          // row and four option tiles below, that can exceed the sheet's
          // own maxHeight on a short screen. Expanded+SingleChildScrollView
          // lets everything past the title bar scroll instead of overflow
          // (also keeps the sheet filling its full-screen allowance, like a
          // real full-screen sheet, instead of shrinking to fit a single
          // small file).
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Padding(
                    padding: const .symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          l10n.selectedCount(_selected.length),
                          style: context.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: paths.isEmpty ? null : _toggleSelectAll,
                          child: Text(
                            _allSelected ? l10n.deselectAll : l10n.selectAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                  heightBox(4),
                  _buildThumbnails(context, l10n, paths),
                  heightBox(12),
                  Divider(height: 1, color: context.divider),
                  heightBox(12),
                  Padding(
                    padding: const .symmetric(horizontal: 14),
                    child: Text(
                      l10n.share,
                      style: context.titleSmall.copyWith(fontWeight: .bold),
                    ),
                  ),
                  heightBox(12),
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: .horizontal,
                      padding: const .symmetric(horizontal: 6),
                      children: [
                        _ShareAppIcon(
                          iconAsset: AppIcons.whatsapp,
                          label: 'WhatsApp',
                          onTap: () => _finish(
                            .directApp,
                            packageName: _whatsAppPackage,
                          ),
                        ),
                        widthBox(16),
                        _ShareAppIcon(
                          iconAsset: AppIcons.gmail,
                          label: 'Gmail',
                          onTap: () =>
                              _finish(.directApp, packageName: _gmailPackage),
                        ),
                        widthBox(16),
                        _ShareAppIcon(
                          iconAsset: AppIcons.drive,
                          label: 'Drive',
                          onTap: () =>
                              _finish(.directApp, packageName: _drivePackage),
                        ),
                        widthBox(16),
                        _ShareAppIcon(
                          iconAsset: AppIcons.messenger,
                          label: 'Messenger',
                          onTap: () => _finish(
                            .directApp,
                            packageName: _messengerPackage,
                          ),
                        ),
                        widthBox(16),
                        _ShareAppIcon(
                          icon: FontAwesomeIcons.ellipsis,
                          color: context.textSecondary,
                          label: l10n.shareViaMore,
                          onTap: () => _finish(.osShareSheet),
                        ),
                      ],
                    ),
                  ),
                  heightBox(16),
                  Divider(height: 1, color: context.divider),
                  heightBox(8),
                  _ShareOptionTile(
                    // document + forward-arrow reads as "share this
                    // document" more clearly than the old document_download.
                    icon: Iconsax.document_forward,
                    label: l10n.shareAsPdfOption,
                    onTap: () => _finish(.shareAsPdf),
                  ),
                  _ShareOptionTile(
                    // gallery + export-arrow reads as "send images out of
                    // the gallery" more clearly than the old plain image.
                    icon: Iconsax.gallery_export,
                    label: l10n.shareAsImagesOption,
                    onTap: () => _finish(.shareAsImages),
                  ),
                  _ShareOptionTile(
                    icon: Iconsax.document_copy,
                    label: l10n.exportEachPageAsPdfOption,
                    onTap: () => _finish(.exportPagesAsPdf),
                  ),
                  _ShareOptionTile(
                    icon: Iconsax.gallery_add,
                    label: l10n.saveToGalleryOption,
                    onTap: () => _finish(.saveToGallery),
                  ),
                  heightBox(8),
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

/// One tappable app target in the share row. Either an [iconAsset] (a
/// transparent-background app logo PNG, shown at its own natural shape with
/// no extra wrapper) or an [icon]+[color] pair (a FontAwesome glyph inside a
/// tinted circle, used for the "more" overflow entry, which has no brand
/// logo of its own).
class _ShareAppIcon extends StatelessWidget {
  final String? iconAsset;
  final FaIconData? icon;
  final Color? color;
  final String label;
  final VoidCallback onTap;

  const _ShareAppIcon({
    this.iconAsset,
    this.icon,
    this.color,
    required this.label,
    required this.onTap,
  }) : assert(
         iconAsset != null || (icon != null && color != null),
         'Provide either iconAsset or both icon and color',
       );

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: .circular(32),
    child: SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: .min,
        children: [
          SizedBox(
            width: 35,
            height: 35,
            child: iconAsset != null
                ? Image.asset(iconAsset!, fit: .contain)
                : Container(
                    alignment: .center,
                    decoration: BoxDecoration(
                      color: color!.withValues(alpha: 0.12),
                      shape: .circle,
                    ),
                    child: FaIcon(icon, color: color, size: 22),
                  ),
          ),
          heightBox(6),
          Text(
            label,
            maxLines: 1,
            overflow: .ellipsis,
            textAlign: .center,
            style: context.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const .symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.textPrimary),
          widthBox(16),
          Expanded(child: Text(label, style: context.bodyMedium)),
        ],
      ),
    ),
  );
}
