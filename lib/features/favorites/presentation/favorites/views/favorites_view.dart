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
import '../../../../home/home_exports.dart';
import '../../../../../routes/routes_exports.dart';
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
              return Padding(
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
                                  ).fileCount(vm.items.length)
                                : AppLocalizations.of(
                                    context,
                                  ).resultsCount(vm.items.length),
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
                    heightBox(10),
                    Expanded(child: _FavoritesList(vm: vm)),
                  ],
                ),
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
    if (vm.allFavorites.isEmpty) {
      return EmptyStateWidget(
        icon: Iconsax.heart,
        title: AppLocalizations.of(context).noFavoritesYet,
        subtitle: AppLocalizations.of(context).favoritesEmptySubtitle,
      );
    }

    final items = vm.items;

    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Iconsax.document_text,
        title: AppLocalizations.of(context).noDocumentsFound,
        subtitle: AppLocalizations.of(context).nothingMatchesQuery(vm.query),
      );
    }

    if (vm.isGridView) {
      return GridView.builder(
        padding: const .fromLTRB(0, 0, 0, 16),
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
            onTap: () => AppNavigator.pushNamed(
              RouteNames.documentViewer,
              extra: document,
            ),
            onToggleFavorite: () => vm.toggleFavorite(document),
          );
        },
      );
    }

    return ListView.separated(
      padding: const .fromLTRB(0, 0, 0, 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) {
        final document = items[index];
        return DocumentListTile(
          document: document,
          accentColor: categoryIconColor(context, document.category),
          onTap: () => AppNavigator.pushNamed(
            RouteNames.documentViewer,
            extra: document,
          ),
          onToggleFavorite: () => vm.toggleFavorite(document),
        );
      },
    );
  }
}
