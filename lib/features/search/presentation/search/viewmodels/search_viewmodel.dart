import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/utils_exports.dart';

/// Which of a document's attached files [DocumentFileTypeFilter.images]/
/// [DocumentFileTypeFilter.pdfs]/[DocumentFileTypeFilter.other] match — a
/// document matches a non-[all] value if *any* of its files do, since a
/// scanned multi-page document can mix file types.
enum DocumentFileTypeFilter { all, images, pdfs, other }

/// Mirrors the windows [ExpiringSoonViewModel]/the expiry digest already
/// use ([DocumentUseCases.digestWindowDays] for "soon"), so this filter's
/// idea of "expiring soon" never drifts from what those surface elsewhere.
enum DocumentExpiryFilter { all, expiringSoon, expired, noExpiry }

/// A document plus, when the query only matched inside its body text (OCR
/// content or notes) rather than its title/category/tags, a short excerpt
/// around the match — so a hit buried in a scanned page is visible in the
/// results list without opening the document first.
typedef DocumentSearchMatch = ({DocumentItem document, String? excerpt});

enum _MatchTier { title, metadata, body }

class SearchViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;

  SearchViewModel({
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
  }) : _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases {
    _categoryUseCases.addListener(notifyListeners);
    _documentUseCases.addListener(notifyListeners);
  }

  String _query = '';
  String get query => _query;

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  bool isGridView = false;

  void setGridView(bool value) {
    if (isGridView == value) return;
    isGridView = value;
    notifyListeners();
  }

  DocumentSort _sort = DocumentSort.newest;
  DocumentSort get sort => _sort;

  void setSort(DocumentSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  DocumentFileTypeFilter _fileTypeFilter = DocumentFileTypeFilter.all;
  DocumentFileTypeFilter get fileTypeFilter => _fileTypeFilter;

  void setFileTypeFilter(DocumentFileTypeFilter value) {
    if (_fileTypeFilter == value) return;
    _fileTypeFilter = value;
    notifyListeners();
  }

  DocumentExpiryFilter _expiryFilter = DocumentExpiryFilter.all;
  DocumentExpiryFilter get expiryFilter => _expiryFilter;

  void setExpiryFilter(DocumentExpiryFilter value) {
    if (_expiryFilter == value) return;
    _expiryFilter = value;
    notifyListeners();
  }

  DateTimeRange? _dateRange;
  DateTimeRange? get dateRange => _dateRange;

  void setDateRange(DateTimeRange? value) {
    _dateRange = value;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _fileTypeFilter != DocumentFileTypeFilter.all ||
      _expiryFilter != DocumentExpiryFilter.all ||
      _dateRange != null;

  void clearFilters() {
    if (!hasActiveFilters) return;
    _fileTypeFilter = DocumentFileTypeFilter.all;
    _expiryFilter = DocumentExpiryFilter.all;
    _dateRange = null;
    notifyListeners();
  }

  static const String allCategoryTab = 'All';

  /// [allCategoryTab] first, then every category (alphabetically) — the
  /// same set Home's grid shows, not just categories that happen to have
  /// a document yet, so every category stays browsable from here too.
  List<String> get categoryTabs {
    final names = _categoryUseCases.categories.map((c) => c.name).toList()
      ..sort();
    return [allCategoryTab, ...names];
  }

  /// Documents in [category] (or every document, for [allCategoryTab]),
  /// further narrowed by the current search [query], the file-type/expiry/
  /// date filters, and ranked so a title match outranks one buried in a
  /// document's body text — all of it local, nothing here ever touches the
  /// network.
  ///
  /// [category] is a display name (a tab label) — resolved back to its
  /// live [CategoryItem.id] here, on every call, rather than matching
  /// documents by name directly, so a rename doesn't drop documents out of
  /// their tab (the tab label and this resolution both read the same live
  /// [CategoryUseCases] in the same rebuild, so they never disagree).
  List<DocumentSearchMatch> documentsFor(String category) {
    final categoryId = category == allCategoryTab
        ? null
        : _categoryIdForName(category);
    final q = _query.trim().toLowerCase();

    final filtered = _documentUseCases.documents.where((d) {
      final matchesCategory =
          category == allCategoryTab || d.categoryId == categoryId;
      return matchesCategory &&
          _matchesQuery(d, q) &&
          _matchesFileType(d) &&
          _matchesExpiry(d) &&
          _matchesDateRange(d);
    }).toList().sortedBy(_sort);

    if (q.isEmpty) {
      return [for (final d in filtered) (document: d, excerpt: null)];
    }

    // Bucketed rather than List.sort'd into tiers -- Dart's List.sort isn't
    // guaranteed stable, and losing the _sort-determined order *within* a
    // tier (e.g. newest-first among title matches) would be a regression,
    // not just a reshuffle.
    final byTier = {for (final tier in _MatchTier.values) tier: <DocumentItem>[]};
    for (final d in filtered) {
      byTier[_matchTier(d, q)]!.add(d);
    }
    return [
      for (final d in byTier[_MatchTier.title]!) (document: d, excerpt: null),
      for (final d in byTier[_MatchTier.metadata]!)
        (document: d, excerpt: null),
      for (final d in byTier[_MatchTier.body]!)
        (document: d, excerpt: _excerptFor(d, q)),
    ];
  }

  bool _matchesQuery(DocumentItem d, String q) {
    if (q.isEmpty) return true;
    return d.title.toLowerCase().contains(q) ||
        d.category.toLowerCase().contains(q) ||
        d.tags.any((tag) => tag.toLowerCase().contains(q)) ||
        d.description.toLowerCase().contains(q) ||
        d.ocrText.toLowerCase().contains(q);
  }

  _MatchTier _matchTier(DocumentItem d, String q) {
    if (d.title.toLowerCase().contains(q)) return _MatchTier.title;
    if (d.category.toLowerCase().contains(q) ||
        d.tags.any((tag) => tag.toLowerCase().contains(q))) {
      return _MatchTier.metadata;
    }
    return _MatchTier.body;
  }

  /// A short, single-line snippet of whichever body field actually
  /// contains [q] (OCR text first, then the user's own notes), centered on
  /// the match with surrounding context.
  String? _excerptFor(DocumentItem d, String q) {
    const radius = 60;
    for (final source in [d.ocrText, d.description]) {
      final lower = source.toLowerCase();
      final index = lower.indexOf(q);
      if (index == -1) continue;
      final start = (index - radius).clamp(0, source.length);
      final end = (index + q.length + radius).clamp(0, source.length);
      final snippet = source
          .substring(start, end)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (snippet.isEmpty) continue;
      return '${start > 0 ? '…' : ''}$snippet${end < source.length ? '…' : ''}';
    }
    return null;
  }

  bool _matchesFileType(DocumentItem d) {
    switch (_fileTypeFilter) {
      case DocumentFileTypeFilter.all:
        return true;
      case DocumentFileTypeFilter.images:
        return d.filePaths.any(isImagePath);
      case DocumentFileTypeFilter.pdfs:
        return d.filePaths.any(isPdfPath);
      case DocumentFileTypeFilter.other:
        return d.filePaths.any((p) => !isImagePath(p) && !isPdfPath(p));
    }
  }

  bool _matchesExpiry(DocumentItem d) {
    switch (_expiryFilter) {
      case DocumentExpiryFilter.all:
        return true;
      case DocumentExpiryFilter.expiringSoon:
        if (!d.isExpirable || d.expiryDate == null) return false;
        final now = DateTime.now();
        final windowEnd = now.add(
          const Duration(days: DocumentUseCases.digestWindowDays),
        );
        return d.expiryDate!.isAfter(now) && d.expiryDate!.isBefore(windowEnd);
      case DocumentExpiryFilter.expired:
        return d.isExpirable &&
            d.expiryDate != null &&
            d.expiryDate!.isBefore(DateTime.now());
      case DocumentExpiryFilter.noExpiry:
        return !d.isExpirable || d.expiryDate == null;
    }
  }

  bool _matchesDateRange(DocumentItem d) {
    final range = _dateRange;
    if (range == null) return true;
    final created = d.createdAt;
    return !created.isBefore(range.start.startOfDay()) &&
        !created.isAfter(range.end.endOfDay());
  }

  String? _categoryIdForName(String name) {
    for (final category in _categoryUseCases.categories) {
      if (category.name == name) return category.id;
    }
    return null;
  }

  Future<void> toggleFavorite(DocumentItem document) =>
      _documentUseCases.toggleFavorite(document);

  @override
  void dispose() {
    _categoryUseCases.removeListener(notifyListeners);
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
