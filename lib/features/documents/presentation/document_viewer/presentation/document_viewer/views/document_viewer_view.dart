import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../../../core/di/di_exports.dart';
import '../../../../../../../core/localization/localization_exports.dart';
import '../../../../../../../core/theme/theme_exports.dart';
import '../../../../../../../core/utils/utils_exports.dart';
import '../../../../../../../core/widgets/widgets_exports.dart';
import '../../../../../../../routes/routes_exports.dart';
import '../../../../../../home/home_exports.dart';
import '../viewmodels/document_viewer_viewmodel.dart';

enum _DocumentAction { edit, share, rename, move, delete }

class DocumentViewerView extends StatelessWidget {
  final DocumentItem document;

  const DocumentViewerView({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = sl<DocumentViewerViewModel>();
        vm.init(document);
        return vm;
      },
      child: Consumer<DocumentViewerViewModel>(
        builder: (context, vm, _) {
          final current = vm.document;
          // Deleted (by this screen or elsewhere) between frames — nothing
          // sensible to show; the delete action itself already pops.
          if (current == null) return const SizedBox.shrink();

          final color = categoryIconColor(context, current.category);
          return Scaffold(
            appBar: CustomAppBar(
              title: current.title,
              actions: [
                IconButton(
                  tooltip: current.isFavorite
                      ? AppLocalizations.of(context).removeFromFavorites
                      : AppLocalizations.of(context).addToFavorites,
                  icon: Icon(
                    current.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                    color: current.isFavorite
                        ? context.errorAccent
                        : context.white,
                  ),
                  onPressed: vm.toggleFavorite,
                ),
                PopupMenuButton<_DocumentAction>(
                  icon: Icon(Iconsax.more, color: context.white),
                  onSelected: (action) =>
                      _handleAction(context, vm, current, action),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _DocumentAction.edit,
                      child: _MenuRow(
                        icon: Iconsax.edit,
                        label: AppLocalizations.of(context).editDocumentTitle,
                      ),
                    ),
                    if (current.filePaths.isNotEmpty)
                      PopupMenuItem(
                        value: _DocumentAction.share,
                        child: _MenuRow(
                          icon: Iconsax.share,
                          label: AppLocalizations.of(context).share,
                        ),
                      ),
                    PopupMenuItem(
                      value: _DocumentAction.rename,
                      child: _MenuRow(
                        icon: Iconsax.edit_2,
                        label: AppLocalizations.of(context).rename,
                      ),
                    ),
                    PopupMenuItem(
                      value: _DocumentAction.move,
                      child: _MenuRow(
                        icon: Iconsax.category,
                        label: AppLocalizations.of(context).move,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: _DocumentAction.delete,
                      child: _MenuRow(
                        icon: Iconsax.trash,
                        label: AppLocalizations.of(context).delete,
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _PageArea(vm: vm, document: current),
                  ),
                  _DocumentInfoPanel(document: current, color: color),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareAll(DocumentItem current) {
    return SharePlus.instance.share(
      ShareParams(files: [for (final path in current.filePaths) XFile(path)]),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
    _DocumentAction action,
  ) {
    switch (action) {
      case _DocumentAction.edit:
        AppNavigator.pushNamed(RouteNames.addDocument, extra: current);
        return Future.value();
      case _DocumentAction.share:
        return _shareAll(current);
      case _DocumentAction.rename:
        return _showRenameDialog(context, vm, current);
      case _DocumentAction.move:
        return _showMovePicker(context, vm, current);
      case _DocumentAction.delete:
        return _confirmDelete(context, vm, current);
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
  ) async {
    final controller = TextEditingController(text: current.title);
    final formKey = GlobalKey<FormState>();
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: .circular(20)),
        titlePadding: const .fromLTRB(24, 24, 24, 4),
        contentPadding: const .fromLTRB(24, 12, 24, 8),
        title: Text(
          AppLocalizations.of(context).renameDocument,
          style: context.titleMedium.copyWith(fontWeight: .bold),
        ),
        content: Form(
          key: formKey,
          child: CustomTextFormField(
            label: AppLocalizations.of(context).documentTitleLabel,
            hintText: AppLocalizations.of(context).documentTitleHint,
            controller: controller,
            isRequired: true,
            autofocus: true,
            textCapitalization: .sentences,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? AppLocalizations.of(context).documentTitleRequired
                : null,
          ),
        ),
        actionsPadding: const .fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.primary,
              shape: RoundedRectangleBorder(borderRadius: .circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle == null || !context.mounted) return;
    vm.rename(newTitle);
    AppToastsUtils.success(
      AppLocalizations.of(context).documentRenamedToast(newTitle),
    );
  }

  Future<void> _showMovePicker(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
  ) async {
    CategoryItem? selected;
    for (final category in vm.categories) {
      if (category.id == current.categoryId) {
        selected = category;
        break;
      }
    }
    final picked = await showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          CategoryPickerSheet(categories: vm.categories, selected: selected),
    );
    if (picked == null || !context.mounted) return;
    vm.moveToCategory(picked);
    AppToastsUtils.success(
      AppLocalizations.of(context).documentMovedToast(picked.name),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: Text(AppLocalizations.of(context).deleteDocument),
        content: Text(
          AppLocalizations.of(context).deleteDocumentConfirm(current.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppLocalizations.of(context).delete,
              style: TextStyle(color: context.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    vm.delete();
    AppNavigator.pop();
    AppToastsUtils.success(
      AppLocalizations.of(context).documentDeletedToast(current.title),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? context.errorAccent : context.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        widthBox(10),
        Text(label, style: context.bodyMedium.copyWith(color: color)),
      ],
    );
  }
}

/// Owns the [PageController] so the page view and thumbnail strip below it
/// share one source of truth for the current page — a thumbnail tap
/// animates the same controller the swipe gesture drives.
class _PageArea extends StatefulWidget {
  final DocumentViewerViewModel vm;
  final DocumentItem document;

  const _PageArea({required this.vm, required this.document});

  @override
  State<_PageArea> createState() => _PageAreaState();
}

class _PageAreaState extends State<_PageArea> {
  late final PageController _controller = PageController(
    initialPage: widget.vm.pageIndex,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.document.filePaths;

    if (paths.isEmpty) {
      return EmptyStateWidget(
        icon: Iconsax.document_text,
        title: AppLocalizations.of(context).noPreviewAvailable,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: paths.length,
                onPageChanged: widget.vm.setPageIndex,
                itemBuilder: (context, index) =>
                    _PagePreview(path: paths[index]),
              ),
              if (paths.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _PageCounterBadge(
                    current: widget.vm.pageIndex + 1,
                    total: paths.length,
                  ),
                ),
            ],
          ),
        ),
        if (paths.length > 1) ...[
          heightBox(10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: .horizontal,
              padding: const .symmetric(horizontal: 14),
              itemCount: paths.length,
              separatorBuilder: (context, index) => widthBox(8),
              itemBuilder: (context, index) => _Thumbnail(
                path: paths[index],
                isSelected: index == widget.vm.pageIndex,
                onTap: () => _jumpTo(index),
              ),
            ),
          ),
          heightBox(10),
        ],
      ],
    );
  }
}

class _PagePreview extends StatelessWidget {
  final String path;

  const _PagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    if (isPdfPath(path)) return _PdfPreview(path: path);
    if (!isImagePath(path)) return _UnsupportedPreview(path: path);
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.file(
          File(path),
          fit: .contain,
          errorBuilder: (context, error, stackTrace) =>
              _UnsupportedPreview(path: path),
        ),
      ),
    );
  }
}

/// Renders a PDF inline (pinch-zoom, swipe between its own internal pages)
/// instead of falling back to [_UnsupportedPreview] — the one non-image
/// attachment type this screen can actually preview rather than just
/// share out. Owns a [PdfControllerPinch] so it can dispose the underlying
/// document when the page is swiped away.
class _PdfPreview extends StatefulWidget {
  final String path;

  const _PdfPreview({required this.path});

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
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
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error) =>
            _UnsupportedPreview(path: widget.path),
      ),
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  final String path;

  const _UnsupportedPreview({required this.path});

  String get _fileName => path.replaceAll('\\', '/').split('/').last;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const .all(24),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(Iconsax.document_text, size: 56, color: context.textSecondary),
            heightBox(12),
            Text(
              _fileName,
              textAlign: .center,
              maxLines: 2,
              overflow: .ellipsis,
              style: context.bodyMedium.copyWith(fontWeight: .w600),
            ),
            heightBox(6),
            Text(
              AppLocalizations.of(context).noPreviewAvailable,
              textAlign: .center,
              style: context.labelSmall.copyWith(color: context.textSecondary),
            ),
            heightBox(16),
            CustomButton(
              text: AppLocalizations.of(context).share,
              radius: 10,
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(files: [XFile(path)])),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;
  final bool isSelected;
  final VoidCallback onTap;

  const _Thumbnail({
    required this.path,
    required this.isSelected,
    required this.onTap,
  });

  Widget _fallback(BuildContext context) => Container(
    color: context.background,
    alignment: .center,
    child: Icon(Iconsax.document, size: 20, color: context.textSecondary),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(10),
      child: Container(
        width: 52,
        height: 52,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: .circular(10),
          border: Border.all(
            color: isSelected ? context.primary : context.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isImagePath(path)
            ? Image.file(
                File(path),
                fit: .cover,
                errorBuilder: (context, error, stackTrace) =>
                    _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }
}

class _PageCounterBadge extends StatelessWidget {
  final int current;
  final int total;

  const _PageCounterBadge({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.black.withValues(alpha: 0.6),
        borderRadius: .circular(20),
      ),
      child: Text(
        '$current / $total',
        style: context.labelSmall.copyWith(
          color: context.white,
          fontWeight: .w600,
        ),
      ),
    );
  }
}

class _DocumentInfoPanel extends StatelessWidget {
  final DocumentItem document;
  final Color color;

  const _DocumentInfoPanel({required this.document, required this.color});

  bool get _showExpiryChip =>
      document.isExpirable && document.expiryDate != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const .fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        border: Border(top: BorderSide(color: context.divider)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: .center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: .circular(8),
                ),
                child: FaIcon(document.icon, size: 14, color: color),
              ),
              widthBox(8),
              Expanded(
                child: Text(
                  document.category,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: context.bodyMedium.copyWith(fontWeight: .w600),
                ),
              ),
              Text(
                AppLocalizations.of(
                  context,
                ).fileCount(document.filePaths.length),
                style: context.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          heightBox(4),
          Text(
            AppLocalizations.of(context).addedOn(document.createdAt.formatted),
            style: context.labelSmall.copyWith(color: context.textSecondary),
          ),
          if (document.tags.isNotEmpty || _showExpiryChip) ...[
            heightBox(10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_showExpiryChip)
                  ExpiryChip(expiryDate: document.expiryDate!),
                for (final tag in document.tags) TagChip(tag: tag),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
