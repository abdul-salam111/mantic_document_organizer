import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/database/database_exports.dart';
import '../../../core/notifications/notifications_exports.dart';

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

/// Persisted via [AppDatabase] (see [CategoryLocalStore.init]). [color] is
/// only ever set by custom categories created via the add_category
/// feature — built-ins keep deriving their color from `categoryIconColor`
/// in home_view.dart.
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

/// A document created via the add_document feature — persisted via
/// [AppDatabase] (see [DocumentLocalStore.init]).
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

  /// AI-organized summary of the document's content (see [AiDocumentService]
  /// in core/ai) — blank if AI enrichment never ran (offline, or the call
  /// failed) or if OCR found nothing to organize. Always user-editable.
  final String description;

  /// Raw on-device OCR output for every attachment, concatenated — never
  /// shown directly in the UI; exists purely as search input and as the
  /// source text handed to the AI service. Blank for documents with no
  /// text-bearing attachments.
  final String ocrText;

  /// Null while active; set the moment this document is moved to Trash
  /// (see [DocumentLocalStore.trashDocument]) — non-null means it's in
  /// [DocumentLocalStore.trashedDocuments], not [DocumentLocalStore.
  /// documents], and is due for permanent deletion after
  /// [DocumentLocalStore.trashRetentionPeriod].
  final DateTime? deletedAt;

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
    this.description = '',
    this.ocrText = '',
    this.deletedAt,
  });

  bool get isTrashed => deletedAt != null;

  DocumentItem copyWith({
    String? title,
    String? category,
    String? categoryId,
    String? iconKey,
    bool? isFavorite,
    String? description,
    String? ocrText,
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
    description: description ?? this.description,
    ocrText: ocrText ?? this.ocrText,
    deletedAt: deletedAt,
  );

  /// Returns a copy moved into the trash — every other field (including
  /// [isFavorite]/[expiryDate]/[tags]) is preserved exactly, so [restored]
  /// reproduces the original document. Constructed directly rather than
  /// through [copyWith], which can't null a field back out. See
  /// [DocumentLocalStore.trashDocument].
  DocumentItem markDeleted(DateTime deletedAt) => DocumentItem(
    id: id,
    title: title,
    category: category,
    categoryId: categoryId,
    iconKey: iconKey,
    createdAt: createdAt,
    tags: tags,
    isFavorite: isFavorite,
    filePaths: filePaths,
    isExpirable: isExpirable,
    expiryDate: expiryDate,
    description: description,
    ocrText: ocrText,
    deletedAt: deletedAt,
  );

  /// Undoes [markDeleted] — see [DocumentLocalStore.restoreDocument].
  DocumentItem restored() => DocumentItem(
    id: id,
    title: title,
    category: category,
    categoryId: categoryId,
    iconKey: iconKey,
    createdAt: createdAt,
    tags: tags,
    isFavorite: isFavorite,
    filePaths: filePaths,
    isExpirable: isExpirable,
    expiryDate: expiryDate,
    description: description,
    ocrText: ocrText,
    deletedAt: null,
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

/// In-memory cache of the local Document table, backed by [AppDatabase] —
/// registered as a lazy singleton so a document added from the
/// add_document feature actually shows up in Home's Recent Files strip
/// instead of vanishing once that screen is popped. Every mutator updates
/// this cache (and notifies listeners) synchronously, then persists to
/// disk in the background — every screen keeps reading it exactly as
/// before, no async/loading state needed anywhere.
class DocumentLocalStore extends ChangeNotifier {
  final AppDatabase _db;
  final ExpiryNotificationService _notifications;

  DocumentLocalStore(this._db, this._notifications);

  /// How long a soft-deleted document stays recoverable in
  /// [trashedDocuments] before [init] auto-purges it — 30 days matches
  /// common OS/consumer trash conventions (Gmail Trash, iOS Photos
  /// "Recently Deleted"). A `static const` so [AppDatabase.
  /// purgeExpiredTrash]'s call site and the Trash UI's countdown can't
  /// drift apart.
  static const Duration trashRetentionPeriod = Duration(days: 30);

  final List<DocumentItem> _documents = [];
  final List<DocumentItem> _trashedDocuments = [];

  /// Newest first. Active (non-trashed) documents only.
  List<DocumentItem> get documents => List.unmodifiable(_documents);

  /// Newest-deleted first.
  List<DocumentItem> get trashedDocuments =>
      List.unmodifiable(_trashedDocuments);

  /// Hydrates [_documents]/[_trashedDocuments] from [AppDatabase] —
  /// called once at startup (see main.dart), before any screen reads
  /// [documents]/[trashedDocuments]. Purges expired trash first, so a
  /// purged row is never loaded into [_trashedDocuments] in the first
  /// place. Every mutator below already updates these in-memory lists
  /// synchronously, so the rest of the app never needs to know
  /// persistence happened at all.
  Future<void> init() async {
    await _db.purgeExpiredTrash(trashRetentionPeriod);
    _documents
      ..clear()
      ..addAll(await _db.fetchDocuments());
    _trashedDocuments
      ..clear()
      ..addAll(await _db.fetchTrashedDocuments());
    notifyListeners();
    // Reconciles every active document's expiry reminders against
    // whatever's actually scheduled on the device — covers both a document
    // saved before this feature existed (nothing scheduled for it yet) and
    // a scheduled reminder surviving from a previous install/build.
    for (final document in _documents) {
      unawaited(_notifications.scheduleForDocument(document));
    }
  }

  void addDocument(DocumentItem document) {
    _documents.insert(0, document);
    notifyListeners();
    unawaited(_db.upsertDocument(document));
    unawaited(_notifications.scheduleForDocument(document));
  }

  void toggleFavorite(DocumentItem document) {
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index == -1) return;
    final updated = document.copyWith(isFavorite: !document.isFavorite);
    _documents[index] = updated;
    notifyListeners();
    unawaited(_db.upsertDocument(updated));
  }

  /// General-purpose update (rename, move to another category, ...) —
  /// matched and replaced by [DocumentItem.id], same as [toggleFavorite].
  void updateDocument(DocumentItem updated) {
    final index = _documents.indexWhere((d) => d.id == updated.id);
    if (index == -1) return;
    _documents[index] = updated;
    notifyListeners();
    unawaited(_db.upsertDocument(updated));
    unawaited(_notifications.scheduleForDocument(updated));
  }

  /// Soft delete — moves [id] out of [documents] into [trashedDocuments],
  /// recoverable via [restoreDocument] within [trashRetentionPeriod].
  void trashDocument(String id) {
    final index = _documents.indexWhere((d) => d.id == id);
    if (index == -1) return;
    final trashed = _documents.removeAt(index).markDeleted(DateTime.now());
    _trashedDocuments.insert(0, trashed);
    notifyListeners();
    unawaited(_db.softDeleteDocument(id, trashed.deletedAt!));
    // A trashed document's expiry no longer needs acting on — cancel its
    // reminders rather than let them fire for something the user can't
    // easily get back to without visiting Trash.
    unawaited(_notifications.cancelForDocument(id));
  }

  /// Moves [id] back from [trashedDocuments] into [documents] — re-inserted
  /// at the position its [DocumentItem.createdAt] belongs (not at the
  /// front), so [documents]' newest-created-first order stays correct for
  /// direct readers like [HomeViewModel.recentFiles] that don't re-sort.
  void restoreDocument(String id) {
    final index = _trashedDocuments.indexWhere((d) => d.id == id);
    if (index == -1) return;
    final restored = _trashedDocuments.removeAt(index).restored();
    final insertAt = _documents.indexWhere(
      (d) => d.createdAt.isBefore(restored.createdAt),
    );
    _documents.insert(insertAt == -1 ? _documents.length : insertAt, restored);
    notifyListeners();
    unawaited(_db.restoreDocument(id));
    unawaited(_notifications.scheduleForDocument(restored));
  }

  /// Permanent delete from the trash — unlike [trashDocument], this cannot
  /// be undone.
  void permanentlyDeleteDocument(String id) {
    _trashedDocuments.removeWhere((d) => d.id == id);
    notifyListeners();
    unawaited(_db.deleteDocument(id));
    unawaited(_notifications.cancelForDocument(id));
  }

  /// Permanently deletes every document currently in [trashedDocuments].
  void emptyTrash() {
    if (_trashedDocuments.isEmpty) return;
    final ids = [for (final d in _trashedDocuments) d.id];
    _trashedDocuments.clear();
    notifyListeners();
    unawaited(_db.deleteDocuments(ids));
    for (final id in ids) {
      unawaited(_notifications.cancelForDocument(id));
    }
  }

  /// Live document count for a category — replaces any static/cached
  /// count, so it's always correct as documents are added/removed.
  int countForCategory(String categoryId) =>
      _documents.where((d) => d.categoryId == categoryId).length;
}

/// In-memory cache of the local Category table, backed by [AppDatabase] —
/// registered as a lazy singleton so a category added from the
/// add_category feature's "New Category" screen actually shows up in
/// Home's category grid instead of vanishing once that screen is popped.
/// Same "mutate the cache + notify synchronously, persist in the
/// background" pattern as [DocumentLocalStore].
class CategoryLocalStore extends ChangeNotifier {
  final AppDatabase _db;

  CategoryLocalStore(this._db);

  static const List<CategoryItem> _builtInCategories = [
    CategoryItem(id: 'bank', name: 'Bank', iconKey: 'buildingColumns'),
    CategoryItem(
      id: 'business_card',
      name: 'Business Card',
      // solidAddressCard, not addressCard — the picker catalog only
      // carries solid-style icons (see icon_catalog.dart), and addressCard
      // is only available there as its solid variant.
      iconKey: 'solidAddressCard',
    ),
    CategoryItem(id: 'contracts', name: 'Contracts', iconKey: 'fileContract'),
    CategoryItem(
      id: 'driving_license',
      name: 'Driving License',
      iconKey: 'idCardClip',
    ),
    CategoryItem(id: 'education', name: 'Education', iconKey: 'graduationCap'),
    CategoryItem(
      id: 'electricity_gas',
      name: 'Electricity/Gas',
      iconKey: 'boltLightning',
    ),
    CategoryItem(
      id: 'id_card',
      name: 'ID Card',
      // solidIdCard, not idCard — see the business_card entry above.
      iconKey: 'solidIdCard',
    ),
    CategoryItem(id: 'insurance', name: 'Insurance', iconKey: 'shieldHalved'),
    CategoryItem(id: 'invoices', name: 'Invoices', iconKey: 'fileInvoice'),
    CategoryItem(id: 'medical', name: 'Medical', iconKey: 'stethoscope'),
    CategoryItem(id: 'passports', name: 'Passports', iconKey: 'passport'),
    CategoryItem(id: 'products', name: 'Products', iconKey: 'boxesStacked'),
    CategoryItem(
      id: 'tax_documents',
      name: 'Tax Documents',
      iconKey: 'fileInvoiceDollar',
    ),
    CategoryItem(id: 'tickets', name: 'Tickets', iconKey: 'ticket'),
  ];

  final List<CategoryItem> _categories = [];

  List<CategoryItem> get categories => List.unmodifiable(_categories);

  /// Hydrates [_categories] from [AppDatabase] — called once at startup
  /// (see main.dart). Seeds [_builtInCategories] first, but only if the
  /// table is genuinely empty (a fresh install), so a renamed/deleted
  /// built-in on a later launch is never resurrected.
  Future<void> init() async {
    await _db.seedBuiltInCategoriesIfEmpty(_builtInCategories);
    _categories
      ..clear()
      ..addAll(await _db.fetchCategories());
    notifyListeners();
  }

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
    unawaited(_db.upsertCategory(category));
  }

  void updateCategory(String id, CategoryItem updated) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _categories[index] = updated;
    notifyListeners();
    unawaited(_db.upsertCategory(updated));
  }

  void removeCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    unawaited(_db.deleteCategory(id));
  }

  /// Bulk variant of [removeCategory] — one notification instead of one
  /// per item, for manage_categories' multi-select delete.
  void removeCategories(Iterable<String> ids) {
    final idSet = ids.toSet();
    _categories.removeWhere((c) => idSet.contains(c.id));
    notifyListeners();
    unawaited(_db.deleteCategories(idSet));
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

  void toggleFavorite(DocumentItem document) =>
      _documentStore.toggleFavorite(document);

  @override
  void dispose() {
    _categoryStore.removeListener(notifyListeners);
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
