import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/bulk_import/presentation/bulk_import_review_view.dart';
import 'bulk_import_fakes.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('review fits small ${brightness.name} screen with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = ImportFixture();
      f.seedFound([candidate('a', extension: 'pdf')]);
      await f.vm.discover();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: BulkImportReviewView(viewModel: f.vm),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Import 1 documents'), findsOneWidget);
      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'updated suggestions display and removing another row preserves edits',
    (tester) async {
      final f = ImportFixture();
      f.seedFound([
        candidate('a', extension: 'pdf'),
        candidate('b', extension: 'pdf'),
      ]);
      await f.vm.discover();
      await tester.pumpWidget(
        MaterialApp(home: BulkImportReviewView(viewModel: f.vm)),
      );
      await tester.pumpAndSettle();
      f.vm.updateTitle('b', 'Second edited title');
      await tester.pump();
      expect(find.text('Second edited title'), findsOneWidget);
      await f.vm.remove('a');
      await tester.pumpAndSettle();
      expect(find.text('Second edited title'), findsOneWidget);
      expect(find.text('Original a'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('system back disposes review without recursive navigation', (
    tester,
  ) async {
    final f = ImportFixture();
    f.seedFound([candidate('a', extension: 'pdf')]);
    await f.vm.discover();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Import intro')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => BulkImportReviewView(viewModel: f.vm),
      ),
    );
    await tester.pumpAndSettle();
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Import intro'), findsOneWidget);
    expect(f.imports.discarded, 1);
    expect(f.documents.documents, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
