import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
// Imports the viewmodel directly rather than navbar_exports.dart — the
// barrel re-exports NavbarView, which imports every tab feature
// (including this one), so importing it here would create an import cycle.
import '../../../../navbar/viewmodel/navbar_viewmodel.dart';
import '../viewmodels/search_viewmodel.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SearchViewModel>(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'All Docs',
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
                      hintText: 'Search documents or categories',
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
      child: Column(
        crossAxisAlignment: .start,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: .start,
            dividerColor: context.transparent,
            padding: EdgeInsets.zero,
            labelPadding: const .symmetric(horizontal: 6),
            indicatorSize: .tab,
            indicator: BoxDecoration(
              color: context.primaryAccent,
              borderRadius: .circular(20),
            ),
            labelColor: context.white,
            unselectedLabelColor: context.textSecondary,
            labelStyle: context.labelLarge.copyWith(fontWeight: .w600),
            unselectedLabelStyle: context.labelLarge,
            tabs: [
              for (final category in categories)
                Tab(
                  height: 36,
                  child: Padding(
                    padding: const .symmetric(horizontal: 10),
                    child: Text(category),
                  ),
                ),
            ],
          ),
          heightBox(14),
          Expanded(
            child: TabBarView(
              children: [
                for (final category in categories)
                  _DocumentList(vm: vm, category: category),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  final SearchViewModel vm;
  final String category;

  const _DocumentList({required this.vm, required this.category});

  @override
  Widget build(BuildContext context) {
    final documents = vm.documentsFor(category);

    if (documents.isEmpty) {
      return EmptyStateWidget(
        icon: Iconsax.document_text,
        title: 'No documents found',
        subtitle: vm.query.trim().isEmpty
            ? 'Nothing in "$category" yet'
            : 'Nothing matches "${vm.query}" in "$category"',
      );
    }

    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) =>
          _SearchResultTile(item: documents[index]),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResultItem item;

  const _SearchResultTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(12),
      onTap: () => AppToastsUtils.info('${item.name} — coming soon'),
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
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
