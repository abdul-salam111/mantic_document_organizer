// Regression tests for TEMPLATE_REVIEW.txt §2.8: CustomButton must not
// overflow at large accessibility text scales, and its minimum height
// must act as a floor (not a fixed size) when content needs more room.

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/widgets/buttons/custom_button.dart';

void main() {
  testWidgets('loading keeps a bottom navigation button compact', (
    tester,
  ) async {
    final saving = ValueNotifier(false);
    addTearDown(saving.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: saving,
          builder: (context, isSaving, _) => Scaffold(
            body: const Center(child: Text('Document form')),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const .symmetric(horizontal: 16, vertical: 12),
                child: CustomButton(
                  text: 'Save',
                  isLoading: isSaving,
                  onPressed: () => saving.value = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final button = find.byType(ElevatedButton);
    final idleRect = tester.getRect(button);
    await tester.tap(button);
    await tester.pump();

    expect(tester.getRect(button), idleRect);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    expect(tester.takeException(), isNull);

    saving.value = false;
    await tester.pumpAndSettle();
    expect(tester.getRect(button), idleRect);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
  });

  testWidgets('does not overflow with a long label at a large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Continue with a fairly long label',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'grows past its 50px minimum height when a short label needs more room',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: MaterialApp(
            home: Scaffold(
              body: CustomButton(text: 'Go', onPressed: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(ElevatedButton));
      expect(size.height, greaterThan(50));
    },
  );
}
