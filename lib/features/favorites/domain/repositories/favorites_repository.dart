import '../../../documents/domain/entities/document_item.dart';

abstract interface class IFavoritesRepository {
  List<DocumentItem> get favorites;
  Future<void> toggleFavorite(DocumentItem document);
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
}
