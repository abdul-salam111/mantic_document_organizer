import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
// Imports the viewmodel directly rather than navbar_exports.dart — the
// barrel re-exports NavbarView, which imports every tab feature
// (including this one), so importing it here would create an import cycle.
import '../../../../navbar/viewmodel/navbar_viewmodel.dart';
import '../viewmodels/favorites_viewmodel.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<FavoritesViewModel>(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).favoritesTitle,
          onBackPressed: () => context.read<NavbarViewModel>().selectTab(0),
        ),
        body: SafeArea(
          child: Consumer<FavoritesViewModel>(
            builder: (context, vm, _) {
              if (vm.items.isEmpty) {
                return EmptyStateWidget(
                  icon: Iconsax.heart,
                  title: AppLocalizations.of(context).noFavoritesYet,
                  subtitle: AppLocalizations.of(context).favoritesEmptySubtitle,
                );
              }

              return ListView.separated(
                padding: const .fromLTRB(10, 16, 10, 16),
                itemCount: vm.items.length,
                separatorBuilder: (context, index) => heightBox(10),
                itemBuilder: (context, index) {
                  final item = vm.items[index];
                  return _FavoriteTile(
                    item: item,
                    onUnfavorite: () => vm.removeFavorite(item),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final FavoriteItem item;
  final VoidCallback onUnfavorite;

  const _FavoriteTile({required this.item, required this.onUnfavorite});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(12),
      onTap: () => AppToastsUtils.info(
        AppLocalizations.of(context).comingSoonToast(item.name),
      ),
      child: Container(
        padding: const .symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(12),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: .center,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.1),
                borderRadius: .circular(10),
              ),
              child: FaIcon(item.icon, size: 18, color: context.primary),
            ),
            widthBox(14),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.bodyMedium.copyWith(fontWeight: .w600),
                  ),
                  heightBox(2),
                  Text(
                    item.category,
                    style: context.labelSmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).removeFromFavorites,
              icon: Icon(Iconsax.heart5, color: context.errorAccent, size: 20),
              onPressed: onUnfavorite,
            ),
          ],
        ),
      ),
    );
  }
}
