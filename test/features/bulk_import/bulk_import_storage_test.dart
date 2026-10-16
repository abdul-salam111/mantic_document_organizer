import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:mantic_doc_org/features/bulk_import/data/bulk_import_local_datasource.dart';

void main() {
  late Directory root;
  late BulkImportLocalDataSource imports;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('docketly_import_test_');
    imports = BulkImportLocalDataSource(rootDirectory: () async => root);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<File> source(String name) =>
      File(p.join(root.path, name)).writeAsString('source bytes');

  test(
    'staging preserves picker filename and originals; cancel removes only session',
    () async {
      final file = await source('picker-cache.pdf');
      final result = await imports.stage([
        (path: file.path, name: 'My statement.PDF'),
      ], limit: 25);
      final c = result.candidates.single;
      expect(c.title, 'My statement');
      expect(
        await File(c.attachments.single.path).readAsString(),
        'source bytes',
      );
      expect(c.attachments.single.path, contains('import_staging'));
      await imports.discard();
      expect(await File(c.attachments.single.path).exists(), false);
      expect(await file.readAsString(), 'source bytes');
    },
  );

  test(
    'missing, unsupported and pathless files are skipped independently',
    () async {
      final file = await source('valid.pdf');
      final result = await imports.stage([
        (path: '/missing/file.pdf', name: 'missing.pdf'),
        (path: file.path, name: 'unsupported.exe'),
        (path: null, name: 'cloud.pdf'),
        (path: file.path, name: 'valid.pdf'),
      ], limit: 25);
      expect(result.skipped, 3);
      expect(result.candidates.single.title, 'valid');
    },
  );

  test(
    'png/gif are skipped by default but accepted with explicitPick -- a '
    'screenshot-noise filter for passive discovery, not for a file the '
    'user explicitly picked (seedFromSharedFiles/ShareIntentListener)',
    () async {
      final file = await source('photo.png');
      final discovered = await imports.stage([
        (path: file.path, name: 'photo.png'),
      ], limit: 25);
      expect(discovered.skipped, 1);
      expect(discovered.candidates, isEmpty);

      final picked = await imports.stage(
        [(path: file.path, name: 'photo.png')],
        limit: 25,
        explicitPick: true,
      );
      expect(picked.skipped, 0);
      expect(picked.candidates.single.title, 'photo');
    },
  );

  test('limit is enforced before extra files are copied', () async {
    final file = await source('valid.pdf');
    final result = await imports.stage(
      List.generate(30, (i) => (path: file.path, name: '$i.pdf')),
      limit: 25,
    );
    expect(result.candidates.length, 25);
    expect(result.overLimit, 5);
    final files = await Directory(
      p.join(root.path, 'import_staging'),
    ).list(recursive: true).where((e) => e is File).toList();
    expect(files.length, 25);
  });

  test(
    'promotion and rollback preserve staging for retry and originals',
    () async {
      final file = await source('valid.pdf');
      final result = await imports.stage([
        (path: file.path, name: 'valid.pdf'),
      ], limit: 25);
      final c = result.candidates.single;
      final saved = (await imports.promote(c)).single;
      expect(await File(saved).readAsString(), 'source bytes');
      await imports.removePromoted(saved);
      expect(await File(saved).exists(), false);
      expect(await File(c.attachments.single.path).exists(), true);
      final retried = (await imports.promote(c)).single;
      await imports.removeStaged(c);
      await imports.discard();
      expect(await File(retried).exists(), true);
      expect(await file.exists(), true);
    },
  );

  test(
    'session cleanup and removal cannot delete another session or original',
    () async {
      final file = await source('valid.pdf');
      final other = BulkImportLocalDataSource(rootDirectory: () async => root);
      final c = (await other.stage([
        (path: file.path, name: 'valid.pdf'),
      ], limit: 25)).candidates.single;
      await imports.removeStaged(c);
      await imports.removePromoted(file.path);
      await imports.discard();
      expect(await File(c.attachments.single.path).exists(), true);
      expect(await file.exists(), true);
    },
  );

  test(
    'startup cleanup removes abandoned sessions but preserves saved documents',
    () async {
      final file = await source('valid.pdf');
      final c = (await imports.stage([
        (path: file.path, name: 'valid.pdf'),
      ], limit: 25)).candidates.single;
      final saved = (await imports.promote(c)).single;
      await BulkImportLocalDataSource.cleanupStaleSessions(
        rootDirectory: () async => root,
      );
      expect(await File(c.attachments.single.path).exists(), false);
      expect(await File(saved).exists(), true);
      expect(await file.exists(), true);
    },
  );
}
