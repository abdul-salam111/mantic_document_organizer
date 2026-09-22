// Regression tests for TEMPLATE_REVIEW.txt §2.8: CustomButton must not
// overflow at large accessibility text scales, and its minimum height
// must act as a floor (not a fixed size) when content needs more room.

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/widgets/buttons/custom_button.dart';

void main() {
  testWidgets(
    'does not overflow with a long label at a large text scale',
    (tester) async {
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
    },
  );

  testWidgets(
    'grows past its 50px minimum height when a short label needs more room',
    (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: MaterialApp(
            home: Scaffold(body: CustomButton(text: 'Go', onPressed: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(ElevatedButton));
      expect(size.height, greaterThan(50));
    },
  );
}
