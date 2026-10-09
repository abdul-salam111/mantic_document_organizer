import 'package:mantic_doc_org/core/utils/persist_action.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/constants_exports.dart';
import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../../../routes/routes_exports.dart';
import '../../navbar/viewmodel/navbar_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/document_cover_thumbnail.dart';
import 'widgets/view_mode_toggle.dart';

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
                                height: 48,
                                width: 48,
                              ).withRoundedCorners(12),
                              widthBox(12),
                              Text(
                                'Dockitly',
                                style: context.titleMedium.copyWith(
                                  color: context.primary,
                                  fontWeight: .bold,
                                ),
                              ),
                            ],
                          ),
                          heightBox(20),
                          Row(
                            children: [
                              Expanded(
                                child: CustomSearchField(
                                  hintText: AppLocalizations.of(
                                    context,
                                  ).homeSearchHint,
                                  readOnly: true,
                                  borderColor: context.border,
                                  // Jumps to the All Docs tab with its own
                                  // search field focused — the AI chat now
                                  // lives behind the dedicated "Ask AI"
                                  // button beside this field instead.
                                  onTap: () => context
                                      .read<NavbarViewModel>()
                                      .selectTab(1, focusSearch: true),
                                ),
                              ),
                              widthBox(8),
                              CustomButton(
                                text: AppLocalizations.of(context).askAi,
                                icon: Iconsax.magicpen,
                                iconSize: 18,
                                iconColor: context.textSecondary,
                                textColor: context.textSecondary,
                                // Matches the search field's own fill color
                                // so the two read as one row — this is a
                                // secondary shortcut, not the primary CTA
                                // on the page, so it shouldn't draw the eye
                                // first.
                                backgroundColor: context.surface,
                                borderColor: context.border,
                                elevation: 0,
                                fontSize: 13,
                                radius: 10,
                                padding: 12,
                                size: const Size(0, 48),
                                onPressed: () => AppNavigator.pushNamed(
                                  RouteNames.aiAssistant,
                                ),
                              ),
                            ],
                          ),
                          heightBox(vm.recentFiles.isNotEmpty ? 14 : 20),
                          if (vm.recentFiles.isNotEmpty) ...[
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
                              height: 80,
                              child: StaggeredReveal(
                                itemCount: vm.recentFiles.length,
                                builder: (context, reveal) =>
                                    ListView.separated(
                                      scrollDirection: .horizontal,
                                      clipBehavior: Clip.none,
                                      itemCount: vm.recentFiles.length,
                                      separatorBuilder: (context, index) =>
                                          widthBox(12),
                                      itemBuilder: (context, index) {
                                        final document = vm.recentFiles[index];
                                        return StaggeredRevealItem(
                                          reveal: reveal,
                                          itemCount: vm.recentFiles.length,
                                          index: index,
                                          beginOffset: const Offset(0.12, 0),
                                          child: _RecentFileCard(
                                            document: document,
                                            onToggleFavorite: () =>
                                                persistAction(
                                                  context,
                                                  () => vm.toggleFavorite(
                                                    document,
                                                  ),
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ),
                            heightBox(20),
                          ],
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context).categories,
                                style: context.titleMedium.copyWith(
                                  fontWeight: .w700,
                                ),
                              ),
                              const Spacer(),
                              ViewModeToggle(
                                isGridView: vm.isGridView,
                                onChanged: vm.setGridView,
                              ),
                            ],
                          ),
                          heightBox(10),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const .symmetric(horizontal: 10),
                      child: _CategorySection(vm: vm),
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
  BuildContext context,
  HomeViewModel vm,
  int index, {
  required bool isGridView,
  required Animation<double> reveal,
  required int itemCount,
}) {
  final Widget tile;
  if (index < vm.categories.length) {
    final category = vm.categories[index];
    tile = _CategoryTile(
      id: category.id,
      name: category.name,
      fileCount: vm.documentCountFor(category.id),
      iconKey: category.iconKey,
      isGridView: isGridView,
      colorKey: category.name,
      color: category.colorValue == null ? null : Color(category.colorValue!),
      isShared: category.isShared,
      memberCount: vm.memberCountFor(category),
      onBadgeTap: category.isShared
          ? () => AppNavigator.pushNamed(
              RouteNames.shareCategory,
              extra: category,
            )
          : null,
    );
  } else if (index == vm.categories.length) {
    tile = _CategoryTile(
      id: uncategorizedCategoryId,
      name: AppLocalizations.of(context).uncategorized,
      fileCount: vm.documentCountFor(uncategorizedCategoryId),
      iconKey: 'solidFolder',
      isGridView: isGridView,
    );
  } else {
    tile = _CategoryTile(
      name: AppLocalizations.of(context).newCategory,
      iconKey: 'circlePlus',
      isAddNew: true,
      isGridView: isGridView,
    );
  }
  return StaggeredRevealItem(
    reveal: reveal,
    itemCount: itemCount,
    index: index,
    child: tile,
  );
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
    // Starts at 0 (not 1) and plays forward once here, so the category
    // grid/list also cascades in on Home's first load — didUpdateWidget
    // below separately replays it (from: 0) on every grid/list toggle.
    // Duration matches StaggeredRevealTiming's own per-item delay math
    // (each tile is a StaggeredRevealItem below) — +2 for the
    // Uncategorized/Add-New tiles appended after the real categories.
    _revealController = AnimationController(
      vsync: this,
      duration: StaggeredRevealTiming.totalDuration(
        widget.vm.categories.length + 2,
      ),
    )..forward();
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: context.screenWidth > 380 ? 15 : 15,
        crossAxisSpacing: context.screenWidth > 380 ? 20 : 15,
        childAspectRatio:0.78,
      ),
      itemCount: vm.categories.length + 2,
      itemBuilder: (context, index) => _categoryTileAt(
        context,
        vm,
        index,
        isGridView: true,
        reveal: reveal,
        itemCount: vm.categories.length + 2,
      ),
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
        itemCount: vm.categories.length + 2,
      ),
    );
  }
}

