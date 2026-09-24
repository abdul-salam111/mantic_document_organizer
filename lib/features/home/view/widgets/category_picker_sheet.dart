import 'package:flutter/material.dart';

import '../../../../core/localization/localization_exports.dart';
import '../../../../core/theme/theme_exports.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../home_view.dart' show categoryIconColor;
import '../../viewmodel/home_viewmodel.dart';

/// Draggable bottom sheet listing every [CategoryItem], highlighting
/// [selected] — pops the tapped [CategoryItem]. Shared by add_document's
/// category field and document_viewer's "Move" action so both pick from
/// categories the same way instead of each screen carrying its own copy.
class CategoryPickerSheet extends StatelessWidget {
  final List<CategoryItem> categories;
  final CategoryItem? selected;

  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const .fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: .circular(2),
                ),
              ),
              heightBox(16),
              Text(
                AppLocalizations.of(context).selectCategory,
                style: context.titleMedium.copyWith(fontWeight: .bold),
              ),
              heightBox(12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => heightBox(8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.id == selected?.id;
                    final color =
                        category.color ??
                        categoryIconColor(context, category.name);
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(category),
                      borderRadius: .circular(12),
                      child: Container(
                        padding: const .symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.primary.withValues(alpha: 0.1)
                              : context.surface,
                          borderRadius: .circular(12),
                          border: isSelected
                              ? Border.all(color: context.primary, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: .center,
                              decoration: BoxDecoration(
                                color: color,
                                shape: .circle,
                              ),
                              child: FaIcon(
                                category.icon,
                                size: 14,
                                color: context.white,
                              ),
                            ),
                            widthBox(12),
                            Expanded(
                              child: Text(
                                category.name,
                                style: context.bodyMedium.copyWith(
                                  fontWeight: .w600,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: context.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
