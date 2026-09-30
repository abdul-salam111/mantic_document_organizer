import '../../../documents/domain/entities/document_item.dart';
import '../../../documents/domain/repositories/document_repository.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements IFavoritesRepository {
  final IDocumentRepository _documents;
  FavoritesRepositoryImpl(this._documents);
  @override
  List<DocumentItem> get favorites =>
      _documents.documents.where((d) => d.isFavorite).toList(growable: false);
  @override
  Future<void> toggleFavorite(DocumentItem document) =>
      _documents.toggleFavorite(document);
  @override
  void addListener(void Function() listener) =>
      _documents.addListener(listener);
  @override
  void removeListener(void Function() listener) =>
      _documents.removeListener(listener);
}
