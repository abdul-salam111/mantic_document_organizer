import 'package:flutter/material.dart';

/// Sentinel [CategoryItem.id] for documents saved with no category
/// selected — stable across locales/renames, unlike matching on the
/// localized "Uncategorized" display name would be.
const String uncategorizedCategoryId = 'uncategorized';

/// Cheap local-id generator for records created in the in-memory stores
/// below (new categories, new documents) — not a real primary key scheme,
/// just enough to give each record a stable identity that survives a
/// rename, matching the pattern already used for scanned-file names in
/// add_document_viewmodel.dart's `_localizeScan`.
String generateLocalId() => DateTime.now().microsecondsSinceEpoch.toString();

/// Extensions this codebase's own capture/attach flow can actually produce
/// as an image (camera scan output, gallery picks) — used to decide
/// whether a [DocumentItem.filePaths] entry can be shown inline (e.g. in
/// document_viewer) or needs a generic file placeholder instead.
const Set<String> _imagePathExtensions = {
  'png',
  'jpg',
  'jpeg',
  'gif',
  'bmp',
  'webp',
  'heic',
  'heif',
  'tif',
  'tiff',
};

bool isImagePath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return false;
  return _imagePathExtensions.contains(path.substring(dot + 1).toLowerCase());
}

/// Whether a [DocumentItem.filePaths] entry is a PDF — the one non-image
/// type document_viewer can actually render inline (via pdfx) rather than
/// falling back to a generic "no preview" placeholder.
bool isPdfPath(String path) => path.toLowerCase().endsWith('.pdf');

/// Presentational-only for now — no categories feature/local DB exists
/// yet (see CLAUDE.md's "Known mismatches" section), so this is dummy
/// data standing in for what will eventually be a real sqflite-backed
/// Category list. [color] is only ever set by custom categories created
/// via the add_category feature — built-ins keep deriving their color
/// from `categoryIconColor` in home_view.dart.
///
/// [id] is the stable identity used for matching/joins (rename-safe);
/// [name] is display-only and free to change via [CategoryLocalStore.
/// updateCategory]. Deliberately no `fileCount` here — that's derived data
/// (how many [DocumentItem]s currently have this [id] as their
/// [DocumentItem.categoryId]), so it's computed live via
/// [DocumentLocalStore.countForCategory] wherever it's displayed instead
/// of being cached on the category itself, where it would go stale the
/// moment a document is added/removed/recategorized.
class CategoryItem {
  final String id;
  final String name;

  /// A stable `FontAwesomeIcons` identifier (e.g. `'buildingColumns'`),
  /// not the icon itself — `FaIconData` is a UI-framework type and can't be
  /// persisted, so it's resolved to one only at render time via
  /// `iconForKey` (core/constants/icon_catalog.dart). See
  /// ICON_TYPE_AND_ATTACHMENT_STORAGE_NOTES.txt for the full reasoning.
  final String iconKey;
  final Color? color;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconKey,
    this.color,
  });
}

/// Shared document sort order — used by every screen that lists
/// [DocumentItem]s (category_documents, favorites, ...) so the options
/// and their ordering logic aren't redefined per screen.
enum DocumentSort { newest, oldest, nameAz }

/// Presentation-only for now, same reasoning as [CategoryItem] — a
/// document created via the add_document feature, standing in for a real
/// sqflite-backed Document row (see CLAUDE.md's "Known mismatches").
///
/// [id] is this document's own stable identity (used for favorite toggling
/// instead of positional/reference matching). [categoryId] is the stable
/// join key back to [CategoryItem.id] — [category] is only a display-name
/// snapshot taken at save time, so it does NOT update if the category is
/// later renamed; anything that needs to filter/join by category must use
/// [categoryId], never [category].
class DocumentItem {
  final String id;
  final String title;
  final String category;
  final String categoryId;

  /// See [CategoryItem.iconKey] — same "stable string, resolved at render
  /// time" reasoning applies here.
  final String iconKey;
  final List<String> tags;
  final bool isFavorite;
  final List<String> filePaths;
  final DateTime createdAt;
  final bool isExpirable;
  final DateTime? expiryDate;

  const DocumentItem({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryId,
    required this.iconKey,
    required this.createdAt,
    this.tags = const [],
    this.isFavorite = false,
    this.filePaths = const [],
    this.isExpirable = false,
    this.expiryDate,
  });

  DocumentItem copyWith({
    String? title,
    String? category,
    String? categoryId,
    String? iconKey,
    bool? isFavorite,
  }) => DocumentItem(
    id: id,
    title: title ?? this.title,
    category: category ?? this.category,
    categoryId: categoryId ?? this.categoryId,
    iconKey: iconKey ?? this.iconKey,
    createdAt: createdAt,
    tags: tags,
    isFavorite: isFavorite ?? this.isFavorite,
    filePaths: filePaths,
    isExpirable: isExpirable,
    expiryDate: expiryDate,
  );
}

