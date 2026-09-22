import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Presentational-only for now — no categories feature/local DB exists
/// yet (see CLAUDE.md's "Known mismatches" section), so this is dummy
/// data standing in for what will eventually be a real sqflite-backed
/// Category list.
class CategoryItem {
  final String name;
  final FaIconData icon;
  final int fileCount;

  const CategoryItem({
    required this.name,
    required this.icon,
    required this.fileCount,
  });
}

class HomeViewModel extends ChangeNotifier {
  final List<CategoryItem> categories = const [
    CategoryItem(
      name: 'Bank',
      icon: FontAwesomeIcons.buildingColumns,
      fileCount: 4,
    ),
    CategoryItem(
      name: 'Business Card',
      icon: FontAwesomeIcons.addressCard,
      fileCount: 2,
    ),
    CategoryItem(
      name: 'Contracts',
      icon: FontAwesomeIcons.fileContract,
      fileCount: 6,
    ),
    CategoryItem(
      name: 'Driving License',
      icon: FontAwesomeIcons.idCardClip,
      fileCount: 1,
    ),
    CategoryItem(name: 'ID Card', icon: FontAwesomeIcons.idCard, fileCount: 3),
    CategoryItem(
      name: 'Insurance',
      icon: FontAwesomeIcons.shieldHalved,
      fileCount: 2,
    ),
    CategoryItem(
      name: 'Medical',
      icon: FontAwesomeIcons.stethoscope,
      fileCount: 5,
    ),
    CategoryItem(
      name: 'Passports',
      icon: FontAwesomeIcons.passport,
      fileCount: 1,
    ),
    CategoryItem(
      name: 'Power',
      icon: FontAwesomeIcons.boltLightning,
      fileCount: 3,
    ),
    CategoryItem(
      name: 'Products',
      icon: FontAwesomeIcons.boxesStacked,
      fileCount: 7,
    ),
    CategoryItem(name: 'Tickets', icon: FontAwesomeIcons.ticket, fileCount: 2),
  ];
}
