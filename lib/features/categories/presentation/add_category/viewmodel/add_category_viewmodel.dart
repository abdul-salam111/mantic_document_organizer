import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../home/home_exports.dart';

/// No real category data layer exists yet (see CLAUDE.md's "Known
/// mismatches" section), so [submit] writes straight into the shared
/// [CategoryLocalStore] (also used by HomeViewModel) instead of a
/// repository — that's what makes a created/edited category actually show
/// up in Home's category grid rather than just popping the screen. Also
/// doubles as the manage_categories feature's edit screen via
/// [startEditing] — reusing the same name/icon/color form rather than
/// duplicating it.
class AddCategoryViewModel extends ChangeNotifier {
  final CategoryLocalStore _categoryStore;

  AddCategoryViewModel({required CategoryLocalStore categoryStore})
    : _categoryStore = categoryStore;

  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  CategoryItem? _editingCategory;
  bool get isEditing => _editingCategory != null;

  FaIconData _selectedIcon = FontAwesomeIcons.folder;
  FaIconData get selectedIcon => _selectedIcon;

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
    _selectedIcon = category.icon;
    _selectedColor = category.color ?? fallbackColor;
  }

  void selectIcon(FaIconData icon) {
    if (_selectedIcon == icon) return;
    _selectedIcon = icon;
    notifyListeners();
  }

  void selectColor(Color color) {
    if (_selectedColor == color) return;
    _selectedColor = color;
    notifyListeners();
  }

  bool nameExists(String name) =>
      _categoryStore.exists(name, excluding: _editingCategory?.name);

  void submit() {
    final editing = _editingCategory;
    final item = CategoryItem(
      name: nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      fileCount: editing?.fileCount,
    );
    if (editing != null) {
      _categoryStore.updateCategory(editing.name, item);
    } else {
      _categoryStore.addCategory(item);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
