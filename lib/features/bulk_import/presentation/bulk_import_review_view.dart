import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';

import '../../../core/constants/constants_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../../../routes/routes_exports.dart';
import '../../documents/domain/entities/document_item.dart';
import '../../home/home_exports.dart';
import '../domain/entities/bulk_import_candidate.dart';
import 'viewmodel/bulk_import_viewmodel.dart';

class BulkImportReviewView extends StatelessWidget {
  final BulkImportViewModel viewModel;
  const BulkImportReviewView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => viewModel,
    child: const _ReviewBody(),
  );
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody();

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  Future<void> _import(BuildContext context, BulkImportViewModel vm) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (vm.isProcessing) {
      final proceed = await showAnimatedConfirmDialog(
        context,
        icon: Iconsax.flash_1,
        title: 'Import with current details?',
        message:
            'Suggestions are still running. Importing now keeps the details '
            'currently shown and stops remaining suggestions.',
        confirmLabel: 'Import now',
        cancelLabel: 'Keep reviewing',
        isDestructive: false,
      );
      if (!proceed || !context.mounted) return;
    }
    final result = await vm.commit();
    if (!context.mounted) return;
    final allDone = result.failures.isEmpty && vm.candidates.isEmpty;
    await _showResultDialog(
      context,
      icon: result.failures.isEmpty ? Iconsax.tick_circle : Iconsax.warning_2,
      accent: result.failures.isEmpty ? context.success : context.warning,
      title: result.failures.isEmpty
          ? 'Import complete'
          : 'Some documents need retrying',
      message:
          '${result.imported} documents imported.'
          '${result.failures.isEmpty ? '' : '\n${result.failures.length} could not be saved. They remain in review with an error so you can retry. Saved documents will not be imported again.'}',
      actionLabel: allDone ? 'Done' : 'Back to review',
    );
    if (!context.mounted) return;
    if (allDone) context.goNamed(RouteNames.home);
  }

  Future<void> _showResultDialog(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: dialogContext.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              heightBox(18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: dialogContext.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              heightBox(8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: dialogContext.bodyMedium.copyWith(
                  color: dialogContext.textSecondary,
                ),
              ),
              heightBox(24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: actionLabel,
                  radius: 14,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BulkImportViewModel>();
    return PopScope(
      canPop: !vm.isImporting,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: AppBar(
          backgroundColor: context.background,
          foregroundColor: context.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 4,
          leadingWidth: 56,
          leading: Center(
            child: _CircleIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Cancel import',
              onPressed: vm.isImporting ? null : () => _leave(context),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Review documents',
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                vm.candidates.isEmpty
                    ? 'Nothing left to review'
                    : '${vm.selectedCount} of ${vm.candidates.length} selected',
                style: context.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        body: AbsorbPointer(
          absorbing: vm.isImporting,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (vm.notice != null) ...[
                _InfoBanner(icon: Iconsax.info_circle, message: vm.notice!),
                heightBox(14),
              ],
              if (vm.isProcessing) ...[
                _ProcessingBanner(vm: vm),
                heightBox(14),
              ],
              if (vm.candidates.isEmpty) const _EmptyState(),
              for (final c in vm.candidates)
                _CandidateCard(key: ValueKey(c.id), candidate: c),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: context.background,
              border: Border(top: BorderSide(color: context.divider)),
            ),
            child: CustomButton(
              onPressed: vm.canImport ? () => _import(context, vm) : null,
              icon: vm.isImporting ? null : Iconsax.document_upload,
              radius: 16,
              size: const Size(double.infinity, 54),
              text: vm.isImporting
                  ? 'Importing ${vm.importCompleted} of ${vm.importTotal}…'
                  : 'Import ${vm.selectedCount} documents',
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.categoryCardSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 19,
          color: onPressed == null ? context.textDisabled : context.textPrimary,
        ),
      ),
    ),
  );
}

/// A pill-shaped button matching this screen's selection toolbar and each
/// card's secondary actions (retry/split/expiry) — one visual language
/// instead of mixing default [TextButton]s with ad-hoc containers.
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PillButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: _PillContent(icon: icon, label: label, enabled: onTap != null),
  );
}

