import 'package:flutter/material.dart';
import '../../../../core/di/di_exports.dart';
import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/persist_action.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../../../../routes/routes_exports.dart';
import '../../../documents/documents_domain_exports.dart' show DocumentItem;
import '../../domain/entities/document_readiness.dart';
import '../../viewmodel/readiness_viewmodel.dart';
import 'document_cover_thumbnail.dart';

class DocumentReadinessCard extends StatelessWidget {
  const DocumentReadinessCard({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => sl<ReadinessViewModel>()..init(),
    child: Consumer<ReadinessViewModel>(
      builder: (context, vm, _) {
        final l10n = AppLocalizations.of(context);
        return Padding(
          padding: const .only(bottom: 14),
          child: Material(
            color: context.categoryCardSurface,
            borderRadius: .circular(20),
            clipBehavior: .antiAlias,
            child: InkWell(
              onTap: !vm.ready
                  ? null
                  : () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      backgroundColor: context.background,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: vm,
                        child: const _ReadinessSheet(),
                      ),
                    ),
              child: Padding(
                padding: const .all(18),
                child: !vm.ready
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.readinessTitle,
                              style: context.titleSmall,
                            ),
                          ),
                          if (vm.isLoading)
                            const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            TextButton(
                              onPressed: vm.init,
                              child: Text(l10n.readinessRetry),
                            ),
                        ],
                      )
                    : Row(
                        children: [
                          _ReadinessRing(vm: vm),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: .start,
                              children: [
                                Text(
                                  l10n.readinessTitle,
                                  style: context.titleSmall.copyWith(
                                    fontWeight: .w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vm.total == 0
                                      ? l10n.readinessAllExcluded
                                      : l10n.readinessCount(
                                          vm.completed,
                                          vm.total,
                                        ),
                                  style: context.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  vm.total > 0 && vm.completed == vm.total
                                      ? l10n.readinessComplete
                                      : l10n.readinessReview,
                                  style: context.labelSmall.copyWith(
                                    color: context.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ReadinessRing extends StatelessWidget {
  final ReadinessViewModel vm;
  const _ReadinessRing({required this.vm});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.readinessTitle,
      value: vm.total == 0
          ? l10n.readinessAllExcluded
          : l10n.readinessCount(vm.completed, vm.total),
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 72,
          // Animates the ring (and its percentage label) from whatever it
          // last showed to the new progress -- TweenAnimationBuilder
          // tracks the previous `end` itself, so a document being
          // saved/linked/excluded eases the ring forward instead of
          // snapping, without needing an explicit AnimationController here.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: vm.progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Stack(
              alignment: .center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    strokeCap: .round,
                    color: context.primaryAccent,
                    backgroundColor: context.primary.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const .all(12),
                  child: FittedBox(
                    child: Text(
                      vm.total == 0 ? '—' : '${(value * 100).round()}%',
                      style: context.titleMedium.copyWith(fontWeight: .w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _groupTitle(AppLocalizations l10n, ReadinessGroup group) =>
    switch (group) {
      ReadinessGroup.identity => l10n.readinessIdentity,
      ReadinessGroup.address => l10n.readinessAddress,
      ReadinessGroup.birth => l10n.readinessBirth,
      ReadinessGroup.health => l10n.readinessHealth,
      ReadinessGroup.finance => l10n.readinessFinance,
    };
String _groupExamples(AppLocalizations l10n, ReadinessGroup group) =>
    switch (group) {
      ReadinessGroup.identity => l10n.readinessIdentityExamples,
      ReadinessGroup.address => l10n.readinessAddressExamples,
      ReadinessGroup.birth => l10n.readinessBirthExamples,
      ReadinessGroup.health => l10n.readinessHealthExamples,
      ReadinessGroup.finance => l10n.readinessFinanceExamples,
    };

class _ReadinessSheet extends StatelessWidget {
  const _ReadinessSheet();

  Future<void> _add(
    BuildContext context,
    ReadinessViewModel vm,
    ReadinessGroup group,
  ) async {
    final l10n = AppLocalizations.of(context);
    var category = vm.categoryFor(group);
    if (category == null) {
      final ok = await persistAction(context, () async {
        category = await vm.prepareCategory(group, _groupTitle(l10n, group));
      });
      if (!ok || !context.mounted) return;
    }
    final saved = await context.pushNamed<DocumentItem>(
      RouteNames.addDocument,
      extra: category,
    );
    if (saved != null && context.mounted) await vm.link(group, saved);
  }

  Future<void> _choose(
    BuildContext context,
    ReadinessViewModel vm,
    ReadinessGroup group,
  ) async {
    final selected = await showModalBottomSheet<DocumentItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.background,
      builder: (_) => _SavedDocumentPicker(vm: vm),
    );
    if (selected != null && context.mounted) await vm.link(group, selected);
  }

  @override
  Widget build(BuildContext context) => Consumer<ReadinessViewModel>(
    builder: (context, vm, _) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: ListView(
            padding: const .fromLTRB(20, 0, 20, 24),
            children: [
              Text(l10n.readinessTitle, style: context.titleLarge),
              heightBox(4),
              Text(
                vm.total == 0
                    ? l10n.readinessAllExcluded
                    : l10n.readinessCount(vm.completed, vm.total),
                style: context.bodySmall.copyWith(color: context.textSecondary),
              ),
              heightBox(14),
              for (final item in vm.items) ...[
                _ReadinessItemRow(
                  vm: vm,
                  item: item,
                  onAdd: () => _add(context, vm, item.group),
                  onChoose: () => _choose(context, vm, item.group),
                ),
                heightBox(8),
              ],
              heightBox(10),
              Text(
                l10n.readinessAdditionalExamples,
                style: context.labelSmall.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      );
    },
  );
}

enum _ReadinessMenuAction { choose, exclude }

/// One checklist line -- icon, title, and a single truncated subtitle, with
/// at most one primary action visible (Add) and everything else (choose a
/// different document, mark not applicable) behind an overflow menu, so an
/// item never needs more than one row regardless of its state.
class _ReadinessItemRow extends StatelessWidget {
  final ReadinessViewModel vm;
  final ReadinessItem item;
  final VoidCallback onAdd;
  final VoidCallback onChoose;
  const _ReadinessItemRow({
    required this.vm,
    required this.item,
    required this.onAdd,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _groupTitle(l10n, item.group);

    if (item.excluded) {
      return _ReadinessRow(
        icon: Icons.remove_circle_outline,
        iconColor: context.textSecondary,
        title: title,
        titleColor: context.textSecondary,
        subtitle: l10n.readinessNotApplicable,
        trailing: TextButton(
          onPressed: vm.isLoading
              ? null
              : () => vm.setExcluded(item.group, false),
          child: Text(l10n.readinessInclude),
        ),
      );
    }

    if (item.complete) {
      final document = item.document!;
      return _ReadinessRow(
        icon: Icons.check_circle,
        iconColor: context.primaryAccent,
        title: title,
        onTap: () =>
            context.pushNamed(RouteNames.documentViewer, extra: document),
        subtitleWidget: Row(
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 13,
              color: context.textSecondary,
            ),
            widthBox(4),
            Expanded(
              child: Text(
                document.title.trim().isEmpty
                    ? l10n.readinessUntitled
                    : document.title,
                maxLines: 1,
                overflow: .ellipsis,
                style: context.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
        trailing: _ReadinessOverflowMenu(
          vm: vm,
          item: item,
          onChoose: onChoose,
        ),
      );
    }

    return _ReadinessRow(
      icon: Icons.radio_button_unchecked,
      iconColor: context.textSecondary,
      title: title,
      subtitle: _groupExamples(l10n, item.group),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          _AddChip(
            label: l10n.readinessAdd,
            onPressed: vm.isLoading ? null : onAdd,
          ),
          widthBox(2),
          _ReadinessOverflowMenu(vm: vm, item: item, onChoose: onChoose),
        ],
      ),
    );
  }
}

/// Shared single-row shell for [_ReadinessItemRow]'s three states -- fixed
/// icon + title + one-line subtitle + trailing action(s), so every item
/// takes the same compact height regardless of which state it's in.
class _ReadinessRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget trailing;
  final VoidCallback? onTap;
  const _ReadinessRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleWidget,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: context.surface,
    borderRadius: .circular(14),
    clipBehavior: .antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.border),
          borderRadius: .circular(14),
        ),
        padding: const .symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            widthBox(10),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.titleSmall.copyWith(
                      color: titleColor,
                      fontWeight: .w600,
                    ),
                  ),
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 2),
                    subtitleWidget!,
                  ] else if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: context.labelSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            widthBox(6),
            trailing,
          ],
        ),
      ),
    ),
  );
}

/// Compact filled "Add" action -- the one primary action an incomplete
/// item needs visible at a glance; everything else lives in
/// [_ReadinessOverflowMenu] instead of stacking more buttons beside it.
class _AddChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _AddChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.add, size: 15),
    label: Text(label),
    style: TextButton.styleFrom(
      backgroundColor: context.primary.withValues(alpha: 0.1),
      foregroundColor: context.primaryAccent,
      padding: const .symmetric(horizontal: 10, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: .shrinkWrap,
      shape: const StadiumBorder(),
      textStyle: context.labelSmall.copyWith(fontWeight: .w600),
    ),
  );
}

/// "Use a saved document" / "Mark not applicable" -- secondary actions
/// available for every non-excluded item, tucked behind one icon instead
/// of two more always-visible buttons.
class _ReadinessOverflowMenu extends StatelessWidget {
  final ReadinessViewModel vm;
  final ReadinessItem item;
  final VoidCallback onChoose;
  const _ReadinessOverflowMenu({
    required this.vm,
    required this.item,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_ReadinessMenuAction>(
      icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: .circular(14)),
      enabled: !vm.isLoading,
      onSelected: (action) => switch (action) {
        _ReadinessMenuAction.choose => onChoose(),
        _ReadinessMenuAction.exclude => vm.setExcluded(item.group, true),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ReadinessMenuAction.choose,
          child: Text(
            item.complete ? l10n.readinessChange : l10n.readinessChoose,
          ),
        ),
        PopupMenuItem(
          value: _ReadinessMenuAction.exclude,
          child: Text(l10n.readinessNotApplicable),
        ),
      ],
    );
  }
}

