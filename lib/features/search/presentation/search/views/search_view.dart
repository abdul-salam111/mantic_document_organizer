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
import '../viewmodels/search_viewmodel.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SearchViewModel>(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).allDocsTitle,
          onBackPressed: () => context.read<NavbarViewModel>().selectTab(0),
        ),
        body: SafeArea(
          child: Consumer<SearchViewModel>(
            builder: (context, vm, _) {
              return Padding(
                padding: const .fromLTRB(10, 16, 10, 0),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CustomSearchField(
                      hintText: AppLocalizations.of(context).allDocsSearchHint,
                      onChanged: vm.updateQuery,
                    ),
                    heightBox(14),
                    Expanded(child: _CategoryTabs(vm: vm)),
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

class _CategoryTabs extends StatelessWidget {
  final SearchViewModel vm;

  const _CategoryTabs({required this.vm});

  @override
  Widget build(BuildContext context) {
    final categories = vm.categoryTabs;
    return DefaultTabController(
      length: categories.length,
      child: Builder(
        builder: (context) {
          // TabBar's own `indicator` only decorates the selected tab —
          // unselected tabs get an outline here by listening to the
          // controller directly and giving every non-selected Tab its own
          // bordered container, so they read as outlined chips rather than
          // bare text.
          final controller = DefaultTabController.of(context);
          return Column(
            crossAxisAlignment: .start,
            children: [
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) => TabBar(
                  isScrollable: true,
                  tabAlignment: .start,
                  dividerColor: context.transparent,
                  padding: EdgeInsets.zero,
                  labelPadding: const .symmetric(horizontal: 4),
                  indicatorSize: .tab,
                  indicator: BoxDecoration(
                    color: context.primaryAccent,
                    borderRadius: .circular(16),
                  ),
                  labelColor: context.white,
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: context.labelSmall.copyWith(fontWeight: .w600),
                  unselectedLabelStyle: context.labelSmall,
                  tabs: [
                    for (var i = 0; i < categories.length; i++)
                      Tab(
                        height: 28,
                        child: Container(
                          alignment: .center,
                          padding: const .symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: .circular(16),
                            border: controller.index == i
                                ? null
                                : Border.all(color: context.border),
                          ),
                          child: Text(_categoryLabel(context, categories[i])),
                        ),
                      ),
                  ],
                ),
              ),
              heightBox(10),
              // Rebuilds on tab switch too (not just vm changes) since the
              // result count is scoped to whichever category is selected.
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final count = vm
                      .documentsFor(categories[controller.index])
                      .length;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          vm.query.trim().isEmpty
                              ? AppLocalizations.of(context).fileCount(count)
                              : AppLocalizations.of(
                                  context,
                                ).resultsCount(count),
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
                      widthBox(10),
                      DocumentSortMenuButton(
                        selected: vm.sort,
                        onSelected: vm.setSort,
                        onAppBar: false,
                      ),
                    ],
                  );
                },
              ),
              heightBox(10),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final category in categories)
                      _DocumentList(vm: vm, category: category),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Displays [category] as-is, unless it's the sentinel
/// [SearchViewModel.allCategoryTab] — that one gets swapped for the
/// localized "All" label instead of showing the raw English sentinel.
String _categoryLabel(BuildContext context, String category) {
  return category == SearchViewModel.allCategoryTab
      ? AppLocalizations.of(context).allCategoryTab
      : category;
}

class _DocumentList extends StatelessWidget {
  final SearchViewModel vm;
  final String category;

  const _DocumentList({required this.vm, required this.category});

  @override
  Widget build(BuildContext context) {
    final documents = vm.documentsFor(category);

    if (documents.isEmpty) {
      final label = _categoryLabel(context, category);
      return EmptyStateWidget(
        icon: Iconsax.document_text,
        title: AppLocalizations.of(context).noDocumentsFound,
        subtitle: vm.query.trim().isEmpty
            ? AppLocalizations.of(context).nothingInCategoryYet(label)
            : AppLocalizations.of(
                context,
              ).nothingMatchesQueryInCategory(vm.query, label),
      );
    }

    if (vm.isGridView) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
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
      itemCount: documents.length,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) {
        final document = documents[index];
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
