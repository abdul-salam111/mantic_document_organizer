// Regression test for TEMPLATE_REVIEW.txt §1.2: CustomAppBar's title text
// color once matched its own background color (both context.primary),
// making the title invisible. This asserts the two stay distinct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/theme/theme.dart';
import 'package:mantic_doc_org/core/widgets/appbar/custom_appbar.dart';



void main() {
  testWidgets('CustomAppBar title color contrasts with its background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: const Scaffold(appBar: CustomAppBar(title: 'Title')),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final titleText = appBar.title! as Text;
    final resolvedTextColor = titleText.style!.color;
    final resolvedBackgroundColor = appBar.backgroundColor;

    expect(resolvedTextColor, isNotNull);
    expect(resolvedBackgroundColor, isNotNull);
    expect(
      resolvedTextColor,
      isNot(equals(resolvedBackgroundColor)),
      reason: 'AppBar title must contrast with its own background color',
    );
  });
}
