import 'package:flutter/material.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';

import '../../../../core/constants/constants_exports.dart';
import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../home_view.dart' show categoryIconColor;

/// A searchable, draggable category picker shared by document creation and
/// the document viewer's move action.
class CategoryPickerSheet extends StatefulWidget {
  final List<CategoryItem> categories;
  final CategoryItem? selected;

  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selected,
  });

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  final _searchController = TextEditingController();

  String get _query => _searchController.text.trim().toLowerCase();

  List<CategoryItem> get _visibleCategories {
    if (_query.isEmpty) return widget.categories;
    return widget.categories
        .where((category) => category.name.toLowerCase().contains(_query))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final categories = _visibleCategories;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              heightBox(14),
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      localizations.selectCategory,
                      textAlign: TextAlign.center,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: context.textSecondary,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                  ),
                ],
              ),
              heightBox(16),
              SizedBox(
                height: 52,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  style: context.bodyMedium,
                  decoration: InputDecoration(
                    hintText: localizations.searchCategories,
                    hintStyle: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      size: 20,
                      color: context.textSecondary,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: context.textSecondary,
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                          ),
                    filled: true,
                    fillColor: context.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: _searchBorder(context),
                    enabledBorder: _searchBorder(context),
                    focusedBorder: _searchBorder(
                      context,
                      color: context.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              heightBox(16),
              Expanded(
                child: categories.isEmpty
                    ? _EmptySearchState(
                        message: localizations.noCategoriesFound,
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.1,
                            ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) => _CategoryTile(
                          category: categories[index],
                          selected: categories[index].id == widget.selected?.id,
                          onTap: () =>
                              Navigator.of(context).pop(categories[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _searchBorder(
    BuildContext context, {
    Color? color,
    double width = 1,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color ?? context.border, width: width),
  );
}

class _CategoryTile extends StatelessWidget {
  final CategoryItem category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        (category.colorValue == null ? null : Color(category.colorValue!)) ??
        categoryIconColor(context, category.name);

    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? context.primary.withValues(alpha: 0.09)
                    : context.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? context.primary : context.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(iconForKey(category.iconKey), size: 22, color: color),
                  heightBox(6),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: context.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String message;

  const _EmptySearchState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded, size: 36, color: context.textSecondary),
        heightBox(10),
        Text(
          message,
          style: context.bodyMedium.copyWith(color: context.textSecondary),
        ),
      ],
    ),
  );
}
