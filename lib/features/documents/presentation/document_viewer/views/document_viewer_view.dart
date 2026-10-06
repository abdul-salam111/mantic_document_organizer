import 'package:mantic_doc_org/core/utils/persist_action.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart';
import '../viewmodels/document_viewer_viewmodel.dart';
import 'share_document_sheet.dart';

enum _DocumentAction { exportPdf, delete }

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
                  onPressed: () => persistAction(context, vm.toggleFavorite),
                ),
                PopupMenuButton<_DocumentAction>(
                  icon: Icon(Iconsax.more, color: context.white),
                  onSelected: (action) =>
                      _handleAction(context, vm, current, action),
                  itemBuilder: (context) => [
                    if (current.filePaths.any(isImagePath))
                      PopupMenuItem(
                        value: _DocumentAction.exportPdf,
                        child: _MenuRow(
                          icon: Iconsax.document_download,
                          label: AppLocalizations.of(context).exportAsPdf,
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
              child: _PageArea(
                document: current,
                onAddFiles: () => _openScannerForDocument(current),
              ),
            ),
            bottomNavigationBar: _DocumentActionBar(
              onAdd: () => _openScannerForDocument(current),
              onEdit: () => _openEditor(current),
              onShare: () => _openShareSheet(context, vm, current),
              onMove: () {
                _showMovePicker(context, vm, current);
              },
              onRename: () {
                _showRenameSheet(context, vm, current);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
    _DocumentAction action,
  ) {
    switch (action) {
      case _DocumentAction.exportPdf:
        return persistAction(context, () => vm.exportPdf(current)).then((_) {});
      case _DocumentAction.delete:
        return _confirmDelete(context, vm, current);
    }
  }

  void _openEditor(DocumentItem document) {
    AppNavigator.pushNamed(RouteNames.addDocument, extra: document);
  }

  void _openScannerForDocument(DocumentItem document) {
    AppNavigator.pushNamed(RouteNames.addDocument, extra: (document, true));
  }

  Future<void> _openShareSheet(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
  ) async {
    final result = await showModalBottomSheet<ShareSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      builder: (_) => ShareDocumentSheet(document: current),
    );
    if (result == null || !context.mounted) return;

    switch (result.action) {
      case ShareSheetAction.directApp:
        await persistAction(
          context,
          () => vm.shareDirect(result.paths, result.packageName!),
        );
      case ShareSheetAction.osShareSheet:
        await persistAction(context, () => vm.shareFiles(result.paths));
      case ShareSheetAction.shareAsPdf:
        await persistAction(
          context,
          () => vm.shareSelectedAsPdf(result.paths, current.title),
        );
      case ShareSheetAction.shareAsImages:
        await persistAction(
          context,
          () => vm.shareSelectedAsImages(result.paths),
        );
      case ShareSheetAction.exportPagesAsPdf:
        await persistAction(
          context,
          () => vm.exportSelectedPagesAsPdf(result.paths, current.title),
        );
      case ShareSheetAction.saveToGallery:
        final saved = await persistAction(
          context,
          () => vm.saveSelectedToGallery(result.paths),
        );
        if (saved && context.mounted) {
          AppToastsUtils.success(
            AppLocalizations.of(context).savedToGalleryToast,
          );
        }
    }
  }

  Future<void> _showRenameSheet(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
  ) async {
    final newTitle = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RenameDocumentSheet(initialTitle: current.title),
    );
    if (newTitle == null || !context.mounted) return;
    if (!await persistAction(context, () => vm.rename(newTitle))) return;
    if (!context.mounted) return;
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
    if (!await persistAction(context, () => vm.moveToCategory(picked))) return;
    if (!context.mounted) return;
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
          AppLocalizations.of(context).deleteDocumentConfirm(
            current.title,
            DocumentUseCases.trashRetentionPeriod.inDays,
          ),
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
    if (!await persistAction(context, () => vm.delete())) return;
    if (!context.mounted) return;
    AppNavigator.pop();
    AppToastsUtils.success(
      AppLocalizations.of(context).documentTrashedToast(current.title),
    );
  }
}

class _RenameDocumentSheet extends StatefulWidget {
  const _RenameDocumentSheet({required this.initialTitle});

  final String initialTitle;

  @override
  State<_RenameDocumentSheet> createState() => _RenameDocumentSheetState();
}

class _RenameDocumentSheetState extends State<_RenameDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          heightBox(20),
          Text(
            AppLocalizations.of(context).renameDocument,
            style: context.titleLarge.copyWith(fontWeight: .bold),
          ),
          heightBox(6),
          Text(
            'Choose a clear name so you can find this document later.',
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
          heightBox(20),
          Form(
            key: _formKey,
            child: CustomTextFormField(
              label: AppLocalizations.of(context).documentTitleLabel,
              hintText: AppLocalizations.of(context).documentTitleHint,
              controller: _controller,
              isRequired: true,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? AppLocalizations.of(context).documentTitleRequired
                  : null,
            ),
          ),
          heightBox(20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ),
              widthBox(12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primary,
                  ),
                  child: Text(AppLocalizations.of(context).save),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
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

/// Scanner-style actions remain available while the user reads attachments.
class _DocumentActionBar extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onMove;
  final VoidCallback onRename;

  const _DocumentActionBar({
    required this.onAdd,
    required this.onEdit,
    required this.onShare,
    required this.onMove,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          border: Border(top: BorderSide(color: context.border)),
        ),
        child: Row(
          children: [
            _DocumentActionItem(
              icon: Icons.add_a_photo_outlined,
              label: l10n.add,
              onTap: onAdd,
            ),
            _DocumentActionItem(
              icon: Iconsax.edit_2,
              label: l10n.edit,
              onTap: onEdit,
            ),
            _DocumentActionItem(
              icon: Iconsax.share,
              label: l10n.share,
              onTap: onShare,
            ),
            _DocumentActionItem(
              icon: Iconsax.category,
              label: l10n.move,
              onTap: onMove,
            ),
            _DocumentActionItem(
              icon: Iconsax.edit,
              label: l10n.rename,
              onTap: onRename,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DocumentActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: context.textPrimary),
            heightBox(5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.labelSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shows each attachment directly in one vertical list with a sticky counter
/// for the file currently at the top of the viewport.
class _PageArea extends StatefulWidget {
  final DocumentItem document;
  final VoidCallback onAddFiles;

  const _PageArea({required this.document, required this.onAddFiles});

  @override
  State<_PageArea> createState() => _PageAreaState();
}

class _PageAreaState extends State<_PageArea> {
  final _scrollController = ScrollController();
  final _listKey = GlobalKey();
  late List<GlobalKey> _fileKeys = _keysFor(widget.document.filePaths.length);
  int _currentFile = 0;
  final Set<int> _selectedFiles = {};

  static List<GlobalKey> _keysFor(int count) =>
      List.generate(count, (_) => GlobalKey(), growable: false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCurrentFile);
  }

  @override
  void didUpdateWidget(covariant _PageArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.filePaths != widget.document.filePaths) {
      _fileKeys = _keysFor(widget.document.filePaths.length);
      _currentFile = 0;
      _selectedFiles.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateCurrentFile());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateCurrentFile)
      ..dispose();
    super.dispose();
  }

  void _toggleFileSelection(int index) {
    setState(() {
      if (!_selectedFiles.add(index)) _selectedFiles.remove(index);
    });
  }

  void _updateCurrentFile() {
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || listBox == null) return;

    for (var index = 0; index < _fileKeys.length; index++) {
      final fileBox =
          _fileKeys[index].currentContext?.findRenderObject() as RenderBox?;
      if (fileBox == null) continue;
      final top = fileBox.localToGlobal(Offset.zero, ancestor: listBox).dy;
      if (top + fileBox.size.height > 0) {
        if (_currentFile != index) setState(() => _currentFile = index);
        return;
      }
    }
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

    // Pinch-zoom lives in FilePreviewView (opened via onOpenPreview below),
    // not here — this list previously also wrapped itself in its own
    // InteractiveViewer to zoom in place, but that nested a nested-scrollable
    // (ListView) and nested tap targets (_SelectableFilePreview's
    // GestureDetector) inside it, so the pinch gesture's arena mostly
    // resolved to those instead of the zoom: it only actually zoomed when
    // pinching off a file (empty list space), never on one.
    return Stack(
      children: [
        ListView.separated(
          key: _listKey,
          controller: _scrollController,
          padding: const .fromLTRB(14, 14, 14, 24),
          itemCount: paths.length + 1,
          separatorBuilder: (_, _) => heightBox(14),
          itemBuilder: (context, index) => index == paths.length
              ? _AddFilesButton(onTap: widget.onAddFiles)
              : KeyedSubtree(
                  key: _fileKeys[index],
                  child: _SelectableFilePreview(
                    path: paths[index],
                    isSelected: _selectedFiles.contains(index),
                    selectionActive: _selectedFiles.isNotEmpty,
                    onToggle: () => _toggleFileSelection(index),
                    onOpenPreview: () => AppNavigator.pushNamed(
                      RouteNames.filePreview,
                      extra: (widget.document.filePaths, index),
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: IgnorePointer(
            child: _FileCounter(current: _currentFile + 1, total: paths.length),
          ),
        ),
      ],
    );
  }
}

class _FileCounter extends StatelessWidget {
  final int current;
  final int total;

  const _FileCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => Container(
    padding: const .symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: context.black.withValues(alpha: 0.65),
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

class _AddFilesButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFilesButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: context.surface,
    child: InkWell(
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: _DottedRoundedBorderPainter(color: context.border),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 20,
                color: context.textSecondary,
              ),
              widthBox(8),
              Text(
                AppLocalizations.of(context).addFiles,
                style: context.bodySmall.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DottedRoundedBorderPainter extends CustomPainter {
  final Color color;

  const _DottedRoundedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.zero));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 9) {
        canvas.drawPath(
          metric.extractPath(offset, (offset + 5).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SelectableFilePreview extends StatelessWidget {
  final String path;
  final bool isSelected;
  final bool selectionActive;
  final VoidCallback onToggle;
  final VoidCallback onOpenPreview;

  const _SelectableFilePreview({
    required this.path,
    required this.isSelected,
    required this.selectionActive,
    required this.onToggle,
    required this.onOpenPreview,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: onToggle,
    onTap: selectionActive ? onToggle : onOpenPreview,
    child: Stack(
      children: [
        _FilePreview(path: path),
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: context.primary.withValues(alpha: 0.16)),
            ),
          ),
        if (isSelected)
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: Container(
                width: 28,
                height: 28,
                alignment: .center,
                decoration: BoxDecoration(
                  color: context.primary,
                  shape: .circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: context.white,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _FilePreview extends StatelessWidget {
  final String path;

  const _FilePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    if (isImagePath(path)) {
      return Image.file(
        File(path),
        width: double.infinity,
        fit: .fitWidth,
        errorBuilder: (context, error, stackTrace) =>
            _UnsupportedPreview(path: path),
      );
    }
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: _PagePreview(path: path),
    );
  }
}

class _PagePreview extends StatelessWidget {
  final String path;

  const _PagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    if (isPdfPath(path)) {
      return PdfZoomView(path: path, fallback: _UnsupportedPreview(path: path));
    }
    if (!isImagePath(path)) return _UnsupportedPreview(path: path);
    return InteractiveViewer(
      panEnabled: false,
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
              onPressed: () => persistAction(
                context,
                () => context.read<DocumentViewerViewModel>().shareFile(path),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
