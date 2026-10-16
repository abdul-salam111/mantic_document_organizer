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

/// Matches the same compact card language as [DraftInbox]/Home's Expiring
/// Soon banner -- small circular icon badge, title + chevron row, tinted
/// pill background -- rather than standing out as a bigger, differently
/// shaped block. The progress itself reads as a slim bar under the title
/// (with the percentage called out as its own stat) instead of a large
/// ring, so the card's height stays in the same family as its siblings.
class DocumentReadinessCard extends StatelessWidget {
  const DocumentReadinessCard({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => sl<ReadinessViewModel>()..init(),
    child: Consumer<ReadinessViewModel>(
      builder: (context, vm, _) {
        final l10n = AppLocalizations.of(context);
        final isComplete = vm.total > 0 && vm.completed == vm.total;
        return Padding(
          padding: const .only(bottom: 14),
          child: Material(
            color: Color.alphaBlend(
              context.primary.withValues(alpha: 0.05),
              context.categoryCardSurface,
            ),
            borderRadius: .circular(12),
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
                padding: const .symmetric(horizontal: 12, vertical: 10),
                child: !vm.ready
                    ? Row(
                        children: [
                          _ReadinessIconBadge(complete: false),
                          widthBox(10),
                          Expanded(
                            child: Text(
                              l10n.readinessTitle,
                              style: context.labelLarge.copyWith(
                                fontWeight: .w700,
                              ),
                            ),
                          ),
                          if (vm.isLoading)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            TextButton(
                              onPressed: vm.init,
                              child: Text(l10n.readinessRetry),
                            ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            children: [
                              _ReadinessIconBadge(complete: isComplete),
                              widthBox(10),
                              Expanded(
                                child: Text(
                                  l10n.readinessTitle,
                                  style: context.labelLarge.copyWith(
                                    fontWeight: .w700,
                                  ),
                                ),
                              ),
                              widthBox(8),
                              if (vm.total > 0)
                                _AnimatedPercentLabel(progress: vm.progress),
                            ],
                          ),
                          heightBox(10),
                          _ReadinessBar(progress: vm.progress),
                          heightBox(8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vm.total == 0
                                      ? l10n.readinessAllExcluded
                                      : l10n.readinessCount(
                                          vm.completed,
                                          vm.total,
                                        ),
                                  style: context.labelSmall.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                              if (vm.total > 0) ...[
                                Text(
                                  isComplete
                                      ? l10n.readinessComplete
                                      : l10n.readinessReview,
                                  style: context.labelSmall.copyWith(
                                    color: context.primaryAccent,
                                    fontWeight: .w600,
                                  ),
                                ),
                                widthBox(4),
                              ],
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: context.textSecondary,
                              ),
                            ],
                          ),
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

class _ReadinessIconBadge extends StatelessWidget {
  final bool complete;
  const _ReadinessIconBadge({required this.complete});
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: .center,
    decoration: BoxDecoration(
      color: context.primary.withValues(alpha: 0.15),
      shape: .circle,
    ),
    child: Icon(
      complete ? Icons.verified_outlined : Icons.fact_check_outlined,
      size: 16,
      color: context.primaryAccent,
    ),
  );
}

/// The percentage read-out next to the title -- animates in step with
/// [_ReadinessBar] below it (same tween/duration) so the number and the
/// fill never visibly disagree mid-animation.
class _AnimatedPercentLabel extends StatelessWidget {
  final double progress;
  const _AnimatedPercentLabel({required this.progress});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: progress),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => Text(
      '${(value * 100).round()}%',
      style: context.titleSmall.copyWith(
        fontWeight: .w800,
        color: context.primaryAccent,
      ),
    ),
  );
}

/// A slim, full-width animated fill -- replaces the previous large ring so
/// this card reads at a glance instead of needing its own visual weight
/// class separate from Home's other compact cards.
class _ReadinessBar extends StatelessWidget {
  final double progress;
  const _ReadinessBar({required this.progress});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: progress),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => ClipRRect(
      borderRadius: .circular(4),
      child: SizedBox(
        width: double.infinity,
        height: 7,
        child: Stack(
          children: [
            ColoredBox(color: context.primary.withValues(alpha: 0.12)),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: ColoredBox(color: context.primaryAccent),
            ),
          ],
        ),
      ),
    ),
  );
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
              const SizedBox(height: 8),
              Text(
                l10n.readinessExplanation,
                style: context.bodySmall.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                vm.total == 0
                    ? l10n.readinessAllExcluded
                    : l10n.readinessCount(vm.completed, vm.total),
                style: context.titleSmall,
              ),
              const SizedBox(height: 12),
              for (final item in vm.items) ...[
                Container(
                  padding: const .all(14),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: .circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.excluded
                                ? Icons.remove_circle_outline
                                : item.complete
                                ? Icons.check_circle_outline
                                : Icons.add_circle_outline,
                            color: item.complete
                                ? context.primaryAccent
                                : context.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _groupTitle(l10n, item.group),
                              style: context.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _groupExamples(l10n, item.group),
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.excluded
                            ? l10n.readinessNotApplicable
                            : item.complete
                            ? l10n.readinessSaved
                            : l10n.readinessConsider,
                        style: context.labelMedium.copyWith(
                          color: item.complete
                              ? context.primaryAccent
                              : context.textSecondary,
                        ),
                      ),
                      if (item.complete)
                        TextButton.icon(
                          onPressed: () => context.pushNamed(
                            RouteNames.documentViewer,
                            extra: item.document,
                          ),
                          icon: const Icon(
                            Icons.description_outlined,
                            size: 18,
                          ),
                          label: Text(
                            item.document!.title.trim().isEmpty
                                ? l10n.readinessUntitled
                                : item.document!.title,
                            maxLines: 2,
                            overflow: .ellipsis,
                          ),
                        ),
                      if (!item.excluded)
                        Wrap(
                          spacing: 8,
                          children: [
                            if (!item.complete)
                              TextButton.icon(
                                onPressed: vm.isLoading
                                    ? null
                                    : () => _add(context, vm, item.group),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(l10n.readinessAdd),
                              ),
                            TextButton(
                              onPressed: vm.isLoading
                                  ? null
                                  : () => _choose(context, vm, item.group),
                              child: Text(
                                item.complete
                                    ? l10n.readinessChange
                                    : l10n.readinessChoose,
                              ),
                            ),
                          ],
                        ),
                      TextButton(
                        onPressed: vm.isLoading
                            ? null
                            : () => vm.setExcluded(item.group, !item.excluded),
                        child: Text(
                          item.excluded
                              ? l10n.readinessInclude
                              : l10n.readinessNotApplicable,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(l10n.readinessAdditional, style: context.titleSmall),
              const SizedBox(height: 6),
              Text(
                l10n.readinessAdditionalExamples,
                style: context.bodySmall.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      );
    },
  );
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
