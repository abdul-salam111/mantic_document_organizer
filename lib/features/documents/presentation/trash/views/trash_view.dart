import 'package:mantic_doc_org/core/utils/persist_action.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../home/home_exports.dart';
import '../viewmodels/trash_viewmodel.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<TrashViewModel>(),
      child: Consumer<TrashViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: CustomAppBar(
              title: AppLocalizations.of(context).trash,
              actions: [
                if (vm.documents.isNotEmpty)
                  IconButton(
                    tooltip: AppLocalizations.of(context).emptyTrash,
                    icon: Icon(Iconsax.trash, color: context.white),
                    onPressed: () => _confirmEmptyTrash(context, vm),
                  ),
              ],
            ),
            body: SafeArea(
              child: vm.documents.isEmpty
                  ? EmptyStateWidget(
                      icon: Iconsax.trash,
                      title: AppLocalizations.of(context).trashEmptyTitle,
                      subtitle: AppLocalizations.of(context).trashEmptySubtitle,
                    )
                  : StaggeredReveal(
                      itemCount: vm.documents.length,
                      builder: (context, reveal) => ListView.separated(
                        padding: const .fromLTRB(10, 10, 10, 20),
                        itemCount: vm.documents.length,
                        separatorBuilder: (context, index) => heightBox(10),
                        itemBuilder: (context, index) {
                          final document = vm.documents[index];
                          return StaggeredRevealItem(
                            reveal: reveal,
                            itemCount: vm.documents.length,
                            index: index,
                            child: _TrashDocumentTile(
                              document: document,
                              accentColor: categoryIconColor(
                                context,
                                document.category,
                              ),
                              onRestore: () => _restore(context, vm, document),
                              onDeleteForever: () =>
                                  _confirmDeleteForever(context, vm, document),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    TrashViewModel vm,
    DocumentItem document,
  ) async {
    if (!await persistAction(context, () => vm.restore(document))) return;
    if (!context.mounted) return;
    AppToastsUtils.success(
      AppLocalizations.of(context).documentRestoredToast(document.title),
    );
  }

  Future<void> _confirmDeleteForever(
    BuildContext context,
    TrashViewModel vm,
    DocumentItem document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: Text(AppLocalizations.of(context).deleteForeverTitle),
        content: Text(
          AppLocalizations.of(context).deleteForeverConfirm(document.title),
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
    if (!await persistAction(context, () => vm.deleteForever(document))) return;
    if (!context.mounted) return;
    AppToastsUtils.success(
      AppLocalizations.of(
        context,
      ).documentPermanentlyDeletedToast(document.title),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    TrashViewModel vm,
  ) async {
    final count = vm.documents.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: Text(AppLocalizations.of(context).emptyTrashTitle),
        content: Text(AppLocalizations.of(context).emptyTrashConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppLocalizations.of(context).emptyTrash,
              style: TextStyle(color: context.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (!await persistAction(context, () => vm.emptyTrash())) return;
    if (!context.mounted) return;
    AppToastsUtils.success(AppLocalizations.of(context).trashEmptiedToast);
  }
}

/// Same visual language as [DocumentListTile] (accent bar, cover
/// thumbnail) but with restore/delete-forever actions instead of a
/// favorite toggle, and no [onTap] — a trashed document doesn't route
/// into document_viewer, whose edit/rename/move actions don't apply to it.
class _TrashDocumentTile extends StatelessWidget {
  final DocumentItem document;
  final Color accentColor;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  const _TrashDocumentTile({
    required this.document,
    required this.accentColor,
    required this.onRestore,
    required this.onDeleteForever,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: .circular(16),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: context.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const .all(8),
                child: Row(
                  crossAxisAlignment: .start,
                  children: [
                    DocumentCoverThumbnail(
                      document: document,
                      color: accentColor,
                      width: 76,
                      height: 76,
                      borderRadius: 12,
                      iconSize: 26,
                    ),
                    widthBox(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            document.title,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: context.bodyMedium.copyWith(
                              fontWeight: .w700,
                            ),
                          ),
                          heightBox(4),
                          Text(
                            document.category,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: context.labelSmall.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                          heightBox(8),
                          _RetentionBadge(deletedAt: document.deletedAt!),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: .min,
                      children: [
                        IconButton(
                          tooltip: AppLocalizations.of(context).restore,
                          icon: Icon(
                            Iconsax.rotate_left,
                            size: 20,
                            color: context.primary,
                          ),
                          onPressed: onRestore,
                        ),
                        IconButton(
                          tooltip: AppLocalizations.of(
                            context,
                          ).deleteForeverTitle,
                          icon: Icon(
                            Iconsax.trash,
                            size: 20,
                            color: context.errorAccent,
                          ),
                          onPressed: onDeleteForever,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Countdown to auto-purge — same visual pattern as [ExpiryChip]
/// (document_chips.dart) but counting down to `deletedAt +
/// DocumentUseCases.trashRetentionPeriod` instead of a user-set expiry
/// date, with urgency thresholds scaled to that (shorter) window.
class _RetentionBadge extends StatelessWidget {
  final DateTime deletedAt;

  const _RetentionBadge({required this.deletedAt});

  @override
  Widget build(BuildContext context) {
    final retention = DocumentUseCases.trashRetentionPeriod;
    final purgeDate = deletedAt.add(retention);
    final daysLeft = purgeDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, retention.inDays);
    final badgeColor = daysLeft <= 3
        ? context.errorAccent
        : daysLeft <= 7
        ? context.warning
        : context.textSecondary;
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: .circular(20),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(Iconsax.timer_1, size: 11, color: badgeColor),
          widthBox(4),
          Text(
            AppLocalizations.of(context).trashRetentionRemaining(daysLeft),
            style: context.labelSmall.copyWith(
              color: badgeColor,
              fontWeight: .w600,
            ),
          ),
        ],
      ),
    );
  }
}
