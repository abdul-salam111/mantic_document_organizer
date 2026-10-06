import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../domain/entities/document_item.dart';

/// Android package names for the two apps shown directly in the share row —
/// see [DirectShareService] for how these turn into a real direct-to-app
/// share (with an OS-share-sheet fallback on anything that isn't Android or
/// doesn't have the app installed).
const String _whatsAppPackage = 'com.whatsapp';
const String _gmailPackage = 'com.google.android.gm';

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
  late Set<int> _selected = {
    for (var i = 0; i < widget.document.filePaths.length; i++) i,
  };

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paths = widget.document.filePaths;

    return SafeArea(
      child: Column(
        mainAxisSize: .min,
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
                  child: Text(_allSelected ? l10n.deselectAll : l10n.selectAll),
                ),
              ],
            ),
          ),
          heightBox(4),
          SizedBox(
            height: 170,
            child: paths.isEmpty
                ? Center(
                    child: Text(
                      l10n.noPreviewAvailable,
                      style: context.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: .horizontal,
                    padding: const .symmetric(horizontal: 20),
                    itemCount: paths.length,
                    separatorBuilder: (_, _) => widthBox(10),
                    itemBuilder: (context, index) => _ShareFileTile(
                      path: paths[index],
                      isSelected: _selected.contains(index),
                      onTap: () => _toggle(index),
                    ),
                  ),
          ),
          heightBox(16),
          Divider(height: 1, color: context.divider),
          heightBox(16),
          Padding(
            padding: const .symmetric(horizontal: 20),
            child: Text(
              l10n.share,
              style: context.titleSmall.copyWith(fontWeight: .bold),
            ),
          ),
          heightBox(12),
          Padding(
            padding: const .symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: .start,
              children: [
                _ShareAppIcon(
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF25D366),
                  label: 'WhatsApp',
                  onTap: () => _finish(
                    .directApp,
                    packageName: _whatsAppPackage,
                  ),
                ),
                widthBox(20),
                _ShareAppIcon(
                  icon: FontAwesomeIcons.envelope,
                  color: const Color(0xFFEA4335),
                  label: 'Gmail',
                  onTap: () =>
                      _finish(.directApp, packageName: _gmailPackage),
                ),
                widthBox(20),
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
            icon: Iconsax.document_download,
            label: l10n.shareAsPdfOption,
            onTap: () => _finish(.shareAsPdf),
          ),
          _ShareOptionTile(
            icon: Iconsax.image,
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
    );
  }
}

class _ShareFileTile extends StatelessWidget {
  final String path;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShareFileTile({
    required this.path,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isSelected ? 1 : 0.4,
      child: Container(
        width: 120,
        clipBehavior: .antiAlias,
        decoration: BoxDecoration(
          borderRadius: .circular(12),
          border: Border.all(
            color: isSelected ? context.primary : context.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: .expand,
          children: [
            _ShareFileThumbnail(path: path),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: .center,
                  decoration: BoxDecoration(
                    color: context.primary,
                    shape: .circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: context.white,
                  ),
                ),
              ),
          ],
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
        fit: .cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }
    if (isPdfPath(path)) {
      return PdfPageThumbnail(path: path, fallback: _fallback(context));
    }
    return _fallback(context);
  }
}

class _ShareAppIcon extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ShareAppIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: .circular(32),
    child: SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: .center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: .circle,
            ),
            child: FaIcon(icon, color: color, size: 22),
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
      padding: const .symmetric(horizontal: 20, vertical: 14),
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
