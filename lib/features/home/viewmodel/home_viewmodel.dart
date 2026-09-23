import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/utils/utils_exports.dart';

/// Presentational-only for now — no categories feature/local DB exists
/// yet (see CLAUDE.md's "Known mismatches" section), so this is dummy
/// data standing in for what will eventually be a real sqflite-backed
/// Category list. [color] is only ever set by custom categories created
/// via the add_category feature — built-ins keep deriving their color
/// from `categoryIconColor` in home_view.dart.
class CategoryItem {
  final String name;
  final FaIconData icon;
  final Color? color;
  final int? fileCount;

  const CategoryItem({
    required this.name,
    required this.icon,
    this.color,
    this.fileCount,
  });
}

/// Presentational-only for now, same as [CategoryItem] — standing in for
/// what will eventually be the most-recently-added/edited Document rows.
class RecentFileItem {
  final String name;
  final String category;
  final FaIconData icon;
  final String timeLabel;

  const RecentFileItem({
    required this.name,
    required this.category,
    required this.icon,
    required this.timeLabel,
  });
}

/// Presentation-only for now, same reasoning as [CategoryItem] — a
/// document created via the add_document feature, standing in for a real
/// sqflite-backed Document row (see CLAUDE.md's "Known mismatches").
class DocumentItem {
  final String title;
  final String category;
  final FaIconData icon;
  final List<String> tags;
  final bool isFavorite;
  final List<String> filePaths;
  final DateTime createdAt;

  const DocumentItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.createdAt,
    this.tags = const [],
    this.isFavorite = false,
    this.filePaths = const [],
  });
}

/// Single shared in-memory stand-in for the local Document table (see
/// CLAUDE.md's "Known mismatches" section) — registered as a lazy
/// singleton so a document added from the add_document feature actually
/// shows up in Home's Recent Files strip instead of vanishing once that
/// screen is popped.
class DocumentLocalStore extends ChangeNotifier {
  final List<DocumentItem> _documents = [];

  /// Newest first.
  List<DocumentItem> get documents => List.unmodifiable(_documents);

  void addDocument(DocumentItem document) {
    _documents.insert(0, document);
    notifyListeners();
  }
}

/// Single shared in-memory stand-in for the local Category table (see
/// CLAUDE.md's "Known mismatches" section) — registered as a lazy
/// singleton so a category added from the add_category feature's "New
/// Category" screen actually shows up in Home's category grid instead of
/// vanishing once that screen is popped.
class CategoryLocalStore extends ChangeNotifier {
  final List<CategoryItem> _categories = [
    const CategoryItem(
      name: 'Bank',
      icon: FontAwesomeIcons.buildingColumns,
      fileCount: 4,
    ),
    const CategoryItem(
      name: 'Business Card',
      icon: FontAwesomeIcons.addressCard,
    ),
    const CategoryItem(
      name: 'Contracts',
      icon: FontAwesomeIcons.fileContract,
      fileCount: 6,
    ),
    const CategoryItem(
      name: 'Driving License',
      icon: FontAwesomeIcons.idCardClip,
    ),
    const CategoryItem(name: 'Education', icon: FontAwesomeIcons.graduationCap),
    const CategoryItem(
      name: 'Electricity/Gas',
      icon: FontAwesomeIcons.boltLightning,
    ),
    const CategoryItem(name: 'ID Card', icon: FontAwesomeIcons.idCard),
    const CategoryItem(name: 'Insurance', icon: FontAwesomeIcons.shieldHalved),
    const CategoryItem(name: 'Invoices', icon: FontAwesomeIcons.fileInvoice),
    const CategoryItem(
      name: 'Medical',
      icon: FontAwesomeIcons.stethoscope,
      fileCount: 5,
    ),
    const CategoryItem(name: 'Passports', icon: FontAwesomeIcons.passport),
    const CategoryItem(
      name: 'Products',
      icon: FontAwesomeIcons.boxesStacked,
      fileCount: 7,
    ),
    const CategoryItem(
      name: 'Tax Documents',
      icon: FontAwesomeIcons.fileInvoiceDollar,
    ),
    const CategoryItem(name: 'Tickets', icon: FontAwesomeIcons.ticket),
  ];

