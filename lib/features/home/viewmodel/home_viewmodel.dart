import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Presentational-only for now — no categories feature/local DB exists
/// yet (see CLAUDE.md's "Known mismatches" section), so this is dummy
/// data standing in for what will eventually be a real sqflite-backed
/// Category list.
class CategoryItem {
  final String name;
  final FaIconData icon;
  final int? fileCount;

  const CategoryItem({required this.name, required this.icon, this.fileCount});
}

class HomeViewModel extends ChangeNotifier {
  bool isGridView = true;

  void setGridView(bool gridView) {
    if (isGridView == gridView) return;
    isGridView = gridView;
    notifyListeners();
  }

  /// Sorted alphabetically regardless of source order below, so the
  /// display order stays correct as categories are added/renamed.
  List<CategoryItem> get categories =>
      List<CategoryItem>.of(_categories)
        ..sort((a, b) => a.name.compareTo(b.name));

  static const List<CategoryItem> _categories = [
    CategoryItem(
      name: 'Bank',
      icon: FontAwesomeIcons.buildingColumns,
      fileCount: 4,
    ),
    CategoryItem(name: 'Business Card', icon: FontAwesomeIcons.addressCard),
    CategoryItem(
      name: 'Contracts',
      icon: FontAwesomeIcons.fileContract,
      fileCount: 6,
    ),
    CategoryItem(
      name: 'Driving License',
      icon: FontAwesomeIcons.idCardClip,
    ),
    CategoryItem(name: 'Education', icon: FontAwesomeIcons.graduationCap),
    CategoryItem(
      name: 'Electricity/Gas',
      icon: FontAwesomeIcons.boltLightning,
    ),
    CategoryItem(name: 'ID Card', icon: FontAwesomeIcons.idCard),
    CategoryItem(name: 'Insurance', icon: FontAwesomeIcons.shieldHalved),
    CategoryItem(name: 'Invoices', icon: FontAwesomeIcons.fileInvoice),
    CategoryItem(
      name: 'Medical',
      icon: FontAwesomeIcons.stethoscope,
      fileCount: 5,
    ),
    CategoryItem(name: 'Passports', icon: FontAwesomeIcons.passport),
    CategoryItem(
      name: 'Products',
      icon: FontAwesomeIcons.boxesStacked,
      fileCount: 7,
    ),
    CategoryItem(
      name: 'Tax Documents',
      icon: FontAwesomeIcons.fileInvoiceDollar,
    ),
    CategoryItem(name: 'Tickets', icon: FontAwesomeIcons.ticket),
  ];
}