/// The visual half of [_PillButton], split out so it can also sit inside a
/// [PopupMenuButton]'s `child` (which supplies its own tap handling) without
/// nesting a second [InkWell].
class _PillContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;

  const _PillContent({
    required this.icon,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: context.surfaceElevated,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: context.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: enabled ? context.textSecondary : context.textDisabled,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled ? context.textPrimary : context.textDisabled,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.border),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.textSecondary),
        widthBox(10),
        Expanded(
          child: Text(
            message,
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _ProcessingBanner extends StatelessWidget {
  final BulkImportViewModel vm;

  const _ProcessingBanner({required this.vm});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: context.shadow,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const LoadingIndicator(size: 20),
        widthBox(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Finding suggestions',
                style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              heightBox(8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: vm.processingTotal == 0
                      ? null
                      : vm.processedCount / vm.processingTotal,
                  backgroundColor: context.border,
                  color: context.primary,
                ),
              ),
              heightBox(6),
              Text(
                '${vm.processedCount} of ${vm.processingTotal} complete',
                style: context.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.categoryCardSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.document_text,
            size: 32,
            color: context.textSecondary,
          ),
        ),
        heightBox(16),
        Text(
          'Nothing left to review',
          style: context.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        heightBox(6),
        Text(
          'Close this screen to choose more files.',
          textAlign: TextAlign.center,
          style: context.bodySmall.copyWith(color: context.textSecondary),
        ),
      ],
    ),
  );
}

CategoryItem? _categoryFor(List<CategoryItem> categories, String categoryId) {
  if (categoryId == uncategorizedCategoryId) return null;
  for (final category in categories) {
    if (category.id == categoryId) return category;
  }
  return null;
}

Future<void> _openCategoryPicker(
  BuildContext context,
  BulkImportViewModel vm,
  BulkImportCandidate c,
) async {
  const uncategorized = CategoryItem(
    id: uncategorizedCategoryId,
    name: 'Uncategorized',
    iconKey: 'solidFolder',
  );
  final options = [uncategorized, ...vm.categories];
  final selected = _categoryFor(vm.categories, c.categoryId) ?? uncategorized;
  final picked = await showModalBottomSheet<CategoryItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        CategoryPickerSheet(categories: options, selected: selected),
  );
  if (picked != null) vm.updateCategory(c.id, picked.id);
}

