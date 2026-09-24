import 'package:flutter/foundation.dart';

import '../../../../home/home_exports.dart';

/// No real document data layer exists yet (see CLAUDE.md's "Known
/// mismatches" section) — this reads straight from the shared
/// [DocumentLocalStore] (also used by HomeViewModel/CategoryDocumentsViewModel)
/// and filters to whichever documents currently have [DocumentItem.isFavorite]
/// set, so favoriting a document anywhere in the app (e.g. category_documents'
/// heart button) actually shows up here instead of this screen carrying its
/// own disconnected dummy list.
class FavoritesViewModel extends ChangeNotifier {
  final DocumentLocalStore _documentStore;

  FavoritesViewModel({required DocumentLocalStore documentStore})
    : _documentStore = documentStore {
    _documentStore.addListener(notifyListeners);
  }

  bool isGridView = false;

  void setGridView(bool value) {
    if (isGridView == value) return;
    isGridView = value;
    notifyListeners();
  }

  String _query = '';
  String get query => _query;

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  DocumentSort _sort = DocumentSort.newest;
  DocumentSort get sort => _sort;

  void setSort(DocumentSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  /// Every favorited document, regardless of the current search query —
  /// used to tell "no favorites at all" apart from "no results for this
  /// search" in the empty state.
  List<DocumentItem> get allFavorites =>
      _documentStore.documents.where((d) => d.isFavorite).toList();

  List<DocumentItem> get items {
    final q = _query.trim().toLowerCase();
    final filtered = allFavorites.where((d) {
      if (q.isEmpty) return true;
      return d.title.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q) ||
          d.tags.any((tag) => tag.contains(q));
    }).toList();
    return filtered.sortedBy(_sort);
  }

  void toggleFavorite(DocumentItem document) =>
      _documentStore.toggleFavorite(document);

  @override
  void dispose() {
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