/// Shared sort logic for any screen listing [DocumentItem]s — returns a
/// new sorted list rather than mutating [this], so callers can chain it
/// straight off a filter without worrying about aliasing the source list.
extension DocumentListSorting on List<DocumentItem> {
  List<DocumentItem> sortedBy(DocumentSort sort) {
    final sorted = List<DocumentItem>.of(this);
    switch (sort) {
      case DocumentSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case DocumentSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case DocumentSort.nameAz:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return sorted;
  }
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

  void toggleFavorite(DocumentItem document) {
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index == -1) return;
    _documents[index] = document.copyWith(isFavorite: !document.isFavorite);
    notifyListeners();
  }

  /// General-purpose update (rename, move to another category, ...) —
  /// matched and replaced by [DocumentItem.id], same as [toggleFavorite].
  void updateDocument(DocumentItem updated) {
    final index = _documents.indexWhere((d) => d.id == updated.id);
    if (index == -1) return;
    _documents[index] = updated;
    notifyListeners();
  }

  /// Hard delete — there's no Trash/soft-delete yet (see
  /// PROJECT_STATUS_AND_ROADMAP.txt), so this is genuinely permanent.
  void removeDocument(String id) {
    _documents.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  /// Live document count for a category — replaces any static/cached
  /// count, so it's always correct as documents are added/removed.
  int countForCategory(String categoryId) =>
      _documents.where((d) => d.categoryId == categoryId).length;
}

/// Single shared in-memory stand-in for the local Category table (see
/// CLAUDE.md's "Known mismatches" section) — registered as a lazy
/// singleton so a category added from the add_category feature's "New
/// Category" screen actually shows up in Home's category grid instead of
/// vanishing once that screen is popped.
class CategoryLocalStore extends ChangeNotifier {
  final List<CategoryItem> _categories = [
    const CategoryItem(id: 'bank', name: 'Bank', iconKey: 'buildingColumns'),
    const CategoryItem(
      id: 'business_card',
      name: 'Business Card',
      // solidAddressCard, not addressCard — the picker catalog only
      // carries solid-style icons (see icon_catalog.dart), and addressCard
      // is only available there as its solid variant.
      iconKey: 'solidAddressCard',
    ),
    const CategoryItem(
      id: 'contracts',
      name: 'Contracts',
      iconKey: 'fileContract',
    ),
    const CategoryItem(
      id: 'driving_license',
      name: 'Driving License',
      iconKey: 'idCardClip',
    ),
    const CategoryItem(
      id: 'education',
      name: 'Education',
      iconKey: 'graduationCap',
    ),
    const CategoryItem(
      id: 'electricity_gas',
      name: 'Electricity/Gas',
      iconKey: 'boltLightning',
    ),
    const CategoryItem(
      id: 'id_card',
      name: 'ID Card',
      // solidIdCard, not idCard — see the business_card entry above.
      iconKey: 'solidIdCard',
    ),
    const CategoryItem(
      id: 'insurance',
      name: 'Insurance',
      iconKey: 'shieldHalved',
    ),
    const CategoryItem(
      id: 'invoices',
      name: 'Invoices',
      iconKey: 'fileInvoice',
    ),
    const CategoryItem(id: 'medical', name: 'Medical', iconKey: 'stethoscope'),
    const CategoryItem(id: 'passports', name: 'Passports', iconKey: 'passport'),
    const CategoryItem(
      id: 'products',
      name: 'Products',
      iconKey: 'boxesStacked',
    ),
    const CategoryItem(
      id: 'tax_documents',
      name: 'Tax Documents',
      iconKey: 'fileInvoiceDollar',
    ),
    const CategoryItem(id: 'tickets', name: 'Tickets', iconKey: 'ticket'),
  ];

  List<CategoryItem> get categories => List.unmodifiable(_categories);

  CategoryItem? byId(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  bool exists(String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    return _categories.any(
      (c) => c.name.toLowerCase() == normalized && c.id != excludingId,
    );
  }

  void addCategory(CategoryItem category) {
    _categories.add(category);
    notifyListeners();
  }

  void updateCategory(String id, CategoryItem updated) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _categories[index] = updated;
    notifyListeners();
  }

  void removeCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Bulk variant of [removeCategory] — one notification instead of one
  /// per item, for manage_categories' multi-select delete.
  void removeCategories(Iterable<String> ids) {
    final idSet = ids.toSet();
    _categories.removeWhere((c) => idSet.contains(c.id));
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

  /// Live document count for a category (or [uncategorizedCategoryId]) —
  /// see [CategoryItem]'s doc comment for why this isn't a stored field.
  int documentCountFor(String categoryId) =>
      _documentStore.countForCategory(categoryId);

  /// Newest first, capped to a reasonable preview length for the
  /// horizontal strip — real documents only, no placeholder/dummy entries,
  /// so this is empty until something's actually been added.
  static const int _recentFilesLimit = 10;

  List<DocumentItem> get recentFiles =>
      _documentStore.documents.take(_recentFilesLimit).toList();

  @override
  void dispose() {
    _categoryStore.removeListener(notifyListeners);
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