class _CandidateCard extends StatefulWidget {
  final BulkImportCandidate candidate;
  const _CandidateCard({super.key, required this.candidate});
  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  late final TextEditingController _title;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.candidate.title);
  }

  @override
  void didUpdateWidget(covariant _CandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = widget.candidate;
    if (oldWidget.candidate.title != c.title && _title.text != c.title) {
      _title.text = c.title;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry(BuildContext context, BulkImportViewModel vm) async {
    final c = widget.candidate;
    final initialDate = c.expiryDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year < 1900 ? initialDate.year : 1900),
      lastDate: DateTime(initialDate.year > 2200 ? initialDate.year + 1 : 2201),
    );
    if (date != null && context.mounted) vm.updateExpiry(c.id, date);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BulkImportViewModel>();
    final c = widget.candidate;
    final selectedCategory = _categoryFor(vm.categories, c.categoryId);
    final categoryColor = selectedCategory == null
        ? context.textSecondary
        : ((selectedCategory.colorValue == null
                  ? null
                  : Color(selectedCategory.colorValue!)) ??
              categoryIconColor(context, selectedCategory.name));

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: context.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // A Material ancestor (not just a colored Container) so the
          // ExpansionTile's internal ListTile paints its ink splashes on
          // this surface instead of triggering Flutter's "ink splashes
          // may be invisible" assertion against the DecoratedBox above it.
          // It also backs the InkWell below, which makes the whole card
          // (minus the thumbnails and the interactive fields/rows inside
          // it, which claim their own taps first) a single select/deselect
          // target -- tapping a thumbnail instead opens that page.
          child: Material(
            color: context.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => vm.toggle(c.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: c.isSelected ? 1 : 0.45,
                      child: _CandidateThumbnailSlider(
                        candidate: c,
                        onOpenPage: (index) => AppNavigator.pushNamed(
                          RouteNames.filePreview,
                          extra: (
                            [for (final a in c.attachments) a.path],
                            index,
                          ),
                        ),
                      ),
                    ),
                    heightBox(14),
                    if (c.state == CandidateProcessingState.processing) ...[
                      Row(
                        children: [
                          const LoadingIndicator(size: 16),
                          widthBox(8),
                          Text(
                            'Analyzing…',
                            style: context.labelSmall.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      heightBox(10),
                    ],
                    if (c.state == CandidateProcessingState.failed &&
                        c.error != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: context.errorAccent,
                          ),
                          widthBox(6),
                          Expanded(
                            child: Text(
                              c.error!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.labelSmall.copyWith(
                                color: context.errorAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      heightBox(10),
                    ],
                    TextField(
                      controller: _title,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        errorText: c.title.trim().isEmpty
                            ? 'Enter a title'
                            : null,
                        filled: true,
                        fillColor: context.surface,
                      ),
                      onChanged: (value) => vm.updateTitle(c.id, value),
                    ),
                    heightBox(12),
                    InkWell(
                      onTap: () => _openCategoryPicker(context, vm, c),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: categoryColor,
                                shape: BoxShape.circle,
                              ),
                              child: selectedCategory == null
                                  ? Icon(
                                      Iconsax.category,
                                      size: 14,
                                      color: context.white,
                                    )
                                  : FaIcon(
                                      iconForKey(selectedCategory.iconKey),
                                      size: 14,
                                      color: context.white,
                                    ),
                            ),
                            widthBox(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Category',
                                    style: context.labelSmall.copyWith(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    selectedCategory?.name ?? 'Uncategorized',
                                    style: context.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Iconsax.arrow_right_3,
                              size: 16,
                              color: context.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (c.expiryDate != null) ...[
                      heightBox(10),
                      InkWell(
                        onTap: () => _pickExpiry(context, vm),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.warning.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Iconsax.calendar_1,
                                  size: 14,
                                  color: context.warning,
                                ),
                              ),
                              widthBox(10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Expires',
                                      style: context.labelSmall.copyWith(
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).formatMediumDate(c.expiryDate!),
                                      style: context.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _RemoveButton(
                                onTap: () => vm.updateExpiry(c.id, null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (c.state == CandidateProcessingState.failed) ...[
                      heightBox(10),
                      _PillButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retry analysis',
                        onTap: c.isSelected ? () => vm.retry(c.id) : null,
                      ),
                    ],
                    if (c.attachments.length > 1) ...[
                      heightBox(10),
                      _PillButton(
                        icon: Icons.call_split,
                        label: 'Split into separate documents',
                        onTap: () => vm.splitCandidate(c.id),
                      ),
                    ],
                    if (c.importError != null) ...[
                      heightBox(10),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: context.errorAccent,
                          ),
                          widthBox(6),
                          Expanded(
                            child: Text(
                              c.importError!,
                              style: context.labelSmall.copyWith(
                                color: context.errorAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: _SelectionBadge(selected: c.isSelected),
        ),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.categoryCardSurface,
      ),
      child: Icon(Icons.close_rounded, size: 15, color: context.textSecondary),
    ),
  );
}

/// Pinned to a candidate card's top-right corner -- filled blue check when
/// selected, an empty ring otherwise. The card itself is the tap target
/// (see the card's own InkWell); this badge is only the indicator.
class _SelectionBadge extends StatelessWidget {
  final bool selected;
  const _SelectionBadge({required this.selected});

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? context.primary : Colors.black.withValues(alpha: 0.35),
      border: Border.all(
        color: selected ? context.primary : context.white,
        width: 1.5,
      ),
    ),
    child: selected
        ? Icon(Icons.check_rounded, size: 15, color: context.white)
        : null,
  );
}

/// A single large thumbnail for a one-page candidate, or a horizontally
/// scrollable row of thumbnails — one per attachment — for a multi-page
/// candidate, so every page is directly visible/swipeable. Tapping any
/// page opens its full view via [onOpenPage] -- selection itself is a
/// card-level action (see the card's own InkWell), not per-page.
class _CandidateThumbnailSlider extends StatelessWidget {
  final BulkImportCandidate candidate;
  final ValueChanged<int> onOpenPage;
  const _CandidateThumbnailSlider({
    required this.candidate,
    required this.onOpenPage,
  });

  static const double _width = 92;
  static const double _height = 110;
  static const double _radius = 16;

  Widget _fallback(BuildContext context) => Container(
    color: context.categoryCardSurface,
    alignment: Alignment.center,
    child: Icon(
      Icons.description_outlined,
      size: 28,
      color: context.primaryAccent,
    ),
  );

  Widget _tile(BuildContext context, String path) {
    final fallback = _fallback(context);
    return Container(
      width: _width,
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: context.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isImagePath(path)
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              cacheWidth: (_width * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (_, _, _) => fallback,
            )
          : isPdfPath(path)
          ? PdfPageThumbnail(path: path, fallback: fallback, renderWidth: 220)
          : fallback,
    );
  }

  Widget _tappableTile(BuildContext context, int index) => InkWell(
    borderRadius: BorderRadius.circular(_radius),
    onTap: () => onOpenPage(index),
    child: _tile(context, candidate.attachments[index].path),
  );

  @override
  Widget build(BuildContext context) {
    if (candidate.attachments.length == 1) {
      return _tappableTile(context, 0);
    }
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: candidate.attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) => _tappableTile(context, index),
      ),
    );
  }
}
