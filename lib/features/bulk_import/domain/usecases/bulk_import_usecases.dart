import '../entities/bulk_import_candidate.dart';
import '../repositories/bulk_import_repository.dart';

class BulkImportUseCases {
  final BulkImportRepository _repository;
  BulkImportUseCases(this._repository);
  Future<BulkPickResult> stage(
    List<({String? path, String name})> files, {
    required int limit,
  }) => _repository.stage(files, limit: limit);
  Future<String> promote(BulkImportCandidate candidate) =>
      _repository.promote(candidate);
  Future<void> removeStaged(BulkImportCandidate candidate) =>
      _repository.removeStaged(candidate);
  Future<void> removePromoted(String path) => _repository.removePromoted(path);
  Future<void> discard() => _repository.discard();
}
