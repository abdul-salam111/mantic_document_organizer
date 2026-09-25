import 'package:flutter/material.dart';

import '../../../../../../../core/di/di_exports.dart';
import '../../../../../../../core/localization/localization_exports.dart';
import '../../../../../../../core/theme/theme_exports.dart';
import '../../../../../../../core/utils/utils_exports.dart';
import '../../../../../../../core/widgets/widgets_exports.dart';
import '../../../../../../../routes/routes_exports.dart';
import '../../../../../../home/home_exports.dart';
import '../viewmodels/category_documents_viewmodel.dart';

class CategoryDocumentsView extends StatelessWidget {
  final CategoryItem category;

  const CategoryDocumentsView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = sl<CategoryDocumentsViewModel>();
        vm.init(category);
        return vm;
      },
      child: Consumer<CategoryDocumentsViewModel>(
        builder: (context, vm, _) {
          final color =
              category.color ?? categoryIconColor(context, category.name);
          return Scaffold(
            appBar: CustomAppBar(title: category.name),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
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
                                      ).fileCount(vm.documents.length)
                                    : AppLocalizations.of(
                                        context,
                                      ).resultsCount(vm.documents.length),
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
                      ],
                    ),
                  ),
                  heightBox(10),
                  Expanded(
                    child: _DocumentList(vm: vm, color: color),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: AppLocalizations.of(context).addDocumentTitle,
              backgroundColor: color,
              foregroundColor: context.white,
              onPressed: () => AppNavigator.pushNamed(
                RouteNames.addDocument,
                extra: category,
              ),
              child: const Icon(Iconsax.add),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  final CategoryDocumentsViewModel vm;
  final Color color;

  const _DocumentList({required this.vm, required this.color});

  @override
  Widget build(BuildContext context) {
    final documents = vm.documents;

    if (documents.isEmpty) {
      return Padding(
        padding: const .symmetric(horizontal: 10),
        child: EmptyStateWidget(
          icon: Iconsax.document_text,
          title: AppLocalizations.of(context).noDocumentsFound,
          subtitle: vm.query.trim().isEmpty
              ? AppLocalizations.of(
                  context,
                ).nothingInCategoryYet(vm.category.name)
              : AppLocalizations.of(
                  context,
                ).nothingMatchesQueryInCategory(vm.query, vm.category.name),
        ),
      );
    }

    if (vm.isGridView) {
      return GridView.builder(
        padding: const .fromLTRB(10, 0, 10, 90),
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
            accentColor: color,
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
      padding: const .fromLTRB(10, 0, 10, 90),
      itemCount: documents.length,
      separatorBuilder: (context, index) => heightBox(10),
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentListTile(
          document: document,
          accentColor: color,
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
