import 'package:flutter/foundation.dart';
import '../../../core/shared/shared_exports.dart';
import '../../categories/domain/entities/category_item.dart';
import '../../categories/domain/usecases/category_usecases.dart';
import '../../documents/domain/entities/document_item.dart';
import '../../documents/domain/usecases/document_usecases.dart';
import '../domain/entities/document_readiness.dart';
import '../domain/usecases/readiness_usecases.dart';

class ReadinessViewModel extends ChangeNotifier with UseCaseExecutor {
  final DocumentUseCases documents;
  final CategoryUseCases categories;
  final LoadReadiness load;
  final SaveReadiness save;
  ReadinessViewModel({required this.documents, required this.categories, required this.load, required this.save}) {
    documents.addListener(notifyListeners);
    categories.addListener(notifyListeners);
  }
  bool _closed = false;
  @override
  void notifyListeners() { if (!_closed) super.notifyListeners(); }
  ReadinessPreferences _preferences = ReadinessPreferences();
  bool ready = false;
  List<ReadinessItem> get items => evaluateReadiness(documents.documents, _preferences);
  int get total => items.where((i) => !i.excluded).length;
  int get completed => items.where((i) => i.complete).length;
  double get progress => total == 0 ? 0 : completed / total;
  List<DocumentItem> get availableDocuments => documents.documents.where((d) => !d.isTrashed && d.filePaths.isNotEmpty).toList();
  CategoryItem? categoryFor(ReadinessGroup group) {
    final id = group.categoryId;
    final category = id == null ? null : categories.byId(id);
    return category?.isViewerOnly == true ? null : category;
  }
  Future<CategoryItem> prepareCategory(ReadinessGroup group, String fallbackName) async {
    final existing = categoryFor(group);
    if (existing != null) return existing;
    for (final category in categories.categories) {
      if (!category.isViewerOnly && category.name == fallbackName) return category;
    }
    final category = CategoryItem(id: generateLocalId(), name: fallbackName, iconKey: 'solidFolder');
    await categories.addCategory(category);
    return category;
  }

  Future<void> init() async {
    final result = await execute(call: () => load(NoParams()), showError: false);
    if (result != null) { _preferences = result; ready = true; notifyListeners(); }
  }
  Future<void> setExcluded(ReadinessGroup group, bool excluded) async {
    if (isLoading || !ready) return;
    final next = _preferences.excluded.toSet();
    excluded ? next.add(group) : next.remove(group);
    await _persist(ReadinessPreferences(excluded: next, links: _preferences.links));
  }
  Future<void> link(ReadinessGroup group, DocumentItem document) async {
    if (isLoading || !ready) return;
    if (!availableDocuments.any((d) => d.id == document.id)) return;
    await _persist(ReadinessPreferences(
      excluded: _preferences.excluded.toSet()..remove(group),
      links: {..._preferences.links, group: document.id},
    ));
  }
  Future<void> _persist(ReadinessPreferences next) async {
    final result = await execute(call: () => save(next));
    if (result != null) { _preferences = result; notifyListeners(); }
  }
  @override
  void dispose() {
    _closed = true;
    documents.removeListener(notifyListeners);
    categories.removeListener(notifyListeners);
    super.dispose();
  }
}
