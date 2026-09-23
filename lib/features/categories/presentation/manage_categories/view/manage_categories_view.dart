import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart';
import '../viewmodel/manage_categories_viewmodel.dart';

class ManageCategoriesView extends StatelessWidget {
  const ManageCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<ManageCategoriesViewModel>(),
      child: Consumer<ManageCategoriesViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: vm.isSelecting
                ? _SelectionAppBar(
                    count: vm.selectedCount,
                    onClose: vm.clearSelection,
                    onDelete: () => _confirmBulkDelete(context, vm),
                  )
                : CustomAppBar(
                    title: AppLocalizations.of(context).manageCategories,
                  ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const .fromLTRB(10, 14, 10, 0),
                    child: CustomSearchField(
                      hintText: AppLocalizations.of(context).searchCategories,
                      onChanged: vm.updateQuery,
                    ),
                  ),
                  Expanded(
                    child: vm.categories.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context).noCategoriesFound,
                              style: context.bodyMedium.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const .symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            itemCount: vm.categories.length,
                            separatorBuilder: (context, index) => heightBox(10),
                            itemBuilder: (context, index) {
                              final category = vm.categories[index];
                              return _CategoryRow(
                                category: category,
                                isSelecting: vm.isSelecting,
                                isSelected: vm.isSelected(category.name),
                                onTap: () {
                                  if (vm.isSelecting) {
                                    vm.toggleSelection(category.name);
                                  }
                                },
                                onLongPress: () =>
                                    vm.toggleSelection(category.name),
                                onEdit: () => AppNavigator.pushNamed(
                                  RouteNames.addCategory,
                                  extra: category,
                                ),
                                onDelete: () =>
                                    _confirmDelete(context, vm, category),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ManageCategoriesViewModel vm,
    CategoryItem category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: Text(AppLocalizations.of(context).deleteCategory),
        content: Text(
          AppLocalizations.of(context).deleteCategoryConfirm(category.name),
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
    vm.deleteCategory(category);
    AppToastsUtils.success(
      AppLocalizations.of(context).categoryDeletedToast(category.name),
    );
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    ManageCategoriesViewModel vm,
  ) async {
    final count = vm.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: Text(AppLocalizations.of(context).deleteCategory),
        content: Text(
          AppLocalizations.of(context).deleteCategoriesConfirm(count),
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
    vm.deleteSelected();
    AppToastsUtils.success(
      AppLocalizations.of(context).categoriesDeletedToast(count),
    );
  }
}

class _SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int count;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _SelectionAppBar({
    required this.count,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.primary,
      iconTheme: IconThemeData(color: context.white),
      leading: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context).selectedCount(count),
        style: context.bodyLarge.copyWith(
          color: context.white,
          fontWeight: .bold,
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CategoryRow extends StatelessWidget {
  final CategoryItem category;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.color ?? categoryIconColor(context, category.name);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: .circular(12),
      child: Container(
        padding: const .symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primary.withValues(alpha: 0.1)
              : context.surfaceElevated,
          borderRadius: .circular(12),
          border: isSelected
              ? Border.all(color: context.primary, width: 1.5)
              : null,
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: context.shadow,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            if (isSelecting)
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? context.primary : context.textSecondary,
                size: 24,
              )
            else
              Container(
                width: 44,
                height: 44,
                alignment: .center,
                decoration: BoxDecoration(color: color, shape: .circle),
                child: FaIcon(category.icon, size: 18, color: context.white),
              ),
            widthBox(12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.bodyMedium.copyWith(fontWeight: .w600),
                  ),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).fileCount(category.fileCount ?? 0),
                    style: context.labelSmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isSelecting) ...[
              IconButton(
                tooltip: AppLocalizations.of(context).editCategory,
                icon: Icon(
                  Iconsax.edit_2,
                  size: 20,
                  color: context.textSecondary,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).deleteCategory,
                icon: Icon(Iconsax.trash, size: 20, color: context.error),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
