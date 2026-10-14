import 'package:flutter/foundation.dart';
import '../../domain/entities/document_draft.dart';
import '../../domain/repositories/draft_repository.dart';
import '../datasources/draft_local_datasource.dart';

/// Mirrors document storage: serialize writes and publish only durable state.
class DraftRepositoryImpl extends ChangeNotifier implements IDraftRepository {
  final DraftLocalDataSource _source;
  DraftRepositoryImpl(this._source);
  List<DocumentDraft> _drafts = [];
  Future<void> _pending = Future.value();
  @override
  List<DocumentDraft> get drafts => List.unmodifiable(_drafts);

  Future<void> _write(Future<void> Function() action) {
    final result = _pending.then((_) async {
      await action();
      _drafts = await _source.read();
      notifyListeners();
    });
    _pending = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }
  @override
  Future<void> init() => _write(() async {});
  @override
  Future<void> save(DocumentDraft draft) => _write(() => _source.save(draft));
  @override
  Future<void> discard(String id) => _write(() => _source.discard(id));
  @override
  Future<List<String>> missingFiles(DocumentDraft draft) => _source.missingFiles(draft);
}
