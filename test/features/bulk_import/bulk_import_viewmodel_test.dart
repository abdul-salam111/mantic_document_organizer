import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/entities/bulk_import_candidate.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/bulk_import_repository.dart';
import 'package:mantic_doc_org/features/bulk_import/domain/repositories/gallery_discovery_repository.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_suggestion.dart';
import 'bulk_import_fakes.dart';

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
    'discovery applies AI suggestions inline, but later user edits still win',
    () async {
      f.seedFound([candidate('a'), candidate('b')]);
      await f.vm.discover();
      // Discovery already called analyze() for both candidates, inline.
      expect(f.processing.calls.length, 2);
      expect(f.processing.analysisCalls, 2);
      f.vm.updateTitle('a', ' My title ');
      f.vm.updateDescription('a', 'Summary');
      f.vm.updateExpiry('a', DateTime(2030));
      f.vm.updateTags('a', 'one, Two words, @bad, one');
      f.vm.applyCategoryToSelected('personal');
      f.vm.toggle('b');
      final result = await f.vm.commit();
      expect(result.imported, 1);
      final saved = f.documents.documents.single;
      expect(saved.title, 'My title');
      expect(saved.categoryId, 'personal');
      expect(saved.tags, ['one', 'two-words']);
      expect(saved.description, 'Summary');
      expect(saved.expiryDate, DateTime(2030));
      expect(saved.isExpirable, true);
      expect(f.vm.candidates.single.id, 'b');
      expect(f.imports.discarded, 0);
    },
  );

  test('empty title blocks confirmation and updates clear the error', () async {
    f.seedFound([candidate('a')]);
    await f.vm.discover();
    f.vm.updateTitle('a', '   ');
    expect(f.vm.canImport, false);
    expect((await f.vm.commit()).imported, 0);
    expect(f.imports.promoted, isEmpty);
    f.vm.updateTitle('a', 'Valid');
    expect(f.vm.canImport, true);
  });

  test(
    'partial failures retain staged files; retry never duplicates successes',
    () async {
      f.seedFound([candidate('a'), candidate('b'), candidate('c')]);
      f.documents.failures.add('bulk_b');
      f.imports.copyFailures.add('c');
      await f.vm.discover();
      final result = await f.vm.commit();
      expect(result.imported, 1);
      expect(result.failures.keys, ['b', 'c']);
      expect(f.imports.rolledBack, ['/permanent/b.jpg']);
      expect(f.vm.candidates.map((c) => c.id), ['b', 'c']);
      expect(f.vm.candidates.every((c) => c.importError != null), true);
      expect(f.imports.removed, ['a']);
      expect(f.imports.discarded, 0);
      f.documents.failures.clear();
      f.imports.copyFailures.clear();
      expect((await f.vm.commit()).imported, 2);
      expect(f.documents.documents.map((d) => d.id), [
        'bulk_a',
        'bulk_b',
        'bulk_c',
      ]);
    },
  );

  test('no readable text is filtered out before any AI call', () async {
    f.seedFound([candidate('a')]);
    f.processing.text = '';
    final found = await f.vm.discover();
    expect(found, false);
    expect(f.vm.candidates, isEmpty);
    expect(f.imports.removed, ['a']);
    expect(f.processing.analysisCalls, 0); // free local check, no network
  });

  test(
    'a candidate the AI flags as a document is accepted and pre-filled from the suggestion',
    () async {
      f.seedFound([candidate('a')]);
      final found = await f.vm.discover();
      expect(found, true);
      final c = f.vm.candidates.single;
      expect(c.id, 'a');
      expect(c.state, CandidateProcessingState.ready);
      expect(c.title, 'Suggested title');
      expect(c.categoryId, 'bank');
      expect(c.tags, ['bank-statement', 'valid', 'other']);
      expect(c.description, 'Suggested description');
      expect(c.expiryDate, DateTime(2030, 6, 4));
    },
  );

  test(
    'a candidate the AI flags as not-a-document is rejected before review',
    () async {
      f.seedFound([candidate('a')]);
      f.processing.suggestion = const AiDocumentSuggestion(isDocument: false);
      final found = await f.vm.discover();
      expect(found, false);
      expect(f.vm.candidates, isEmpty);
      expect(f.imports.removed, ['a']);
    },
  );

  test('declined gallery permission is reported without staging anything', () async {
    f.discovery.permission = DiscoveryPermission.denied;
    f.seedFound([candidate('a')]);
    final found = await f.vm.discover();
    expect(found, false);
    expect(f.vm.permissionDenied, true);
    expect(f.imports.stageCalls, 0);
  });

  test(
    'discover() refuses to run offline, without touching discovery at all',
    () async {
      f.connectivity.online = false;
      f.seedFound([candidate('a')]);
      final found = await f.vm.discover();
      expect(found, false);
      expect(f.vm.offline, true);
      expect(f.discovery.findCandidatesCalls, 0);
      expect(f.imports.stageCalls, 0);
    },
  );

  test('a repeat scan starts from the stored watermark', () async {
    f.watermarkStore.stored = DateTime(2024, 6, 1);
    f.seedFound([candidate('a')]);
    await f.vm.discover();
    expect(f.discovery.lastSince, DateTime(2024, 6, 1));
    expect(f.watermarkStore.stored, DateTime(2025, 1, 1));
  });

  test(
    'a failed AI analysis keeps the candidate, retryable and importable',
    () async {
      f.processing.suggestion = null; // AiDocumentService.analyze() collapses
      // every failure mode (offline mid-call, bad JSON, etc.) to null.
      f.seedFound([candidate('a')]);
      await f.vm.discover();
      expect(f.vm.candidates.single.state, CandidateProcessingState.failed);
      expect(f.vm.candidates.single.ocrText, f.processing.text);
      expect(f.vm.canImport, true);
      f.processing.suggestion = FakeProcessing().suggestion;
      f.vm.retry('a');
      await pumpEventQueue();
      expect(f.vm.candidates.single.state, CandidateProcessingState.ready);
      expect(f.vm.candidates.single.error, isNull);
    },
  );

  test(
    'user edits made before a retry survive the retried suggestion',
    () async {
      f.processing.suggestion = null;
      f.seedFound([candidate('a')]);
      await f.vm.discover();
      expect(f.vm.candidates.single.state, CandidateProcessingState.failed);
      f.vm.updateTitle('a', 'Edited title');
      f.vm.updateCategory('a', 'personal');
      f.vm.updateTags('a', 'edited');
      f.vm.updateDescription('a', 'Edited summary');
      f.vm.updateExpiry('a', null);
      f.processing.suggestion = FakeProcessing().suggestion;
      f.vm.retry('a');
      await pumpEventQueue();
      final c = f.vm.candidates.single;
      expect(c.title, 'Edited title');
      expect(c.categoryId, 'personal');
      expect(c.tags, ['edited']);
      expect(c.description, 'Edited summary');
      expect(c.expiryDate, isNull);
      expect(c.state, CandidateProcessingState.ready);
    },
  );

  test('25-candidate cap stops scanning and reports more were found', () async {
    f.seedFound(List.generate(30, (i) => candidate('$i')));
    final found = await f.vm.discover();
    expect(found, true);
    expect(f.vm.candidates.length, 25);
    expect(f.vm.scanHasMore, true);
    // Assets beyond the cap are never staged, so nothing needed removal.
    expect(f.imports.stageCalls, 25);
    expect(f.imports.removed, isEmpty);
    // Discovery's OCR + AI-analysis pass is a single sequential loop.
    expect(f.processing.maxConcurrent, 1);
    expect(f.processing.maxAnalyzeConcurrent, 1);
  });

  test(
    'deselecting a queued retry cancels it; reselecting retries exactly once',
    () async {
      f.processing.suggestion = null; // both discovery analyses fail
      f.seedFound([candidate('a'), candidate('b')]);
      await f.vm.discover();
      expect(
        f.vm.candidates.every((c) => c.state == CandidateProcessingState.failed),
        true,
      );
      f.processing.suggestion = FakeProcessing().suggestion;
      f.processing.suggestionGate = Completer<AiDocumentSuggestion?>();
      f.vm.retry('a');
      f.vm.retry('b');
      await pumpEventQueue(); // 'a' is mid-analyze (gated); 'b' queued behind it.
      f.vm.toggle('b'); // deselect while queued -> cancelled before analyze().
      f.processing.suggestionGate!.complete(f.processing.suggestion);
      await pumpEventQueue();
      expect(f.vm.isProcessing, false);
      final afterCancel = f.processing.analysisCalls;
      f.vm.toggle('b'); // reselect -> retried again, exactly once.
      await pumpEventQueue();
      expect(f.processing.analysisCalls, afterCancel + 1);
      expect(f.processing.maxAnalyzeConcurrent, 1);
    },
  );

  test(
    'removing an active retry waits for analysis, then deletes without late updates',
    () async {
      f.processing.suggestion = null;
      f.seedFound([candidate('a')]);
      await f.vm.discover();
      expect(f.vm.candidates.single.state, CandidateProcessingState.failed);
      f.processing.suggestion = FakeProcessing().suggestion;
      f.processing.suggestionGate = Completer<AiDocumentSuggestion?>();
      f.vm.retry('a');
      await pumpEventQueue(); // 'a' is mid-analyze (gated).
      final removing = f.vm.remove('a');
      expect(f.vm.candidates, isEmpty);
      f.processing.suggestionGate!.complete(f.processing.suggestion);
      await removing;
      expect(f.imports.removed, ['a']);
    },
  );

  test(
    'commit freezes details and disables edits while save is pending',
    () async {
      f.documents.gate = Completer<void>();
      f.seedFound([candidate('a'), candidate('b')]);
      await f.vm.discover();
      final saving = f.vm.commit();
      await pumpEventQueue();
      f.vm.updateTitle('a', 'Late edit');
      f.vm.toggle('b');
      await f.vm.remove('b');
      expect((await f.vm.commit()).imported, 0);
      f.documents.gate!.complete();
      expect((await saving).imported, 2);
      // Commit freezes the snapshot before the late edit, but after
      // discovery's inline AI suggestion already applied.
      expect(f.documents.documents.first.title, 'Suggested title');
    },
  );

  test(
    'cancel during discovery discards staged files without documents',
    () async {
      f.imports.pickGate = Completer<BulkPickResult>();
      f.discovery.assets = [discoveredAsset('a')];
      final discovering = f.vm.discover();
      final cancelling = f.vm.cancel();
      f.imports.pickGate!.complete(BulkPickResult([candidate('a')]));
      expect(await discovering, false);
      await cancelling;
      expect(f.imports.discarded, 1);
      expect(f.documents.documents, isEmpty);
    },
  );

  test(
    'dispose during an active retry does not notify or start the next item',
    () async {
      f.processing.suggestion = null;
      f.seedFound([candidate('a'), candidate('b')]);
      await f.vm.discover();
      f.processing.suggestion = FakeProcessing().suggestion;
      f.processing.suggestionGate = Completer<AiDocumentSuggestion?>();
      f.vm.retry('a');
      f.vm.retry('b');
      await pumpEventQueue();
      // 'a' is mid-analyze (gated); 'b' is still queued behind it.
      final callsBeforeDispose = f.processing.analysisCalls;
      var notifications = 0;
      f.vm.addListener(() {
        notifications++;
      });
      f.vm.dispose();
      f.processing.suggestionGate!.complete(f.processing.suggestion);
      await f.vm.cancel();
      expect(notifications, 0);
      expect(f.processing.analysisCalls, callsBeforeDispose);
      expect(f.imports.discarded, 1);
      // Avoid a second dispose in the shared teardown.
      f = ImportFixture();
    },
  );
}
