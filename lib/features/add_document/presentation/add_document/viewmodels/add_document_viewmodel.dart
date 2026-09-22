import 'package:flutter/foundation.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/add_document_params.dart';
import '../../../domain/entities/add_document_entity.dart';
import '../../../domain/usecases/add_document_usecase.dart';

class AddDocumentViewModel extends ChangeNotifier with UseCaseExecutor {
  final AddDocumentUsecase _addDocumentUsecase;

  AddDocumentViewModel({required AddDocumentUsecase addDocumentUsecase})
    : _addDocumentUsecase = addDocumentUsecase;

  AddDocumentEntity? _document;
  AddDocumentEntity? get document => _document;

  Future<void> addDocument(String name, {String? description}) async {
    await execute(
      call: () => _addDocumentUsecase(
        AddDocumentParams(name: name, description: description),
      ),
      onSuccess: (document) {
        _document = document;
        notifyListeners();
      },
    );
  }
}
