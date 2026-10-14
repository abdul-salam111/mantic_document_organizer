import '../entities/document_draft.dart';
import '../repositories/draft_repository.dart';

class DraftUseCases {
  final IDraftRepository _repository;
  DraftUseCases(this._repository);
  List<DocumentDraft> get drafts => _repository.drafts;
  void addListener(void Function() listener) => _repository.addListener(listener);
  void removeListener(void Function() listener) => _repository.removeListener(listener);
  Future<void> init() => _repository.init();
  Future<void> save(DocumentDraft draft) => _repository.save(draft);
  Future<void> discard(String id) => _repository.discard(id);
  Future<List<String>> missingFiles(DocumentDraft draft) => _repository.missingFiles(draft);
}
