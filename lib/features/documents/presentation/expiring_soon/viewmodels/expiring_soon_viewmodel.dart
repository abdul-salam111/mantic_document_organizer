import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/foundation.dart';

class ExpiringSoonViewModel extends ChangeNotifier {
  final DocumentUseCases _documentUseCases;

  ExpiringSoonViewModel({required DocumentUseCases documentUseCases})
    : _documentUseCases = documentUseCases {
    _documentUseCases.addListener(notifyListeners);
  }

  /// Soonest-expiring first — matches the digest notification's own count
  /// exactly (same window, same active-document source).
  List<DocumentItem> get documents => _documentUseCases.expiringSoon();

  Future<void> toggleFavorite(DocumentItem document) =>
      _documentUseCases.toggleFavorite(document);

  @override
  void dispose() {
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
