import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<HomeViewModel>(),
      child: Scaffold(
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            children: [
                              const AppLogo(
                                height: 36,
                                width: 36,
                              ).withRoundedCorners(10),
                              widthBox(10),
                              Text(
                                'Mantic',
                                style: context.titleMedium.copyWith(
                                  color: context.primary,
                                  fontWeight: .bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Profile',
                                style: IconButton.styleFrom(
                                  backgroundColor: context.surface,
                                  fixedSize: const Size(36, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: .circular(10),
                                  ),
                                ),
                                icon: Icon(
                                  Iconsax.profile_circle,
                                  color: context.textPrimary,
                                  size: 20,
                                ),
                                onPressed: () => AppToastsUtils.info(
                                  'Profile — coming soon',
                                ),
                              ),
                            ],
                          ),
                          heightBox(20),
                          const CustomSearchField(hintText: 'Search documents'),
                          heightBox(28),
                          Row(
                            children: [
                              Text(
                                'Categories',
                                style: context.titleMedium.copyWith(
                                  fontWeight: .w700,
                                ),
                              ),
                              const Spacer(),
                              _ViewModeButton(
                                icon: Iconsax.element_3,
                                isSelected: vm.isGridView,
                                onTap: () => vm.setGridView(true),
                              ),
                              widthBox(6),
                              _ViewModeButton(
                                icon: Iconsax.row_vertical,
                                isSelected: !vm.isGridView,
                                onTap: () => vm.setGridView(false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: .symmetric(horizontal: 10),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              ),
                            ),
                        child: vm.isGridView
                            ? _CategoryGrid(
                                key: const ValueKey('grid'),
                                vm: vm,
                              )
                            : _CategoryList(
                                key: const ValueKey('list'),
                                vm: vm,
                              ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _categoryTileAt(
  HomeViewModel vm,
  int index, {
  required bool isGridView,
}) {
  if (index < vm.categories.length) {
    final category = vm.categories[index];
    return _CategoryTile(
      name: category.name,
      fileCount: category.fileCount,
      icon: category.icon,
      isGridView: isGridView,
      colorKey: category.name,
    );
  }
  if (index == vm.categories.length) {
    return _CategoryTile(
      name: 'Uncategorized',
      fileCount: 0,
      icon: FontAwesomeIcons.folder,
      isGridView: isGridView,
    );
  }
  return _CategoryTile(
    name: 'New Category',
    icon: FontAwesomeIcons.circlePlus,
    isAddNew: true,
    isGridView: isGridView,
  );
}

class _CategoryGrid extends StatelessWidget {
  final HomeViewModel vm;

  const _CategoryGrid({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: vm.categories.length + 2,
      itemBuilder: (context, index) =>
          _categoryTileAt(vm, index, isGridView: true),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final HomeViewModel vm;

  const _CategoryList({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.categories.length + 2,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) =>
          _categoryTileAt(vm, index, isGridView: false),
    );
  }
}

/// Each category's icon color is picked to match what it represents,
/// grouped by theme rather than assigned arbitrarily: government ID
/// documents share blue, money-related documents share green, Medical
/// gets red (the one place "danger" red actually reads correctly — a
/// medical cross), legal/protection documents share purple, and
/// energy/billing shares amber. Anything left over falls back to a
/// neutral info blue.
Color _categoryIconColor(BuildContext context, String categoryName) {
  switch (categoryName) {
    case 'Driving License':
    case 'ID Card':
    case 'Passports':
      return context.primary;
    case 'Bank':
    case 'Tax Documents':
      return context.success;
    case 'Medical':
      return context.errorAccent;
    case 'Insurance':
    case 'Products':
      return context.tertiaryLight;
    case 'Contracts':
      return context.tertiary;
    case 'Education':
      return context.secondaryDark;
    case 'Electricity/Gas':
    case 'Invoices':
      return context.warning;
    default:
      return context.info;
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(8),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: .center,
        decoration: BoxDecoration(
          color: isSelected ? context.primary : context.surface,
          borderRadius: .circular(7),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isSelected ? context.white : context.textSecondary,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final int? fileCount;
  final FaIconData icon;
  final bool isAddNew;
  final bool isGridView;
  final String? colorKey;

  const _CategoryTile({
    required this.name,
    required this.icon,
    this.fileCount,
    this.isAddNew = false,
    this.isGridView = true,
    this.colorKey,
  });

  Color _iconColor(BuildContext context) {
    if (isAddNew) return context.primaryAccent;
    if (colorKey == null) return context.textSecondary;
    return _categoryIconColor(context, colorKey!);
  }

  bool get _showBadge => fileCount != null && fileCount! > 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(10),
      onTap: () => AppToastsUtils.info('$name — coming soon'),
      child: isGridView ? _buildGrid(context) : _buildList(context),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: .all(8),
          decoration: BoxDecoration(
            color: isAddNew ? context.transparent : context.surfaceElevated,
            borderRadius: .circular(10),
            border: isAddNew
                ? Border.all(color: context.border, width: 1.5)
                : null,
            boxShadow: isAddNew
                ? null
                : [
                    BoxShadow(
                      color: context.shadow,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              FaIcon(
                icon,
                size: 22,
                color: _iconColor(context),
              ),
              heightBox(6),
              Text(
                name,
                maxLines: 1,
                overflow: .ellipsis,
                textAlign: .center,
                style: context.bodySmall.copyWith(fontWeight: .w600),
              ),
            ],
          ),
        ),
        if (_showBadge)
          Positioned(
            top: 6,
            right: 6,
            child: _CountBadge(count: fileCount!, size: 20),
          ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return Container(
      padding: .symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isAddNew ? context.transparent : context.surfaceElevated,
        borderRadius: .circular(12),
        border: isAddNew
            ? Border.all(color: context.border, width: 1.5)
            : null,
        boxShadow: isAddNew
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
          FaIcon(icon, size: 22, color: _iconColor(context)),
          widthBox(14),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: context.bodyMedium.copyWith(fontWeight: .w600),
                ),
                if (_showBadge) ...[
                  heightBox(4),
                  Text(
                    '$fileCount ${fileCount == 1 ? 'file' : 'files'}',
                    style: context.labelSmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          widthBox(8),
          Icon(
            Iconsax.arrow_right_3,
            size: 16,
            color: context.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final double size;

  const _CountBadge({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: .center,
      decoration: BoxDecoration(
        shape: .circle,
        color: context.background,
        border: Border.all(color: context.border, width: 1),
      ),
      child: Text(
        '$count',
        style: context.labelSmall.copyWith(
          color: context.textSecondary,
          fontWeight: .w600,
        ),
      ),
    );
  }
}
