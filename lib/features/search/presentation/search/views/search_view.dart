import 'package:mantic_doc_org/core/utils/persist_action.dart';
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
import '../viewmodels/search_viewmodel.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final FocusNode _searchFocusNode = FocusNode();
  NavbarViewModel? _navbarViewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navbarViewModel = context.read<NavbarViewModel>();
    if (_navbarViewModel != navbarViewModel) {
      _navbarViewModel?.removeListener(_onNavbarChanged);
      _navbarViewModel = navbarViewModel..addListener(_onNavbarChanged);
    }
  }

  // Home's search field switches to this tab via NavbarViewModel.selectTab
  // with focusSearch: true, so autofocusing here (rather than taking an
  // `autofocus` constructor param) works regardless of whether this tab
  // was already built/mounted by the IndexedStack.
  void _onNavbarChanged() {
    final navbarViewModel = _navbarViewModel;
    if (navbarViewModel == null) return;
    if (navbarViewModel.selectedIndex == 1 &&
        navbarViewModel.consumeFocusSearchPending()) {
      // Deferred a frame: Home's own (readOnly) field still requests focus
      // for itself as part of handling the same tap, after its onTap
      // callback runs — requesting focus here synchronously would lose
      // that race and get overridden right back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _navbarViewModel?.removeListener(_onNavbarChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SearchViewModel>(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).allDocsTitle,
          onBackPressed: () => context.read<NavbarViewModel>().selectTab(0),
          backgroundColor: context.background,
          foregroundColor: context.textPrimary,
        ),
        backgroundColor: context.background,
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
                      focusNode: _searchFocusNode,
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
                      widthBox(10),
                      _FilterButton(vm: vm),
                    ],
                  );
                },
              ),
              heightBox(10),
              Expanded(
                child: TabBarView(
                  children: [
                    for (var i = 0; i < categories.length; i++)
                      // TabBarView keeps the pages adjacent to the current
                      // one built (so swiping between them is smooth),
                      // which means a document under e.g. "Bank" renders
                      // in both the "All" page and the "Bank" page at
                      // once. HeroMode(enabled: false) keeps every page
                      // but the selected one out of Hero tag discovery, so
                      // that doesn't collide with the one tag each
                      // document's cover actually registers on the active
                      // page. AnimatedBuilder (rather than computing
                      // `enabled` once per build) keeps this correct while
                      // swiping, without rebuilding the document list
                      // itself on every frame of the swipe — only the
                      // cheap HeroMode wrapper does.
                      AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) =>
                            HeroMode(enabled: controller.index == i, child: child!),
                        child: _DocumentList(
                          vm: vm,
                          category: categories[i],
                        ),
                      ),
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
    final matches = vm.documentsFor(category);

    if (matches.isEmpty) {
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
      return StaggeredReveal(
        itemCount: matches.length,
        builder: (context, reveal) => GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final document = matches[index].document;
            return StaggeredRevealItem(
              reveal: reveal,
              itemCount: matches.length,
              index: index,
              child: DocumentGridTile(
                document: document,
                accentColor: categoryIconColor(context, document.category),
                onTap: () => AppNavigator.pushNamed(
                  RouteNames.documentViewer,
                  extra: document,
                ),
                onToggleFavorite: () =>
                    persistAction(context, () => vm.toggleFavorite(document)),
              ),
            );
          },
        ),
      );
    }

    return StaggeredReveal(
      itemCount: matches.length,
      builder: (context, reveal) => ListView.separated(
        itemCount: matches.length,
        separatorBuilder: (context, index) => heightBox(10),
        itemBuilder: (context, index) {
          final match = matches[index];
          final document = match.document;
          return StaggeredRevealItem(
            reveal: reveal,
            itemCount: matches.length,
            index: index,
            child: DocumentListTile(
              document: document,
              accentColor: categoryIconColor(context, document.category),
              onTap: () => AppNavigator.pushNamed(
                RouteNames.documentViewer,
                extra: document,
              ),
              onToggleFavorite: () =>
                  persistAction(context, () => vm.toggleFavorite(document)),
              matchExcerpt: match.excerpt,
              highlightQuery: vm.query,
            ),
          );
        },
      ),
    );
  }
}

/// Opens [_FilterSheet] — a small red dot shows whenever a file-type/
/// expiry/date filter is active, since the icon alone doesn't say so at a
/// glance the way the sort/view-mode buttons next to it don't need to.
class _FilterButton extends StatelessWidget {
  final SearchViewModel vm;

