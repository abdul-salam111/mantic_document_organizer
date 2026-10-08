import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/background/document_sync_background_service.dart';
import '../../../../../core/utils/shared_space_sync.dart';

class CategoryDocumentsViewModel extends ChangeNotifier {
  final DocumentUseCases _documentUseCases;
  final DocumentSyncBackgroundService _syncBackgroundService;

  CategoryDocumentsViewModel({
    required DocumentUseCases documentUseCases,
    required DocumentSyncBackgroundService syncBackgroundService,
  }) : _documentUseCases = documentUseCases,
       _syncBackgroundService = syncBackgroundService {
    _documentUseCases.addListener(notifyListeners);
  }

  late final CategoryItem _category;
  CategoryItem get category => _category;

  /// Called once from the view's `ChangeNotifierProvider.create`, before
  /// the first frame — mirrors AddCategoryViewModel.startEditing.
  void init(CategoryItem category) {
    _category = category;
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

  /// All documents in this category, regardless of the current search
  /// query — used for the header count so it doesn't shrink while typing.
  List<DocumentItem> get allDocuments => _documentUseCases.documents
      .where((d) => d.categoryId == _category.id)
      .toList();

  List<DocumentItem> get documents {
    final q = _query.trim().toLowerCase();
    final filtered = allDocuments.where((d) {
      if (q.isEmpty) return true;
      return d.title.toLowerCase().contains(q) ||
          d.tags.any((tag) => tag.contains(q));
    }).toList();
    return filtered.sortedBy(_sort);
  }

  Future<void> toggleFavorite(DocumentItem document) =>
      _documentUseCases.toggleFavorite(document);

  // Long-press-to-select, keyed by id — same shape as
  // ManageCategoriesViewModel's own selection state.
  final Set<String> _selectedIds = {};
  bool get isSelecting => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool isSelected(String id) => _selectedIds.contains(id);

  void toggleSelection(String id) {
    if (!_selectedIds.add(id)) _selectedIds.remove(id);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> trashSelected() async {
    final ids = Set<String>.of(_selectedIds);
    if (ids.isEmpty) return;
    await _documentUseCases.trashDocuments(ids);
    _selectedIds.clear();
    triggerSharedSpaceSyncIfNeeded(
      syncBackgroundService: _syncBackgroundService,
      spaceId: _category.spaceId,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