/// Public (not `_`-prefixed) since manage_categories also needs it to
/// preview a built-in category's implied color when its [CategoryItem]
/// carries no explicit [CategoryItem.color] of its own.
Color categoryIconColor(BuildContext context, String categoryName) {
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

/// Cover on the left (flush to the card's edges, no inset border, so it
/// doesn't read as an undersized icon floating in whitespace), title +
/// metadata on the right. The favorite toggle sits directly on the cover
/// itself (via a nested Stack) with a dark scrim behind it so it stays
/// legible against arbitrary photo content. The category name is dropped
/// in favor of its icon as a small badge in the bottom-right corner —
/// recognized faster by color+icon than read as text at this size.
class _RecentFileCard extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback onToggleFavorite;

  const _RecentFileCard({
    required this.document,
    required this.onToggleFavorite,
  });

  static const double _height = 80;

  @override
  Widget build(BuildContext context) {
    final color = categoryIconColor(context, document.category);
    return InkWell(
      borderRadius: .circular(14),
      onTap: () =>
          AppNavigator.pushNamed(RouteNames.documentViewer, extra: document),
      child: Container(
        width: 210,
        height: _height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.categoryCardSurface,
          borderRadius: .circular(14),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: .stretch,
              children: [
                SizedBox(
                  width: _height,
                  height: _height,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const .all(4),
                        child: DocumentCoverThumbnail(
                          document: document,
                          color: color,
                          width: _height - 8,
                          height: _height - 8,
                          borderRadius: 8,
                          iconSize: 24,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _RecentFileFavoriteBadge(
                          isFavorite: document.isFavorite,
                          onTap: onToggleFavorite,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: PendingSyncBadge(
                          documentId: document.id,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const .fromLTRB(10, 8, 36, 8),
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Text(
                          document.title,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: context.bodySmall.copyWith(fontWeight: .w700),
                        ),
                        _MetaLineWithIcon(
                          icon: Iconsax.document,
                          text: AppLocalizations.of(
                            context,
                          ).fileCount(document.filePaths.length),
                        ),
                        _MetaLineWithIcon(
                          icon: Iconsax.timer_1,
                          text: document.createdAt.timeAgoShort,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              right: 6,
              child: _RecentFileCategoryBadge(
                iconKey: document.iconKey,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sits directly on top of the cover image, so it needs a dark scrim
/// behind it (not the flat soft-fill [DocumentListTile]'s favorite button
/// uses) to stay legible against arbitrary photo content.
class _RecentFileFavoriteBadge extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _RecentFileFavoriteBadge({
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isFavorite
          ? AppLocalizations.of(context).removeFromFavorites
          : AppLocalizations.of(context).addToFavorites,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(12),
        child: Container(
          width: 24,
          height: 24,
          alignment: .center,
          decoration: BoxDecoration(
            color: context.black.withValues(alpha: 0.45),
            shape: .circle,
          ),
          child: Icon(
            isFavorite ? Iconsax.heart5 : Iconsax.heart,
            size: 14,
            color: isFavorite ? context.errorAccent : context.white,
          ),
        ),
      ),
    );
  }
}

/// A small leading icon paired with a metadata line — used for the file
/// count and relative-time rows so they scan faster than plain text.
class _MetaLineWithIcon extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLineWithIcon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Icon(icon, size: 12, color: context.textSecondary),
        widthBox(4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: .ellipsis,
            style: context.labelSmall.copyWith(color: context.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// The category's icon standing in for its name — recognizable at a glance
/// without needing to read text at this card size.
class _RecentFileCategoryBadge extends StatelessWidget {
  final String iconKey;
  final Color color;

  const _RecentFileCategoryBadge({required this.iconKey, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: .center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: .circle,
      ),
      child: FaIcon(iconForKey(iconKey), size: 11, color: color),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String? id;
  final String name;
  final int? fileCount;
  final String iconKey;
  final bool isAddNew;
  final bool isGridView;
  final String? colorKey;
  final Color? color;
  final bool isShared;
  final int? memberCount;
  final VoidCallback? onBadgeTap;

  const _CategoryTile({
    this.id,
    required this.name,
    required this.iconKey,
    this.fileCount,
    this.isAddNew = false,
    this.isGridView = true,
    this.colorKey,
    this.color,
    this.isShared = false,
    this.memberCount,
    this.onBadgeTap,
  });

  Color _iconColor(BuildContext context) {
    if (isAddNew) return context.primaryAccent;
    if (color != null) return color!;
    if (colorKey == null) return context.textSecondary;
    return categoryIconColor(context, colorKey!);
  }

  bool get _showBadge => fileCount != null && fileCount! > 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(10),
      onTap: () {
        if (isAddNew) {
          AppNavigator.pushNamed(RouteNames.addCategory);
          return;
        }
        AppNavigator.pushNamed(
          RouteNames.categoryDocuments,
          extra: CategoryItem(
            id: id ?? uncategorizedCategoryId,
            name: name,
            iconKey: iconKey,
            colorValue: color?.toARGB32(),
          ),
        );
      },
      child: isGridView ? _buildGrid(context) : _buildList(context),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: .infinity,
          child: Column(
            mainAxisAlignment: .start,

            children: [
              Container(
                width: context.screenWidth > 380 ? 65 : 56,
                height: context.screenWidth > 380 ? 65 : 56,
                alignment: .center,
                decoration: BoxDecoration(
                  color: context.categoryCardSurface,
                  borderRadius: .circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.shadow,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FaIcon(
                  iconForKey(iconKey),
                  size: context.screenWidth > 380 ? 30 : 24,
                  color: _iconColor(context),
                ),
              ),
              heightBox(6),
              Text(
                name,
                maxLines: 2,
                overflow: .ellipsis,
                textAlign: .center,
                style: context.bodySmall.copyWith(fontWeight: .w600),
              ),
            ],
          ),
        ),
        if (_showBadge)
          Positioned(
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
        color: isAddNew ? context.transparent : context.categoryCardSurface,
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
          FaIcon(iconForKey(iconKey), size: 22, color: _iconColor(context)),
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
