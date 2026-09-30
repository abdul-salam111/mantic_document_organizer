import '../../../../documents/domain/entities/document_item.dart'
    show generateLocalId;
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../core/constants/constants_exports.dart';
import '../../../../../core/theme/theme_exports.dart';

class AddCategoryViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;

  AddCategoryViewModel({required CategoryUseCases categoryUseCases})
    : _categoryUseCases = categoryUseCases;

  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  CategoryItem? _editingCategory;
  bool get isEditing => _editingCategory != null;

  String _selectedIconKey = 'solidFolder';

  /// Resolved on demand from [_selectedIconKey] rather than stored
  /// separately — the icon key is the only thing that ever gets persisted
  /// (see [CategoryItem.iconKey]), so there's exactly one source of truth.
  FaIconData get selectedIcon => iconForKey(_selectedIconKey);

  Color _selectedColor = AppColors.primary;
  Color get selectedColor => _selectedColor;

  /// Prefills the form for editing an existing category. [fallbackColor]
  /// is used when [category] has no explicit [CategoryItem.color] of its
  /// own (built-in categories derive their color from categoryIconColor
  /// by name instead) — called once, before the form is first shown, so
  /// there's no listener yet and no need to notify.
  void startEditing(CategoryItem category, Color fallbackColor) {
    _editingCategory = category;
    nameController.text = category.name;
    _selectedIconKey = category.iconKey;
    _selectedColor =
        (category.colorValue == null ? null : Color(category.colorValue!)) ??
        fallbackColor;
  }

  void selectIcon(String iconKey) {
    if (_selectedIconKey == iconKey) return;
    _selectedIconKey = iconKey;
    notifyListeners();
  }

  void selectColor(Color color) {
    if (_selectedColor == color) return;
    _selectedColor = color;
    notifyListeners();
  }

  bool nameExists(String name) =>
      _categoryUseCases.exists(name, excludingId: _editingCategory?.id);

  bool _isSaving = false;
  bool get isSaving => _isSaving;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> submit() async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();
    try {
      final editing = _editingCategory;
      final item = CategoryItem(
        id: editing?.id ?? generateLocalId(),
        name: nameController.text.trim(),
        iconKey: _selectedIconKey,
        colorValue: _selectedColor.toARGB32(),
      );
      if (editing != null) {
        await _categoryUseCases.updateCategory(editing.id, item);
      } else {
        await _categoryUseCases.addCategory(item);
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    super.dispose();
  }
}
