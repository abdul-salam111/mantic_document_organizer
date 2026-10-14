import '../entities/document_draft.dart';

abstract interface class IDraftRepository {
  List<DocumentDraft> get drafts;
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  Future<void> init();
  Future<void> save(DocumentDraft draft);
  Future<void> discard(String id);
  Future<List<String>> missingFiles(DocumentDraft draft);
}
