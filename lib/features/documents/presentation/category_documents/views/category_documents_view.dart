import 'package:mantic_doc_org/core/utils/persist_action.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart';
import '../viewmodels/category_documents_viewmodel.dart';

class CategoryDocumentsView extends StatelessWidget {
  final CategoryItem category;

  const CategoryDocumentsView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = sl<CategoryDocumentsViewModel>();
        vm.init(category);
        return vm;
      },
      child: Consumer<CategoryDocumentsViewModel>(
        builder: (context, vm, _) {
          final color =
              (category.colorValue == null
                  ? null
                  : Color(category.colorValue!)) ??
              categoryIconColor(context, category.name);
          return Scaffold(
            appBar: vm.isSelecting
                ? SelectionAppBar(
                    count: vm.selectedCount,
                    onClose: vm.clearSelection,
                    onDelete: () => _confirmTrashSelected(context, vm),
                  )
                : CustomAppBar(title: category.name),
            body: SafeArea(
              child: Column(
                children: [
                  if (category.isViewerOnly) const _ViewerOnlyBanner(),
                  Padding(
                    padding: const .fromLTRB(10, 16, 10, 0),
                    child: Column(
                      children: [
                        CustomSearchField(
                          hintText: AppLocalizations.of(
                            context,
                          ).searchDocumentsHint,
                          onChanged: vm.updateQuery,
                        ),
                        heightBox(10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                vm.query.trim().isEmpty
                                    ? AppLocalizations.of(
                                        context,
                                      ).fileCount(vm.documents.length)
                                    : AppLocalizations.of(
                                        context,
                                      ).resultsCount(vm.documents.length),
                                style: context.labelSmall.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                            ViewModeToggle(
                              isGridView: vm.isGridView,
                              onChanged: vm.setGridView,
                              onAppBar: false,
                            ),
                            DocumentSortMenuButton(
                              selected: vm.sort,
                              onSelected: vm.setSort,
                              onAppBar: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  heightBox(10),
                  Expanded(
                    child: _DocumentList(vm: vm, color: color),
                  ),
                ],
              ),
            ),
            floatingActionButton: vm.isSelecting || category.isViewerOnly
                ? null
                : FloatingActionButton(
                    tooltip: AppLocalizations.of(context).addDocumentTitle,
                    backgroundColor: color,
                    foregroundColor: context.white,
                    onPressed: () => AppNavigator.pushNamed(
                      RouteNames.addDocument,
                      extra: category,
                    ),
                    child: const Icon(Iconsax.add),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _confirmTrashSelected(
    BuildContext context,
    CategoryDocumentsViewModel vm,
  ) async {
    final count = vm.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: Text(AppLocalizations.of(context).deleteDocument),
        content: Text(
          AppLocalizations.of(context).trashDocumentsConfirm(
            count,
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
    if (!await persistAction(context, vm.trashSelected)) return;
    if (!context.mounted) return;
    AppToastsUtils.success(
      AppLocalizations.of(context).documentsTrashedToast(count),
    );
  }
}

/// Seen once, not a repeatedly-tapped dead button -- per
/// docs/space_sharing_ux_plan.txt §4, a disabled "+" invites frustrated
/// taps where an explanatory banner is understood immediately.
class _ViewerOnlyBanner extends StatelessWidget {
  const _ViewerOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Iconsax.eye, size: 16, color: context.textSecondary),
          widthBox(8),
          Expanded(
            child: Text(
              'You have view-only access to this category.',
              style: context.labelSmall.copyWith(color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  final CategoryDocumentsViewModel vm;
  final Color color;

  const _DocumentList({required this.vm, required this.color});

  @override
  Widget build(BuildContext context) {
    final documents = vm.documents;

    if (documents.isEmpty) {
      return Padding(
        padding: const .symmetric(horizontal: 10),
        child: EmptyStateWidget(
          icon: Iconsax.document_text,
          title: AppLocalizations.of(context).noDocumentsFound,
          subtitle: vm.query.trim().isEmpty
              ? AppLocalizations.of(
                  context,
                ).nothingInCategoryYet(vm.category.name)
              : AppLocalizations.of(
                  context,
                ).nothingMatchesQueryInCategory(vm.query, vm.category.name),
        ),
      );
    }

    if (vm.isGridView) {
      return StaggeredReveal(
        itemCount: documents.length,
        builder: (context, reveal) => GridView.builder(
          padding: const .fromLTRB(10, 0, 10, 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            return StaggeredRevealItem(
              reveal: reveal,
              itemCount: documents.length,
              index: index,
              child: DocumentGridTile(
                document: document,
                accentColor: color,
                onTap: () => vm.isSelecting
                    ? vm.toggleSelection(document.id)
                    : AppNavigator.pushNamed(
                        RouteNames.documentViewer,
                        extra: document,
                      ),
                onToggleFavorite: () =>
                    persistAction(context, () => vm.toggleFavorite(document)),
                onLongPress: () => vm.toggleSelection(document.id),
                isSelecting: vm.isSelecting,
                isSelected: vm.isSelected(document.id),
              ),
            );
          },
        ),
      );
    }

    return StaggeredReveal(
      itemCount: documents.length,
      builder: (context, reveal) => ListView.separated(
        padding: const .fromLTRB(10, 0, 10, 90),
        itemCount: documents.length,
        separatorBuilder: (context, index) => heightBox(10),
        itemBuilder: (context, index) {
          final document = documents[index];
          return StaggeredRevealItem(
            reveal: reveal,
            itemCount: documents.length,
            index: index,
            child: DocumentListTile(
              document: document,
              accentColor: color,
              onTap: () => vm.isSelecting
                  ? vm.toggleSelection(document.id)
                  : AppNavigator.pushNamed(
                      RouteNames.documentViewer,
                      extra: document,
                    ),
              onToggleFavorite: () =>
                  persistAction(context, () => vm.toggleFavorite(document)),
              onLongPress: () => vm.toggleSelection(document.id),
              isSelecting: vm.isSelecting,
              isSelected: vm.isSelected(document.id),
            ),
          );
        },
      ),
    );
  }
}
