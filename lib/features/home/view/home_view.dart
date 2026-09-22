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
                    padding: .symmetric(horizontal: 10, vertical: 20),
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
                          Text(
                            'Categories',
                            style: context.titleMedium.copyWith(
                              fontWeight: .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: .symmetric(horizontal: 10),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < vm.categories.length) {
                            final category = vm.categories[index];
                            return _CategoryTile(
                              name: category.name,
                              fileCount: category.fileCount,
                              icon: category.icon,
                            );
                          }
                          if (index == vm.categories.length) {
                            return const _CategoryTile(
                              name: 'Uncategorized',
                              fileCount: 0,
                              icon: FontAwesomeIcons.folder,
                            );
                          }
                          return const _CategoryTile(
                            name: 'New Category',
                            icon: FontAwesomeIcons.circlePlus,
                            isAddNew: true,
                          );
                        },
                        childCount: vm.categories.length + 2,
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

class _CategoryTile extends StatelessWidget {
  final String name;
  final int? fileCount;
  final FaIconData icon;
  final bool isAddNew;

  const _CategoryTile({
    required this.name,
    required this.icon,
    this.fileCount,
    this.isAddNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(10),
      onTap: () => AppToastsUtils.info('$name — coming soon'),
      child: Container(
        width: double.infinity,
        padding: .all(10),
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
              color: isAddNew ? context.primaryAccent : context.primary,
            ),
            heightBox(6),
            Text(
              name,
              maxLines: 1,
              overflow: .ellipsis,
              textAlign: .center,
              style: context.bodySmall.copyWith(fontWeight: .w600),
            ),
            if (fileCount != null) ...[
              heightBox(1),
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
    );
  }
}
