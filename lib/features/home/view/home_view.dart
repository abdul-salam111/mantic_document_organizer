import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../../../routes/routes_exports.dart';
import '../../navbar/viewmodel/navbar_viewmodel.dart';
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
                    padding: const .fromLTRB(10, 20, 10, 8),
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
                                tooltip: AppLocalizations.of(
                                  context,
                                ).profileTooltip,
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
                                onPressed: () =>
                                    AppNavigator.pushNamed(RouteNames.profile),
                              ),
                            ],
                          ),
                          heightBox(20),
                          CustomSearchField(
                            hintText: AppLocalizations.of(
                              context,
                            ).homeSearchHint,
                          ),
                          heightBox(14),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context).recentFiles,
                                style: context.titleMedium.copyWith(
                                  fontWeight: .w700,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                borderRadius: .circular(6),
                                // Index 1 = Search, per NavbarView's _tabs order.
                                onTap: () => context
                                    .read<NavbarViewModel>()
                                    .selectTab(1),
                                child: Text(
                                  AppLocalizations.of(context).seeAll,
                                  style: context.labelLarge.copyWith(
                                    color: context.primary,
                                    fontWeight: .w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          heightBox(7),
                          SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: .horizontal,
                              clipBehavior: Clip.none,
                              itemCount: vm.recentFiles.length,
                              separatorBuilder: (context, index) =>
                                  widthBox(12),
                              itemBuilder: (context, index) =>
                                  _RecentFileCard(file: vm.recentFiles[index]),
                            ),
                          ),
                          heightBox(20),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context).categories,
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
                    padding: const .fromLTRB(10, 6, 10, 0),
                    sliver: SliverToBoxAdapter(child: _CategorySection(vm: vm)),
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
  BuildContext context,
  HomeViewModel vm,
  int index, {
  required bool isGridView,
  required Animation<double> reveal,
}) {
  final Widget tile;
  if (index < vm.categories.length) {
    final category = vm.categories[index];
    tile = _CategoryTile(
      name: category.name,
      fileCount: category.fileCount,
      icon: category.icon,
      isGridView: isGridView,
      colorKey: category.name,
    );
  } else if (index == vm.categories.length) {
    tile = _CategoryTile(
      name: AppLocalizations.of(context).uncategorized,
      fileCount: 0,
      icon: FontAwesomeIcons.folder,
      isGridView: isGridView,
    );
  } else {
    tile = _CategoryTile(
      name: AppLocalizations.of(context).newCategory,
      icon: FontAwesomeIcons.circlePlus,
      isAddNew: true,
      isGridView: isGridView,
    );
  }
  return _StaggeredEntry(animation: reveal, index: index, child: tile);
}

/// Fades + slides one grid/list item in, with its start time offset by
/// [index] so items reveal one after another instead of all at once. Capped
/// at [_maxStaggeredItems] so a long category list doesn't push the last
/// tile's start time out unreasonably far.
class _StaggeredEntry extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;

  const _StaggeredEntry({
    required this.animation,
    required this.index,
    required this.child,
  });

  static const int _maxStaggeredItems = 12;
  static const double _staggerWindow = 0.5;

  @override
  Widget build(BuildContext context) {
    final step = index.clamp(0, _maxStaggeredItems) / _maxStaggeredItems;
    final start = step * _staggerWindow;
    final end = start + (1 - _staggerWindow);
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: itemAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(itemAnimation),
        child: child,
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final HomeViewModel vm;

  const _CategorySection({required this.vm});

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _revealController;
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = widget.vm.isGridView;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: 1,
    );
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _CategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vm.isGridView != _isGridView) {
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _isGridView = widget.vm.isGridView);
        _fadeController.value = 1;
        _revealController.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: .topCenter,
      clipBehavior: .none,
      child: FadeTransition(
        opacity: _fadeController,
        child: _isGridView
            ? _CategoryGrid(vm: widget.vm, reveal: _revealController)
            : _CategoryList(vm: widget.vm, reveal: _revealController),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final HomeViewModel vm;
  final Animation<double> reveal;

  const _CategoryGrid({required this.vm, required this.reveal});

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
          _categoryTileAt(context, vm, index, isGridView: true, reveal: reveal),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final HomeViewModel vm;
  final Animation<double> reveal;

  const _CategoryList({required this.vm, required this.reveal});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.categories.length + 2,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) => _categoryTileAt(
        context,
        vm,
        index,
        isGridView: false,
        reveal: reveal,
      ),
    );
  }
}

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

class _RecentFileCard extends StatelessWidget {
  final RecentFileItem file;

  const _RecentFileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    final color = _categoryIconColor(context, file.category);
    return InkWell(
      borderRadius: .circular(14),
      onTap: () => AppToastsUtils.info(
        AppLocalizations.of(context).comingSoonToast(file.name),
      ),
      child: Container(
        width: 110,
        padding: .all(9),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(13),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Container(
              height: 66,
              width: double.infinity,
              alignment: .center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: .circular(9),
              ),
              child: FaIcon(file.icon, size: 26, color: color),
            ),
            heightBox(10),
            Text(
              file.name,
              maxLines: 1,
              overflow: .ellipsis,
              style: context.bodySmall.copyWith(fontWeight: .w600),
            ),
            heightBox(2),
            Text(
              '${file.category} • ${file.timeLabel}',
              maxLines: 1,
              overflow: .ellipsis,
              style: context.labelSmall.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
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
      onTap: () => AppToastsUtils.info(
        AppLocalizations.of(context).comingSoonToast(name),
      ),
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
              FaIcon(icon, size: 22, color: _iconColor(context)),
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

  static const double _listTileHeight = 68;

  Widget _buildList(BuildContext context) {
    return Container(
      height: _listTileHeight,
      padding: .symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isAddNew ? context.transparent : context.surfaceElevated,
        borderRadius: .circular(12),
        border: isAddNew ? Border.all(color: context.border, width: 1.5) : null,
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
              mainAxisAlignment: .center,
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
                    AppLocalizations.of(context).fileCount(fileCount!),
                    style: context.labelSmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          widthBox(8),
          Icon(Iconsax.arrow_right_3, size: 16, color: context.textSecondary),
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