class _SavedDocumentPicker extends StatefulWidget {
  final ReadinessViewModel vm;
  const _SavedDocumentPicker({required this.vm});
  @override
  State<_SavedDocumentPicker> createState() => _SavedDocumentPickerState();
}

class _SavedDocumentPickerState extends State<_SavedDocumentPicker> {
  String _query = '';
  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.vm.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documents = widget.vm.availableDocuments
        .where((d) => '${d.title} ${d.category}'.toLowerCase().contains(_query))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(l10n.readinessChoose, style: context.titleLarge),
              const SizedBox(height: 12),
              CustomSearchField(
                hintText: l10n.readinessSearch,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: documents.isEmpty
                    ? Center(child: Text(l10n.readinessNoDocuments))
                    : ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final document = documents[index];
                          return ListTile(
                            contentPadding: const .symmetric(vertical: 6),
                            leading: DocumentCoverThumbnail(
                              document: document,
                              color: context.primaryAccent,
                              width: 44,
                              height: 52,
                              borderRadius: 6,
                              iconSize: 20,
                            ),
                            title: Text(
                              document.title.trim().isEmpty
                                  ? l10n.readinessUntitled
                                  : document.title,
                              maxLines: 2,
                              overflow: .ellipsis,
                            ),
                            subtitle: Text(document.category),
                            onTap: () => Navigator.of(context).pop(document),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
