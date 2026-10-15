import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/entities/bulk_import_candidate.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_group_suggestion.dart';
import 'bulk_import_fakes.dart';

/// Covers `BulkImportViewModel.seedFromSharedFiles` -- the entry point
/// `ShareIntentListener` uses when more than one file is shared into the
/// app at once, as opposed to [_scanSource]'s passive gallery/filesystem
/// discovery (covered by bulk_import_viewmodel_test.dart/
/// bulk_import_discover_all_test.dart) -- and the review screen's
/// merge/split affordances (`mergeCandidates`/`splitCandidate`), which both
/// entry points share.
void main() {
  late ImportFixture f;
  setUp(() {
    f = ImportFixture();
  });
  tearDown(() async {
    await f.vm.cancel();
    f.vm.dispose();
  });

  test(
    'stages every shared file in one call and groups them with one AI call',
    () async {
      f.imports.picked = [candidate('a'), candidate('b')];
      final found = await f.vm.seedFromSharedFiles([
        '/shared/a.jpg',
        '/shared/b.jpg',
      ]);
      expect(found, true);
      expect(f.imports.stageCalls, 1); // one batch call, not one per file
      expect(f.processing.groupAnalysisCalls, 1);
      expect(f.vm.candidates.map((c) => c.id).toSet(), {'a', 'b'});
    },
  );

  test('refuses to run offline, without staging anything', () async {
    f.connectivity.online = false;
    f.imports.picked = [candidate('a')];
    final found = await f.vm.seedFromSharedFiles(['/shared/a.jpg']);
    expect(found, false);
    expect(f.vm.offline, true);
    expect(f.imports.stageCalls, 0);
  });

  test('an empty path list is a no-op', () async {
    final found = await f.vm.seedFromSharedFiles([]);
    expect(found, false);
    expect(f.imports.stageCalls, 0);
  });

  test(
    'a file the AI flags as not-a-document is still kept, unlike discovery',
    () async {
      f.imports.picked = [candidate('a')];
      f.processing.groupSuggestions = [
        const DocumentGroupSuggestion(memberIndices: [0], isDocument: false),
      ];
      final found = await f.vm.seedFromSharedFiles(['/shared/a.jpg']);
      expect(found, true);
      expect(f.vm.candidates.single.id, 'a');
      expect(f.imports.removed, isEmpty);
    },
  );

  test('a hard AI/network failure keeps every file, retryable, instead of '
      'dropping the share', () async {
    f.imports.picked = [candidate('a'), candidate('b')];
    f.processing.groupAnalysisFails = true;
    final found = await f.vm.seedFromSharedFiles([
      '/shared/a.jpg',
      '/shared/b.jpg',
    ]);
    expect(found, true);
    expect(
      f.vm.candidates.every((c) => c.state == CandidateProcessingState.failed),
      true,
    );
  });

  test(
    'mergeCandidates combines attachments and re-analyzes once as a single document',
    () async {
      f.imports.picked = [candidate('a'), candidate('b')];
      await f.vm.seedFromSharedFiles(['/shared/a.jpg', '/shared/b.jpg']);
      final before = f.processing.analysisCalls;
      f.vm.mergeCandidates(['a', 'b']);
      expect(f.vm.candidates.length, 1);
      final merged = f.vm.candidates.single;
      expect(merged.attachments.length, 2);
      await pumpEventQueue();
      expect(f.processing.analysisCalls, before + 1);
      expect(merged.id, isNot('a'));
      expect(merged.id, isNot('b'));
    },
  );

  test('mergeCandidates does nothing for fewer than two ids', () async {
    f.imports.picked = [candidate('a')];
    await f.vm.seedFromSharedFiles(['/shared/a.jpg']);
    f.vm.mergeCandidates(['a']);
    expect(f.vm.candidates.single.id, 'a');
  });

  test('splitCandidate explodes a merged candidate back into singletons, '
      'each re-analyzed independently', () async {
    f.imports.picked = [candidate('a'), candidate('b')];
    await f.vm.seedFromSharedFiles(['/shared/a.jpg', '/shared/b.jpg']);
    f.vm.mergeCandidates(['a', 'b']);
    await pumpEventQueue();
    final mergedId = f.vm.candidates.single.id;
    final before = f.processing.analysisCalls;
    f.vm.splitCandidate(mergedId);
    expect(f.vm.candidates.length, 2);
    expect(f.vm.candidates.every((c) => c.attachments.length == 1), true);
    await pumpEventQueue();
    expect(f.processing.analysisCalls, before + 2);
  });

  test(
    'splitCandidate does nothing for a single-attachment candidate',
    () async {
      f.imports.picked = [candidate('a')];
      await f.vm.seedFromSharedFiles(['/shared/a.jpg']);
      f.vm.splitCandidate('a');
      expect(f.vm.candidates.single.id, 'a');
    },
  );
}
