import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/theme_utils.dart';
import '../../../../core/utils/utils_exports.dart';
import '../../../../core/widgets/widgets_exports.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routes/routes_exports.dart';
import '../../../home/home_exports.dart';
import '../viewmodel/add_category_viewmodel.dart';
import 'widgets/icon_catalog.dart';

/// Also used as the manage_categories feature's edit screen — pass
/// [category] to prefill the form and switch into edit mode.
class AddCategoryView extends StatelessWidget {
  final CategoryItem? category;

  const AddCategoryView({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = sl<AddCategoryViewModel>();
        final editing = category;
        if (editing != null) {
          vm.startEditing(editing, categoryIconColor(context, editing.name));
        }
        return vm;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: category == null
              ? AppLocalizations.of(context).newCategory
              : AppLocalizations.of(context).editCategory,
        ),
        body: SafeArea(
          child: Consumer<AddCategoryViewModel>(
            builder: (context, vm, _) {
              return Form(
                key: vm.formKey,
                child: ListView(
                  padding: const .all(20),
                  children: [
                    Center(
                      child: _PreviewBadge(
                        icon: vm.selectedIcon,
                        color: vm.selectedColor,
                      ),
                    ),
                    heightBox(28),
                    CustomTextFormField(
                      label: AppLocalizations.of(context).categoryNameLabel,
                      hintText: AppLocalizations.of(context).categoryNameHint,
                      isRequired: true,
                      controller: vm.nameController,
                      textCapitalization: .words,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          ).categoryNameRequired;
                        }
                        if (vm.nameExists(trimmed)) {
                          return AppLocalizations.of(context).categoryNameTaken;
                        }
                        return null;
                      },
                    ),
                    heightBox(24),
                    _IconPickerTrigger(
                      selectedIcon: vm.selectedIcon,
                      activeColor: vm.selectedColor,
                      onTap: () async {
                        final picked = await showModalBottomSheet<FaIconData>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: context.surfaceElevated,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => _IconPickerSheet(
                            selectedIcon: vm.selectedIcon,
                            activeColor: vm.selectedColor,
                          ),
                        );
                        if (picked != null) vm.selectIcon(picked);
                      },
                    ),
                    heightBox(24),
                    _ColorPickerTrigger(
                      selectedColor: vm.selectedColor,
                      onTap: () async {
                        final picked = await showDialog<Color>(
                          context: context,
                          builder: (_) => _ColorPickerDialog(
                            initialColor: vm.selectedColor,
                          ),
                        );
                        if (picked != null) vm.selectColor(picked);
                      },
                    ),
                    heightBox(32),
                    CustomButton(
                      text: vm.isEditing
                          ? AppLocalizations.of(context).save
                          : AppLocalizations.of(context).create,
                      // Writes into the shared CategoryLocalStore (see
                      // AddCategoryViewModel) — no real category data layer
                      // exists yet (CLAUDE.md's "Known mismatches"), so this
                      // is local-only, but it does persist for the session.
                      onPressed: () {
                        if (!vm.formKey.currentState!.validate()) return;
                        final wasEditing = vm.isEditing;
                        vm.submit();
                        // Compute the message (needs this route's context)
                        // and pop *before* showing the toast — another_flushbar
                        // pushes its toast as its own Navigator route, so
                        // popping this screen right on top of that in-flight
                        // push corrupts the navigator's route lifecycle.
                        // AppToastsUtils resolves its own context from the
                        // root navigator key, so it's safe to call after pop.
                        final name = vm.nameController.text.trim();
                        final message = wasEditing
                            ? AppLocalizations.of(
                                context,
                              ).categoryUpdatedToast(name)
                            : AppLocalizations.of(
                                context,
                              ).categoryCreatedToast(name);
                        AppNavigator.pop();
                        AppToastsUtils.success(message);
                      },
                    ),
                    heightBox(20),
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

class _PreviewBadge extends StatelessWidget {
  final FaIconData icon;
  final Color color;

  const _PreviewBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 72,
      height: 72,
      alignment: .center,
      decoration: BoxDecoration(
        color: color,
        shape: .circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FaIcon(icon, size: 30, color: context.white),
    );
  }
}

/// Compact row shown on the form — tapping it opens [_IconPickerSheet].
class _IconPickerTrigger extends StatelessWidget {
  final FaIconData selectedIcon;
  final Color activeColor;
  final VoidCallback onTap;

  const _IconPickerTrigger({
    required this.selectedIcon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Container(
        padding: const .symmetric(horizontal: 16, vertical: 14),
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
              decoration: BoxDecoration(color: activeColor, shape: .circle),
              child: FaIcon(selectedIcon, size: 16, color: context.white),
            ),
            widthBox(12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).chooseIcon,
                style: context.bodyMedium.copyWith(
                  fontWeight: .w600,
                  color: context.textPrimary,
                ),
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 16, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Full-catalog icon picker (1400+ FontAwesome solid icons — see
/// widgets/icon_catalog.dart) shown as a searchable modal sheet, since a
/// set that large only stays usable with a search field, not an inline grid.
class _IconPickerSheet extends StatefulWidget {
  final FaIconData selectedIcon;
  final Color activeColor;

  const _IconPickerSheet({
    required this.selectedIcon,
    required this.activeColor,
  });

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<({FaIconData icon, String keywords})> _results = kIconCatalog;

  void _onSearchChanged(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _results = normalized.isEmpty
          ? kIconCatalog
          : kIconCatalog
                .where((entry) => entry.keywords.contains(normalized))
                .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
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
                AppLocalizations.of(context).chooseIcon,
                style: context.titleMedium.copyWith(fontWeight: .bold),
              ),
              heightBox(12),
              CustomSearchField(
                controller: _searchController,
                hintText: AppLocalizations.of(context).searchIcons,
                onChanged: _onSearchChanged,
              ),
              heightBox(12),
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context).noIconsFound,
                          style: context.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final entry = _results[index];
                          return _IconChoice(
                            icon: entry.icon,
                            isSelected: entry.icon == widget.selectedIcon,
                            activeColor: widget.activeColor,
                            onTap: () => Navigator.of(context).pop(entry.icon),
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

class _IconChoice extends StatelessWidget {
  final FaIconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _IconChoice({
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        alignment: .center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : context.surfaceElevated,
          borderRadius: .circular(12),
          border: isSelected ? null : Border.all(color: context.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: FaIcon(
          icon,
          size: 18,
          color: isSelected ? context.white : context.textSecondary,
        ),
      ),
    );
  }
}

/// Compact row shown on the form — tapping it opens [_ColorPickerDialog].
class _ColorPickerTrigger extends StatelessWidget {
  final Color selectedColor;
  final VoidCallback onTap;

  const _ColorPickerTrigger({required this.selectedColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Container(
        padding: const .symmetric(horizontal: 16, vertical: 14),
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
              decoration: BoxDecoration(
                color: selectedColor,
                shape: .circle,
                border: Border.all(color: context.border),
              ),
            ),
            widthBox(12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).chooseColor,
                style: context.bodyMedium.copyWith(
                  fontWeight: .w600,
                  color: context.textPrimary,
                ),
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 16, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Full HSV color picker (flutter_colorpicker package) shown as a dialog —
/// commits the picked color only when "Done" is tapped, keeping the live
/// preview separate from vm.selectedColor until confirmed.
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _pickedColor = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    // AlertDialog's default insets/content padding otherwise squeeze
    // ColorPicker's default 300px width down further, making the hue
    // slider tiny — shrink both paddings and size the picker to what's
    // actually left so the slider gets real room to use.
    final pickerWidth = (context.screenWidth - 72).clamp(260.0, 420.0);

    return AlertDialog(
      backgroundColor: context.surfaceElevated,
      insetPadding: const .symmetric(horizontal: 16, vertical: 24),
      contentPadding: const .fromLTRB(20, 16, 20, 8),
      title: Text(
        AppLocalizations.of(context).chooseColor,
        style: context.titleMedium,
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _pickedColor,
          onColorChanged: (color) => setState(() => _pickedColor = color),
          enableAlpha: false,
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
          pickerAreaHeightPercent: 0.7,
          colorPickerWidth: pickerWidth,
          labelTypes: const [],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_pickedColor),
          child: Text(AppLocalizations.of(context).done),
        ),
      ],
    );
  }
}
