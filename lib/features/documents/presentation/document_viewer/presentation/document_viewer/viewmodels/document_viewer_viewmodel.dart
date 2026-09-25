import 'package:flutter/foundation.dart';

import '../../../../../../home/home_exports.dart';

/// No real document data layer exists yet (see CLAUDE.md's "Known
/// mismatches" section) — this reads/writes straight through the shared
/// [DocumentLocalStore]/[CategoryLocalStore] (also used by every other
/// documents-related screen). [init] is only ever called with a snapshot
/// of the [DocumentItem] the user tapped; [document] then re-resolves it
/// live by id on every read so favorite/rename/move edits (made here or
/// anywhere else) are always reflected instead of the screen holding a
/// stale copy.
class DocumentViewerViewModel extends ChangeNotifier {
  final DocumentLocalStore _documentStore;
  final CategoryLocalStore _categoryStore;

  DocumentViewerViewModel({
    required DocumentLocalStore documentStore,
    required CategoryLocalStore categoryStore,
  }) : _documentStore = documentStore,
       _categoryStore = categoryStore {
    _documentStore.addListener(notifyListeners);
  }

  late final String _documentId;

  /// Called once from the view's `ChangeNotifierProvider.create`, before
  /// the first frame — mirrors CategoryDocumentsViewModel.init.
  void init(DocumentItem document) {
    _documentId = document.id;
  }

  /// Null once the document has been deleted (by this screen or
  /// elsewhere) — the view falls back to popping itself when this happens.
  DocumentItem? get document {
    for (final d in _documentStore.documents) {
      if (d.id == _documentId) return d;
    }
    return null;
  }

  List<CategoryItem> get categories =>
      List<CategoryItem>.of(_categoryStore.categories)
        ..sort((a, b) => a.name.compareTo(b.name));

  int _pageIndex = 0;
  int get pageIndex => _pageIndex;

  void setPageIndex(int value) {
    if (_pageIndex == value) return;
    _pageIndex = value;
    notifyListeners();
  }

  void toggleFavorite() {
    final current = document;
    if (current == null) return;
    _documentStore.toggleFavorite(current);
  }

  void rename(String newTitle) {
    final current = document;
    final trimmed = newTitle.trim();
    if (current == null || trimmed.isEmpty) return;
    _documentStore.updateDocument(current.copyWith(title: trimmed));
  }

  void moveToCategory(CategoryItem category) {
    final current = document;
    if (current == null) return;
    _documentStore.updateDocument(
      current.copyWith(
        category: category.name,
        categoryId: category.id,
        iconKey: category.iconKey,
      ),
    );
  }

  /// Hard delete — see [DocumentLocalStore.removeDocument].
  void delete() {
    final current = document;
    if (current == null) return;
    _documentStore.removeDocument(current.id);
  }

  @override
  void dispose() {
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
