import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/theme_exports.dart';
import '../../utils/utils_exports.dart';

class SearchableDropdown extends StatefulWidget {
  final List<String> items;
  final String hintText;
  final Function(String) onChanged;
  final TextEditingController controller;
  final Color? fillColor;
  final Color? borderColor;
  final Color? dropdownBackgroundColor;
  final String? Function(String?)? validator;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.hintText = "Select item",
    required this.controller,
    this.fillColor,
    this.borderColor,
    this.dropdownBackgroundColor,
    this.validator,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  bool _isDropdownOpen = false;
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String input) {
    setState(() {
      _filteredItems = widget.items
          .where(
            (item) => item.toLowerCase().contains(input.trim().toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Default colors based on theme
    final defaultFillColor = widget.fillColor ?? context.surface;
    final defaultBorderColor =
        widget.borderColor ?? context.border.withAlpha(50);
    final defaultDropdownBg =
        widget.dropdownBackgroundColor ?? context.surfaceElevated;

    return Column(
      children: [
        // Search Input Field
        TextFormField(
          style: context.bodySmall.copyWith(color: context.textPrimary),
          controller: widget.controller,
          validator: widget.validator,
          onTap: () {
            setState(() {
              _isDropdownOpen = !_isDropdownOpen;
            });
          },
          onChanged: (value) {
            _filterItems(value);
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: context.bodySmall.copyWith(color: context.textSecondary),
            prefixIcon: Icon(Iconsax.map, color: context.grey500, size: 20),
            suffixIcon: Icon(
              _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: context.grey500,
            ),
            fillColor: defaultFillColor,
            filled: true,
            contentPadding: const EdgeInsets.only(left: 10),

            // Default border
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: defaultBorderColor),
            ),

            // Enabled border
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: defaultBorderColor),
            ),

            // Focused border - uses brand color
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.primaryAccent, width: 2),
            ),

            // Error border
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.errorAccent),
            ),

            // Focused error border
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.errorAccent, width: 2),
            ),
          ),
        ),

        // Dropdown List
        if (_isDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: defaultDropdownBg,
              border: Border.all(color: context.border),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: context.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No items found',
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: context.divider,
                    ),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.controller.text == item;

                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        selected: isSelected,
                        selectedTileColor: context.primary.withAlpha(10),
                        title: Text(
                          item,
                          style: context.bodyMedium.copyWith(
                            color: isSelected
                                ? context.primaryAccent
                                : context.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: context.primaryAccent,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          widget.controller.text = item;
                          widget.onChanged(item);
                          setState(() {
                            _isDropdownOpen = false;
                          });
                          context.focusScope.unfocus();
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
