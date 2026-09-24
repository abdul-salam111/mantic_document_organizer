import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
// Imports the viewmodel directly rather than navbar_exports.dart — the
// barrel re-exports NavbarView, which imports every tab feature
// (including this one), so importing it here would create an import cycle.
import '../../../../navbar/viewmodel/navbar_viewmodel.dart';
import '../../../../home/home_exports.dart';
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
          actions: [
            Consumer<FavoritesViewModel>(
              builder: (context, vm, _) => ViewModeToggle(
                isGridView: vm.isGridView,
                onChanged: vm.setGridView,
                onAppBar: true,
              ),
            ),
            widthBox(10),
            Consumer<FavoritesViewModel>(
              builder: (context, vm, _) => DocumentSortMenuButton(
                selected: vm.sort,
                onSelected: vm.setSort,
              ),
            ),
            widthBox(6),
          ],
        ),
        body: SafeArea(
          child: Consumer<FavoritesViewModel>(
            builder: (context, vm, _) {
              if (vm.allFavorites.isEmpty) {
                return EmptyStateWidget(
                  icon: Iconsax.heart,
                  title: AppLocalizations.of(context).noFavoritesYet,
                  subtitle: AppLocalizations.of(context).favoritesEmptySubtitle,
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const .fromLTRB(10, 16, 10, 0),
                    child: CustomSearchField(
                      hintText: AppLocalizations.of(
                        context,
                      ).searchDocumentsHint,
                      onChanged: vm.updateQuery,
                    ),
                  ),
                  heightBox(10),
                  Expanded(child: _FavoritesList(vm: vm)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final FavoritesViewModel vm;

  const _FavoritesList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = vm.items;

    if (items.isEmpty) {
      return Padding(
        padding: const .symmetric(horizontal: 10),
        child: EmptyStateWidget(
          icon: Iconsax.document_text,
          title: AppLocalizations.of(context).noDocumentsFound,
          subtitle: AppLocalizations.of(context).nothingMatchesQuery(vm.query),
        ),
      );
    }

    if (vm.isGridView) {
      return GridView.builder(
        padding: const .fromLTRB(10, 0, 10, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final document = items[index];
          return DocumentGridTile(
            document: document,
            accentColor: categoryIconColor(context, document.category),
            onTap: () => AppToastsUtils.info(
              AppLocalizations.of(context).comingSoonToast(document.title),
            ),
            onToggleFavorite: () => vm.toggleFavorite(document),
          );
        },
      );
    }

    return ListView.separated(
      padding: const .fromLTRB(10, 0, 10, 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) {
        final document = items[index];
        return DocumentListTile(
          document: document,
          accentColor: categoryIconColor(context, document.category),
          onTap: () => AppToastsUtils.info(
            AppLocalizations.of(context).comingSoonToast(document.title),
          ),
          onToggleFavorite: () => vm.toggleFavorite(document),
        );
      },
    );
  }
}