  List<CategoryItem> get categories => List.unmodifiable(_categories);

  bool exists(String name, {String? excluding}) {
    final normalized = name.trim().toLowerCase();
    return _categories.any(
      (c) => c.name.toLowerCase() == normalized && c.name != excluding,
    );
  }

  void addCategory(CategoryItem category) {
    _categories.add(category);
    notifyListeners();
  }

  void updateCategory(String originalName, CategoryItem updated) {
    final index = _categories.indexWhere((c) => c.name == originalName);
    if (index == -1) return;
    _categories[index] = updated;
    notifyListeners();
  }

  void removeCategory(String name) {
    _categories.removeWhere((c) => c.name == name);
    notifyListeners();
  }

  /// Bulk variant of [removeCategory] — one notification instead of one
  /// per item, for manage_categories' multi-select delete.
  void removeCategories(Iterable<String> names) {
    final nameSet = names.toSet();
    _categories.removeWhere((c) => nameSet.contains(c.name));
    notifyListeners();
  }
}

class HomeViewModel extends ChangeNotifier {
  final CategoryLocalStore _categoryStore;
  final DocumentLocalStore _documentStore;

  HomeViewModel({
    required CategoryLocalStore categoryStore,
    required DocumentLocalStore documentStore,
  }) : _categoryStore = categoryStore,
       _documentStore = documentStore {
    _categoryStore.addListener(notifyListeners);
    _documentStore.addListener(notifyListeners);
  }

  bool isGridView = true;

  void setGridView(bool gridView) {
    if (isGridView == gridView) return;
    isGridView = gridView;
    notifyListeners();
  }

  /// Sorted alphabetically regardless of source order below, so the
  /// display order stays correct as categories are added/renamed.
  List<CategoryItem> get categories =>
      List<CategoryItem>.of(_categoryStore.categories)
        ..sort((a, b) => a.name.compareTo(b.name));

  /// Newly created documents (newest first) ahead of the static dummy
  /// list, so Add Document's output is immediately visible here.
  List<RecentFileItem> get recentFiles => [
    for (final doc in _documentStore.documents)
      RecentFileItem(
        name: doc.title,
        category: doc.category,
        icon: doc.icon,
        timeLabel: doc.createdAt.timeAgo,
      ),
    ..._staticRecentFiles,
  ];

  static const List<RecentFileItem> _staticRecentFiles = [
    RecentFileItem(
      name: 'Electricity Bill - Sept',
      category: 'Electricity/Gas',
      icon: FontAwesomeIcons.boltLightning,
      timeLabel: '2h ago',
    ),
    RecentFileItem(
      name: 'Passport Scan',
      category: 'Passports',
      icon: FontAwesomeIcons.passport,
      timeLabel: '5h ago',
    ),
    RecentFileItem(
      name: 'Insurance Policy',
      category: 'Insurance',
      icon: FontAwesomeIcons.shieldHalved,
      timeLabel: 'Yesterday',
    ),
    RecentFileItem(
      name: 'Bank Statement',
      category: 'Bank',
      icon: FontAwesomeIcons.buildingColumns,
      timeLabel: '2d ago',
    ),
    RecentFileItem(
      name: 'Lease Agreement',
      category: 'Contracts',
      icon: FontAwesomeIcons.fileContract,
      timeLabel: '3d ago',
    ),
    RecentFileItem(
      name: 'Lab Report',
      category: 'Medical',
      icon: FontAwesomeIcons.stethoscope,
      timeLabel: '4d ago',
    ),
  ];

  @override
  void dispose() {
    _categoryStore.removeListener(notifyListeners);
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
