import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/theme_exports.dart';
import '../../home/home_exports.dart';

/// No real category data layer exists yet (see CLAUDE.md's "Known
/// mismatches" section), so [createCategory] writes straight into the
/// shared [CategoryLocalStore] (also used by HomeViewModel) instead of a
/// repository — that's what makes a created category actually show up in
/// Home's category grid rather than just popping the screen.
class AddCategoryViewModel extends ChangeNotifier {
  final CategoryLocalStore _categoryStore;

  AddCategoryViewModel({required CategoryLocalStore categoryStore})
    : _categoryStore = categoryStore;

  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  FaIconData _selectedIcon = FontAwesomeIcons.folder;
  FaIconData get selectedIcon => _selectedIcon;

  Color _selectedColor = AppColors.primary;
  Color get selectedColor => _selectedColor;

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

  bool nameExists(String name) => _categoryStore.exists(name);

  void createCategory() {
    _categoryStore.addCategory(
      CategoryItem(
        name: nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