  const _FilterButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) => InkWell(
        borderRadius: .circular(8),
        onTap: () => _showFilterSheet(context, vm),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Iconsax.filter, size: 20, color: context.textPrimary),
            if (vm.hasActiveFilters)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.errorAccent,
                    shape: .circle,
                    border: Border.all(color: context.background, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showFilterSheet(BuildContext context, SearchViewModel vm) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: .vertical(top: .circular(20)),
    ),
    builder: (sheetContext) => _FilterSheet(vm: vm),
  );
}

class _FilterSheet extends StatelessWidget {
  final SearchViewModel vm;

  const _FilterSheet({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const .fromLTRB(16, 12, 16, 24),
        child: AnimatedBuilder(
          animation: vm,
          builder: (context, _) => Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const .only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: .circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: context.titleMedium.copyWith(fontWeight: .w700),
                    ),
                  ),
                  if (vm.hasActiveFilters)
                    TextButton(
                      onPressed: vm.clearFilters,
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              heightBox(16),
              Text(
                'File type',
                style: context.labelLarge.copyWith(fontWeight: .w600),
              ),
              heightBox(10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in DocumentFileTypeFilter.values)
                    _FilterChip(
                      label: _fileTypeLabel(filter),
                      selected: vm.fileTypeFilter == filter,
                      onTap: () => vm.setFileTypeFilter(filter),
                    ),
                ],
              ),
              heightBox(20),
              Text(
                'Expiry',
                style: context.labelLarge.copyWith(fontWeight: .w600),
              ),
              heightBox(10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in DocumentExpiryFilter.values)
                    _FilterChip(
                      label: _expiryLabel(filter),
                      selected: vm.expiryFilter == filter,
                      onTap: () => vm.setExpiryFilter(filter),
                    ),
                ],
              ),
              heightBox(20),
              Text(
                'Date added',
                style: context.labelLarge.copyWith(fontWeight: .w600),
              ),
              heightBox(10),
              _DateRangeTile(vm: vm),
              heightBox(20),
              CustomButton(
                text: 'Done',
                radius: 14,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fileTypeLabel(DocumentFileTypeFilter filter) => switch (filter) {
  DocumentFileTypeFilter.all => 'All',
  DocumentFileTypeFilter.images => 'Images',
  DocumentFileTypeFilter.pdfs => 'PDFs',
  DocumentFileTypeFilter.other => 'Other',
};

String _expiryLabel(DocumentExpiryFilter filter) => switch (filter) {
  DocumentExpiryFilter.all => 'All',
  DocumentExpiryFilter.expiringSoon => 'Expiring soon',
  DocumentExpiryFilter.expired => 'Expired',
  DocumentExpiryFilter.noExpiry => 'No expiry',
};

/// An outlined chip when unselected, filled when selected — same visual
/// language [_CategoryTabs] already uses for its own tabs, reused here
/// instead of inventing a second "chip" look for the same screen.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: .circular(16),
      onTap: onTap,
      child: Container(
        padding: const .symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.primaryAccent : context.transparent,
          borderRadius: .circular(16),
          border: selected ? null : Border.all(color: context.border),
        ),
        child: Text(
          label,
          style: context.labelSmall.copyWith(
            color: selected ? context.white : context.textPrimary,
            fontWeight: selected ? .w600 : .normal,
          ),
        ),
      ),
    );
  }
}

/// Shows the active date range (tap to change it via the platform's own
/// range picker — fully offline, no network involved) or "Any time" with
/// nothing to clear when none is set.
class _DateRangeTile extends StatelessWidget {
  final SearchViewModel vm;

  const _DateRangeTile({required this.vm});

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: vm.dateRange,
    );
    if (picked != null) vm.setDateRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final range = vm.dateRange;
    final label = range == null
        ? 'Any time'
        : '${range.start.formatted} – ${range.end.formatted}';
    return InkWell(
      borderRadius: .circular(12),
      onTap: () => _pickRange(context),
      child: Container(
        padding: const .symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: .circular(12),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar_1, size: 18, color: context.textSecondary),
            widthBox(10),
            Expanded(
              child: Text(label, style: context.bodyMedium),
            ),
            if (range != null)
              InkWell(
                borderRadius: .circular(12),
                onTap: () => vm.setDateRange(null),
                child: Icon(
                  Iconsax.close_circle,
                  size: 18,
                  color: context.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
