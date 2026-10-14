import 'package:mantic_doc_org/core/utils/persist_action.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart';
import '../../add_document/add_document_exports.dart';
import '../viewmodels/document_viewer_viewmodel.dart';
import 'file_page_hero.dart';
import 'share_document_sheet.dart';

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
            appBar: vm.isSelecting
                ? SelectionAppBar(
                    count: vm.selectedCount,
                    onClose: vm.clearSelection,
                    onDelete: () =>
                        _confirmDeleteSelectedFiles(context, vm, current),
                  )
                : CustomAppBar(
                    title: current.title,
                    onBackPressed: () => Navigator.of(context).pop(),
                    backgroundColor: context.background,
                    foregroundColor: context.textPrimary,
                    actions: [
                      IconButton(
                        tooltip: current.isFavorite
                            ? AppLocalizations.of(context).removeFromFavorites
                            : AppLocalizations.of(context).addToFavorites,
                        icon: Icon(
                          current.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                          color: current.isFavorite
                              ? context.errorAccent
                              : context.textPrimary,
                        ),
                        onPressed: () =>
                            persistAction(context, vm.toggleFavorite),
                      ),
                    ],
                  ),
            body: SafeArea(
              child: _PageArea(
                document: current,
                selectedPaths: vm.selectedPaths,
                onToggleSelection: vm.toggleFileSelection,
              ),
            ),
            bottomNavigationBar: _DocumentActionBar(
              canEdit: vm.canEditCurrentDocument,
              onAdd: () => _promptAddPages(context, vm),
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

  /// Deletes the selected pages. If that's every page the document has,
  /// deleting them trashes the whole document instead (same rule
  /// [DocumentViewerViewModel.deleteSelectedFiles] enforces) — handled here
  /// too so the confirm dialog's wording and the follow-up toast/navigation
  /// match which of those actually happened.
  Future<void> _confirmDeleteSelectedFiles(
    BuildContext context,
    DocumentViewerViewModel vm,
    DocumentItem current,
  ) async {
    final count = vm.selectedCount;
    final deletesWholeDocument = count >= current.filePaths.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: Text(AppLocalizations.of(context).delete),
        content: Text(
          deletesWholeDocument
              ? AppLocalizations.of(context).deleteDocumentConfirm(
                  current.title,
                  DocumentUseCases.trashRetentionPeriod.inDays,
                )
              : AppLocalizations.of(context).deleteSelectedFilesConfirm(count),
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
    if (!await persistAction(context, vm.deleteSelectedFiles)) return;
    if (!context.mounted) return;
    if (deletesWholeDocument) {
      AppNavigator.pop();
      AppToastsUtils.success(
        AppLocalizations.of(context).documentTrashedToast(current.title),
      );
    } else {
      AppToastsUtils.success(
        AppLocalizations.of(context).selectedFilesDeletedToast(count),
      );
    }
  }

  void _openEditor(DocumentItem document) {
    AppNavigator.pushNamed(RouteNames.addDocument, extra: document);
  }

  /// Asks where the new page's file should come from, then picks and saves
  /// it straight onto this document — deliberately not routed through the
  /// full Add Document form (unlike the navbar's "+" button, which has no
  /// existing document to attach to): the user is already looking at this
  /// document and just wants more pages on it, with a minimum of taps.
  Future<void> _promptAddPages(
    BuildContext context,
    DocumentViewerViewModel vm,
  ) async {
    final source = await AttachmentSourceSheet.show(context);
    if (source == null || !context.mounted) return;

    showLoadingPopup(
      context,
      message: AppLocalizations.of(context).addingPagesMessage,
    );
    AttachmentSelection? selection;
    try {
      selection = await vm.addPages(source);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'document actions',
        ),
      );
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (selection == null) {
      AppToastsUtils.error(
        source == .gallery
            ? AppLocalizations.of(context).galleryImportFailedToast
            : AppLocalizations.of(context).operationFailedToast,
      );
    } else if (selection.galleryFailed) {
      AppToastsUtils.error(
        AppLocalizations.of(context).galleryImportFailedToast,
      );
    } else if (selection.scanFailed) {
      AppToastsUtils.error(AppLocalizations.of(context).scanFailedToast);
    } else if (selection.skippedImages) {
      AppToastsUtils.warning(
        AppLocalizations.of(context).filesImagesNotAllowed,
      );
    }
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
      case ShareSheetAction.osShareSheet:
        final dismiss = showLoadingPopup(
          context,
          message: AppLocalizations.of(context).preparingPdfMessage,
        );
        try {
          await persistAction(context, () => vm.shareFiles(result.paths));
        } finally {
          await dismiss();
        }

      case ShareSheetAction.shareAsPdf:
        final dismiss = showLoadingPopup(
          context,
          message: AppLocalizations.of(context).preparingPdfMessage,
        );
        try {
          await persistAction(
            context,
            () => vm.shareSelectedAsPdf(result.paths, current.title),
          );
        } finally {
          await dismiss();
        }

      case ShareSheetAction.shareAsImages:
        final dismiss = showLoadingPopup(
          context,
          message: AppLocalizations.of(context).preparingPdfMessage,
        );
        try {
          await persistAction(
            context,
            () => vm.shareSelectedAsImages(result.paths),
          );
        } finally {
          await dismiss();
        }

      case ShareSheetAction.exportPagesAsPdf:
        final dismiss = showLoadingPopup(
          context,
          message: AppLocalizations.of(context).preparingPdfMessage,
        );
        try {
          await persistAction(
            context,
            () => vm.exportSelectedPagesAsPdf(result.paths, current.title),
          );
        } finally {
          await dismiss();
        }

      case ShareSheetAction.saveToGallery:
        final dismiss = showLoadingPopup(
          context,
          message: AppLocalizations.of(context).preparingPdfMessage,
        );
        bool saved = false;
        try {
          saved = await persistAction(
            context,
            () => vm.saveSelectedToGallery(result.paths),
          );
        } finally {
          await dismiss();
        }
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

/// Scanner-style actions remain available while the user reads attachments.
/// [canEdit] is false for a document inside a Viewer-role shared category
/// (see DocumentViewerViewModel.canEditCurrentDocument) -- every mutating
/// action (add pages, edit, move, rename) is hidden then, keeping only
/// Share, per docs/space_sharing_ux_plan.txt §4.
class _DocumentActionBar extends StatelessWidget {
  final bool canEdit;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onMove;
  final VoidCallback onRename;

  const _DocumentActionBar({
    required this.canEdit,
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
            if (canEdit)
              _DocumentActionItem(
                icon: Icons.add_a_photo_outlined,
                label: l10n.addPagesAction,
                onTap: onAdd,
              ),
            if (canEdit)
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
            if (canEdit)
              _DocumentActionItem(
                icon: Iconsax.category,
                label: l10n.move,
                onTap: onMove,
              ),
            if (canEdit)
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
  final Set<String> selectedPaths;
  final ValueChanged<String> onToggleSelection;

  const _PageArea({
    required this.document,
    required this.selectedPaths,
    required this.onToggleSelection,
  });

  @override
  State<_PageArea> createState() => _PageAreaState();
}

class _PageAreaState extends State<_PageArea> {
  final _scrollController = ScrollController();
  final _zoomController = PhotoViewController();
  final _listKey = GlobalKey();
  late List<GlobalKey> _fileKeys = _keysFor(widget.document.filePaths.length);
  int _currentFile = 0;

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateCurrentFile());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateCurrentFile)
      ..dispose();
    _zoomController.dispose();
    super.dispose();
  }

  // Walks from the last file backward and picks the first (i.e.
  // highest-index) one whose top has already crossed above the viewport's
  // top edge — that's the file "at the top" right now. Checking from the
  // front instead (first file whose *bottom* is still > 0) breaks once an
  // earlier file is taller than the remaining scroll distance: its bottom
  // can stay below the viewport top for the entire scroll range, so the
  // counter would get stuck on it even after a later, shorter file is
  // clearly the one on screen.
  void _updateCurrentFile() {
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || listBox == null) return;

    for (var index = _fileKeys.length - 1; index >= 0; index--) {
      final fileBox =
          _fileKeys[index].currentContext?.findRenderObject() as RenderBox?;
      if (fileBox == null) continue;
      final top = fileBox.localToGlobal(Offset.zero, ancestor: listBox).dy;
      if (top <= 0) {
        if (_currentFile != index) setState(() => _currentFile = index);
        return;
      }
    }
    if (_currentFile != 0) setState(() => _currentFile = 0);
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

    // A document whose only file is a genuine PDF -- either a real
    // multi-page PDF the user attached via Files, or a legacy document
    // from before scanned photos stopped being merged into one PDF on
    // save. With nothing else in filePaths to scroll between, the list
    // below this comment -- and its own zoom wrapper further down --
    // exist for nothing, and only get in the way: both are same-axis
    // gesture consumers that would otherwise sit between the user's
    // finger and PdfViewPinch's own internal page-scroll/zoom, exactly
    // the conflict that broke scrolling here before. Render the live PDF
    // directly instead, with nothing above it in the gesture arena. A
    // multi-photo scan is never a single PDF file any more (each photo
    // is its own filePaths entry), so it falls through to the generic
    // list below instead -- already a plain vertical scroller of images.
    final singlePath = paths.length == 1 ? paths.first : null;
    if (singlePath != null && isPdfPath(singlePath)) {
      return DocumentCoverHero(
        document: widget.document,
        color: categoryIconColor(context, widget.document.category),
        child: _SinglePdfPage(
          path: singlePath,
          isSelected: widget.selectedPaths.contains(singlePath),
          selectionActive: widget.selectedPaths.isNotEmpty,
          onToggleSelection: () => widget.onToggleSelection(singlePath),
        ),
      );
    }

    final content = Stack(
      children: [
        ListView.separated(
          key: _listKey,
          controller: _scrollController,
          padding: const .fromLTRB(14, 14, 14, 24),
          itemCount: paths.length,
          separatorBuilder: (_, _) => heightBox(14),
          itemBuilder: (context, index) {
            final preview = _SelectableFilePreview(
              path: paths[index],
              isSelected: widget.selectedPaths.contains(paths[index]),
              selectionActive: widget.selectedPaths.isNotEmpty,
              onToggle: () => widget.onToggleSelection(paths[index]),
              onOpenPreview: () => AppNavigator.pushNamed(
                RouteNames.filePreview,
                extra: (widget.document.filePaths, index),
              ),
            );
            return KeyedSubtree(
              key: _fileKeys[index],
              // Only the first file is what the document's cover thumbnail
              // (on the card/tile that was tapped to get here) actually
              // shows, so it's the only one that has a matching Hero on
              // the other end of the flight.
              child: index == 0
                  ? DocumentCoverHero(
                      document: widget.document,
                      color: categoryIconColor(
                        context,
                        widget.document.category,
                      ),
                      child: preview,
                    )
                  : preview,
            );
          },
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

    // Zooms the page as a whole — list, counter, everything — same intent
    // as the old plain InteractiveViewer wrapper, but that one lost the
    // pinch gesture to this list's own Scrollable and to each item's
    // tap/long-press GestureDetector whenever a finger landed on a file, so
    // it only ever zoomed when pinching empty list space. photo_view's
    // PhotoViewGestureRecognizer is built to referee exactly that: it only
    // claims a single-finger drag when the content is actually zoomed in
    // enough to have somewhere to pan (PhotoViewGestureDetectorScope below
    // wires that check up against this list's own vertical axis, so an
    // unzoomed single-finger drag still falls through to the ListView's
    // scroll untouched), but a real two-finger pinch is always claimed
    // outright, pre-empting any sibling recognizer — including this list's
    // per-item tap/long-press — the moment both fingers move. childSize is
    // pinned to the exact same box PhotoView measures itself (via the outer
    // LayoutBuilder), so "fits its container" lines up with scale == 1.0,
    // same as InteractiveViewer's own identity transform used to mean.
    return LayoutBuilder(
      builder: (context, constraints) => PhotoViewGestureDetectorScope(
        axis: Axis.vertical,
        child: PhotoView.customChild(
          controller: _zoomController,
          childSize: constraints.biggest,
          minScale: 1.0,
          maxScale: 4.0,
          initialScale: 1.0,
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A document whose only file is a single multi-page PDF: shows it live and
/// directly, filling the page area, instead of through the general
/// multi-file list+zoom machinery above (see the comment at its call site
/// in [_PageAreaState.build] for why). [PdfZoomView]/`PdfViewPinch` owns
/// its own pinch-zoom/pan/page-scroll gestures outright here -- the
/// wrapping [GestureDetector] only adds tap/long-press for selection,
/// which coexist fine with those (a tap or long-press that turns into a
/// drag is ceded to PdfViewPinch's own recognizers by the gesture arena,
/// same as how the list below handles it per-item).
class _SinglePdfPage extends StatefulWidget {
  final String path;
  final bool isSelected;
  final bool selectionActive;
  final VoidCallback onToggleSelection;

  const _SinglePdfPage({
    required this.path,
    required this.isSelected,
    required this.selectionActive,
    required this.onToggleSelection,
  });

  @override
  State<_SinglePdfPage> createState() => _SinglePdfPageState();
}

class _SinglePdfPageState extends State<_SinglePdfPage> {
  int _page = 1;
  int? _pagesCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onToggleSelection,
      onTap: widget.selectionActive ? widget.onToggleSelection : null,
      child: ColoredBox(
        color: context.surfaceElevated,
        child: Stack(
          fit: .expand,
          children: [
            PdfZoomView(
              path: widget.path,
              fallback: _UnsupportedPreview(path: widget.path),
              onPageChanged: (page, pagesCount) {
                if (mounted) {
                  setState(() {
                    _page = page;
                    _pagesCount = pagesCount;
                  });
                }
              },
            ),
            if (widget.isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: context.primary.withValues(alpha: 0.16),
                  ),
                ),
              ),
            if (widget.isSelected)
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
            Positioned(
              top: 12,
              left: 12,
              child: IgnorePointer(
                child: _FileCounter(current: _page, total: _pagesCount ?? 1),
              ),
            ),
          ],
        ),
      ),
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
        FilePageHero(path: path, child: _FilePreview(path: path)),
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
        // A scanned page can be several thousand pixels wide (deliberately
        // kept at pick-time's full resolution -- see
        // AttachmentLocalDataSource.pickFromGallery's own comment), but this
        // item only ever displays at screen width -- cap decode size to
        // that instead of decoding the full source for every page in the
        // scroller.
        cacheWidth: (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round(),
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
    // A real interactive PdfZoomView can't live in here: this list item sits
    // inside the page list's own vertical ListView, which is itself nested
    // inside the page-level PhotoView zoom wrapper below -- both same-axis
    // gesture consumers that would fight PdfViewPinch for the same vertical
    // drag (see PdfZoomView's own doc comment). A static first-page
    // thumbnail avoids that conflict entirely; tapping it already opens the
    // full-screen FilePreviewView (via _SelectableFilePreview's onTap),
    // where PdfZoomView owns its gestures uncontested and paging/zooming
    // actually works.
    if (isPdfPath(path)) return _PdfStaticPreview(path: path);
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

/// Static first-page thumbnail for a PDF attachment, with a "N pages"
/// badge when it has more than one -- see [_PagePreview] for why this
/// can't be the live, scrollable [PdfZoomView] itself.
class _PdfStaticPreview extends StatefulWidget {
  final String path;

  const _PdfStaticPreview({required this.path});

  @override
  State<_PdfStaticPreview> createState() => _PdfStaticPreviewState();
}

class _PdfStaticPreviewState extends State<_PdfStaticPreview> {
  int? _pagesCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: .expand,
      children: [
        ColoredBox(
          color: context.surfaceElevated,
          child: PdfPageThumbnail(
            path: widget.path,
            fit: .contain,
            // Default renderWidth (160) is sized for a small card, not this
            // full-width preview -- upscaling it here is what looked
            // pixelated. Render at the device's real pixel width instead.
            renderWidth:
                context.screenWidth * MediaQuery.devicePixelRatioOf(context),
            onPagesCount: (count) {
              if (mounted) setState(() => _pagesCount = count);
            },
            fallback: _UnsupportedPreview(path: widget.path),
          ),
        ),
        if ((_pagesCount ?? 1) > 1)
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const .symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.black.withValues(alpha: 0.65),
                borderRadius: .circular(20),
              ),
              child: Row(
                mainAxisSize: .min,
                children: [
                  const Icon(
                    Iconsax.document_copy,
                    size: 14,
                    color: Colors.white,
                  ),
                  widthBox(6),
                  Text(
                    '$_pagesCount pages',
                    style: context.labelSmall.copyWith(
                      color: context.white,
                      fontWeight: .w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
