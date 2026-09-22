// Smoke test: verifies the app boots through its real routing/DI setup
// and lands on the sign-in screen. Replace/extend this as real features
// are added — this only proves the app doesn't crash on startup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/di/injection_container.dart';
import 'package:mantic_doc_org/core/theme/theme_controller.dart';
import 'package:mantic_doc_org/core/widgets/inputs/custom_textfield.dart';
import 'package:mantic_doc_org/features/auth/presentation/signin/views/signin_page.dart';
import 'package:mantic_doc_org/main.dart';



// DioHelper polls connectivity on its own Timer for the lifetime of its
// registration (see TEMPLATE_REVIEW.txt §2.5) — flutter_test asserts no
// Timer survives past the end of a test. sl.reset() disposes it (see the
// `dispose:` callback on DioHelper's registration in
// core/di/injection_container.dart), but that has to happen as an
// explicit, awaited step at the end of each test body — not via
// `tearDown`/`addTearDown`. Both of those only run after the *entire*
// test closure passed to `testWidgets` returns, and flutter_test's
// pending-timer check runs inside that same closure, right after the
// test body completes — so by the time tearDown/addTearDown callbacks
// fire, the check has already failed.
Future<void> _disposeLocator() => sl.reset();

void main() {
  setUp(() async {
    await sl.reset();
    await setupLocator();
  });

  testWidgets('App boots and shows the sign-in form', (
    WidgetTester tester,
  ) async {
    try {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(SigninPage), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(CustomTextFormField), findsNWidgets(2));
    } finally {
      await _disposeLocator();
    }
  });

  testWidgets('Theme toggle switches the app between light and dark', (
    WidgetTester tester,
  ) async {
    try {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final themeController = sl<ThemeController>();
      expect(themeController.themeMode, ThemeMode.system);

      await tester.tap(find.byTooltip('Toggle theme'));
      await tester.pumpAndSettle();

      expect(themeController.isDarkMode, isTrue);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    } finally {
      await _disposeLocator();
    }
  });

  testWidgets('Sign-in fields do not force word capitalization', (
    WidgetTester tester,
  ) async {
    try {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final fields = tester.widgetList<CustomTextFormField>(
        find.byType(CustomTextFormField),
      );
      expect(fields, isNotEmpty);
      for (final field in fields) {
        expect(field.textCapitalization, TextCapitalization.none);
      }
    } finally {
      await _disposeLocator();
    }
  });
}
