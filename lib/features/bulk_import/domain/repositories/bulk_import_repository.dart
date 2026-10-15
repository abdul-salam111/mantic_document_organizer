import '../entities/bulk_import_candidate.dart';

class BulkPickResult {
  final List<BulkImportCandidate> candidates;
  final int skipped;
  final int overLimit;
  const BulkPickResult(this.candidates, {this.skipped = 0, this.overLimit = 0});
}

abstract interface class BulkImportRepository {
  /// Copies [files] into the session's staging directory and builds one
  /// candidate per supported, readable file, up to [limit].
  Future<BulkPickResult> stage(
    List<({String? path, String name})> files, {
    required int limit,
  });

  /// Moves every one of [candidate]'s staged attachments to permanent
  /// storage, in order. If any copy fails partway through, the siblings
  /// already promoted for this candidate are rolled back before rethrowing.
  Future<List<String>> promote(BulkImportCandidate candidate);
  Future<void> removeStaged(BulkImportCandidate candidate);
  Future<void> removePromoted(String path);
  Future<void> discard();
}
