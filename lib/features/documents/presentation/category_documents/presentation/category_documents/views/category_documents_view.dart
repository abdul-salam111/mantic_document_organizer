import 'package:flutter/material.dart';

import '../../../../../../../core/di/di_exports.dart';
import '../../../../../../../core/localization/localization_exports.dart';
import '../../../../../../../core/theme/theme_exports.dart';
import '../../../../../../../core/utils/utils_exports.dart';
import '../../../../../../../core/widgets/widgets_exports.dart';
import '../../../../../../../routes/routes_exports.dart';
import '../../../../../../home/home_exports.dart';
import '../viewmodels/category_documents_viewmodel.dart';

/// Opened by tapping a category tile on Home — lists every [DocumentItem]
/// whose `category` matches [category].name, read live from the shared
/// [DocumentLocalStore] (see CategoryDocumentsViewModel).
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
              category.color ?? categoryIconColor(context, category.name);
          return Scaffold(
            appBar: CustomAppBar(
              title: category.name,
              actions: [_SortMenuButton(vm: vm)],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const .fromLTRB(14, 16, 14, 0),
                    child: CustomSearchField(
                      hintText: AppLocalizations.of(
                        context,
                      ).searchDocumentsHint,
                      onChanged: vm.updateQuery,
                    ),
                  ),
                  heightBox(10),
                  Expanded(
                    child: _DocumentList(vm: vm, color: color),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
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
}

class _SortMenuButton extends StatelessWidget {
  final CategoryDocumentsViewModel vm;

  const _SortMenuButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DocumentSort>(
      tooltip: AppLocalizations.of(context).sortBy,
      icon: Icon(Iconsax.sort, color: context.white),
      onSelected: vm.setSort,
      itemBuilder: (context) => [
        _sortMenuItem(
          context,
          value: DocumentSort.newest,
          label: AppLocalizations.of(context).sortNewestFirst,
        ),
        _sortMenuItem(
          context,
          value: DocumentSort.oldest,
          label: AppLocalizations.of(context).sortOldestFirst,
        ),
        _sortMenuItem(
          context,
          value: DocumentSort.nameAz,
          label: AppLocalizations.of(context).sortNameAZ,
        ),
      ],
    );
  }

  PopupMenuItem<DocumentSort> _sortMenuItem(
    BuildContext context, {
    required DocumentSort value,
    required String label,
  }) {
    final isSelected = vm.sort == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            Iconsax.tick_circle,
            size: 18,
            color: isSelected ? context.primary : context.transparent,
          ),
          widthBox(10),
          Text(
            label,
            style: context.bodyMedium.copyWith(
              fontWeight: isSelected ? .w600 : .normal,
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
        padding: const .symmetric(horizontal: 14),
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

    return ListView.separated(
      padding: const .fromLTRB(14, 0, 14, 90),
      itemCount: documents.length,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) =>
          _DocumentTile(document: documents[index], vm: vm, color: color),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentItem document;
  final CategoryDocumentsViewModel vm;
  final Color color;

  const _DocumentTile({
    required this.document,
    required this.vm,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(14),
      onTap: () => AppToastsUtils.info(
        AppLocalizations.of(context).comingSoonToast(document.title),
      ),
      child: Container(
        padding: const .all(12),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(14),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: .center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: .circular(11),
              ),
              child: FaIcon(document.icon, size: 19, color: color),
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
                    style: context.bodyMedium.copyWith(fontWeight: .w600),
                  ),
                  heightBox(4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.document,
                        size: 12,
                        color: context.textSecondary,
                      ),
                      widthBox(4),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).fileCount(document.filePaths.length),
                        style: context.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      widthBox(8),
                      Text(
                        '•',
                        style: context.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      widthBox(8),
                      Text(
                        document.createdAt.timeAgo,
                        style: context.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (document.tags.isNotEmpty || _showExpiryChip) ...[
                    heightBox(8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (_showExpiryChip) _buildExpiryChip(context),
                        for (final tag in document.tags)
                          _buildTagChip(context, tag),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              visualDensity: .compact,
              tooltip: document.isFavorite
                  ? AppLocalizations.of(context).removeFromFavorites
                  : AppLocalizations.of(context).addToFavorites,
              icon: Icon(
                document.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                size: 20,
                color: document.isFavorite
                    ? context.errorAccent
                    : context.textSecondary,
              ),
              onPressed: () => vm.toggleFavorite(document),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showExpiryChip =>
      document.isExpirable && document.expiryDate != null;

  Widget _buildExpiryChip(BuildContext context) {
    final expiry = document.expiryDate!;
    final daysLeft = expiry.difference(DateTime.now()).inDays;
    final chipColor = daysLeft < 0
        ? context.errorAccent
        : daysLeft <= 30
        ? context.warning
        : context.textSecondary;
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: .circular(20),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(Iconsax.timer_1, size: 11, color: chipColor),
          widthBox(4),
          Text(
            AppLocalizations.of(context).expiresOn(expiry.formatted),
            style: context.labelSmall.copyWith(
              color: chipColor,
              fontWeight: .w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: .circular(20),
        border: Border.all(color: context.border),
      ),
      child: Text(
        tag,
        style: context.labelSmall.copyWith(color: context.textSecondary),
      ),
    );
  }
}
