import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import '../../../domain/usecases/favorites_usecase.dart';
import 'package:flutter/foundation.dart';

class FavoritesViewModel extends ChangeNotifier {
  final FavoritesUsecase _favoritesUsecase;

  FavoritesViewModel({required FavoritesUsecase favoritesUsecase})
    : _favoritesUsecase = favoritesUsecase {
    _favoritesUsecase.addListener(notifyListeners);
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
  List<DocumentItem> get allFavorites => _favoritesUsecase.favorites;

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

  Future<void> toggleFavorite(DocumentItem document) =>
      _favoritesUsecase.toggleFavorite(document);

  @override
  void dispose() {
    _favoritesUsecase.removeListener(notifyListeners);
    super.dispose();
  }
}
