import '../../../documents/domain/entities/document_item.dart';
import '../repositories/favorites_repository.dart';

class FavoritesUsecase {
  final IFavoritesRepository _repository;
  FavoritesUsecase({required IFavoritesRepository repository})
    : _repository = repository;
  List<DocumentItem> get favorites => _repository.favorites;
  Future<void> toggleFavorite(DocumentItem document) =>
      _repository.toggleFavorite(document);
  void addListener(void Function() listener) =>
      _repository.addListener(listener);
  void removeListener(void Function() listener) =>
      _repository.removeListener(listener);
}
