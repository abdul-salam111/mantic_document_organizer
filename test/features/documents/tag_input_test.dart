import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/di/injection_container.dart';
import 'package:mantic_doc_org/core/localization/localization_exports.dart';
import 'package:mantic_doc_org/core/theme/theme.dart';
import 'package:mantic_doc_org/core/widgets/inputs/custom_textfield.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_processing_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:mantic_doc_org/features/documents/presentation/add_document/viewmodels/add_document_viewmodel.dart';
import 'package:mantic_doc_org/features/documents/presentation/add_document/views/add_document_view.dart';

import '../bulk_import/bulk_import_fakes.dart';

void main() {
  late AddDocumentViewModel vm;

  Finder input() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller == vm.tagController,
  );
  Finder decorator() =>
      find.ancestor(of: input(), matching: find.byType(InputDecorator));
  FocusNode focusNode(WidgetTester tester) =>
      tester.widget<TextField>(input()).focusNode!;

  Future<void> showForm(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await sl.reset();
    final categories = FakeCategories();
    final documents = FakeDocuments();
    vm = AddDocumentViewModel(
      categoryUseCases: CategoryUseCases(categories),
      documentUseCases: DocumentUseCases(documents),
      processing: DocumentProcessingUseCases(FakeProcessing()),
    );
    sl.registerFactory<AddDocumentViewModel>(() => vm);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await sl.reset();
      categories.dispose();
      documents.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppThemes.lightTheme
            : AppThemes.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const AddDocumentView(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(input());
  }

  testWidgets('empty space focuses the one field and typing updates its hint', (
    tester,
  ) async {
    await showForm(tester);

    expect(decorator(), findsOneWidget);
    expect(tester.widget<InputDecorator>(decorator()).isEmpty, isTrue);
    final box = tester.getRect(decorator());
    final blankSpace = Offset(box.right - 24, box.center.dy);
    expect(tester.getRect(input()).contains(blankSpace), isFalse);
    await tester.tapAt(blankSpace);
    await tester.pump();

    expect(focusNode(tester).hasFocus, isTrue);
    expect(tester.widget<InputDecorator>(decorator()).isFocused, isTrue);
    await tester.enterText(input(), 'Car Insurance');
    await tester.pump();
    expect(tester.widget<InputDecorator>(decorator()).isEmpty, isFalse);
    vm.tagController.clear();
    await tester.pump();
    expect(tester.widget<InputDecorator>(decorator()).isEmpty, isTrue);
  });

  testWidgets('comma, Done, and Enter add inline chips and keep the cursor', (
    tester,
  ) async {
    await showForm(tester);
    await tester.enterText(input(), 'Car Insurance,');
    await tester.pump();

    expect(vm.tags, ['Car Insurance']);
    expect(vm.tagController.text, isEmpty);
    expect(focusNode(tester).hasFocus, isTrue);
    expect(
      find.descendant(of: decorator(), matching: find.byType(Chip)),
      findsOneWidget,
    );
    expect(tester.widget<InputDecorator>(decorator()).isEmpty, isFalse);

    await tester.enterText(input(), 'Medical');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(vm.tags, ['Car Insurance', 'Medical']);
    expect(vm.tagController.text, isEmpty);
    expect(focusNode(tester).hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(input(), 'Work');
    // The engine translates a physical Enter to this action. A raw
    // sendKeyEvent in a widget test bypasses that engine translation.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(vm.tags, ['Car Insurance', 'Medical', 'Work']);
    expect(focusNode(tester).hasFocus, isTrue);

    await tester.enterText(input(), ',');
    await tester.pump();
    expect(vm.tags, hasLength(3));
    expect(vm.tagController.text, isEmpty);
  });

  testWidgets(
    'tapping a chip selects it and Backspace removes the selected tag',
    (tester) async {
      await showForm(tester);
      await tester.enterText(input(), 'Insurance,');
      await tester.pump();
      focusNode(tester).unfocus();
      await tester.pump();
      await tester.tap(find.text('Insurance'));
      await tester.pump();
      expect(focusNode(tester).hasFocus, isTrue);
      final selectedChip = tester.widget<Chip>(find.byType(Chip));
      expect(selectedChip.shape, isA<StadiumBorder>());

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(vm.tags, isEmpty);
      expect(find.byType(Chip), findsNothing);
      expect(focusNode(tester).hasFocus, isTrue);
      expect(tester.widget<InputDecorator>(decorator()).isEmpty, isTrue);

      await tester.enterText(input(), 'Insurance,');
      await tester.pump();

      focusNode(tester).unfocus();
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(Chip),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pump();
      expect(vm.tags, isEmpty);
      expect(find.byType(Chip), findsNothing);
      expect(focusNode(tester).hasFocus, isTrue);
      expect(tester.widget<InputDecorator>(decorator()).isEmpty, isTrue);
    },
  );

  testWidgets('chips use compact padding and sizing', (tester) async {
    await showForm(tester);
    await tester.enterText(input(), 'ID,');
    await tester.pump();

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.padding, EdgeInsets.zero);
    expect(chip.labelPadding, const EdgeInsets.symmetric(horizontal: 4));
    expect(chip.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
    expect(tester.getSize(find.byType(Chip)).height, lessThanOrEqualTo(28));
  });

  testWidgets('tag input disables IME suggestions for comma delimiters', (
    tester,
  ) async {
    await showForm(tester);

    final field = tester.widget<TextField>(input());
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
  });

  testWidgets('the one-line form controls use the same height', (tester) async {
    await showForm(tester);

    expect(tester.getSize(find.byType(TextFormField)).height, 55);
    expect(tester.getSize(decorator()).height, 55);
    final fixedHeightControls = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.minHeight == 55,
    );
    expect(fixedHeightControls, findsNWidgets(2));
    for (final element in fixedHeightControls.evaluate()) {
      expect(tester.getSize(find.byWidget(element.widget)).height, 55);
    }
  });

  testWidgets('title is optional', (tester) async {
    await showForm(tester);

    final title = tester.widget<CustomTextFormField>(
      find.byType(CustomTextFormField),
    );
    expect(title.isRequired, isFalse);
    expect(title.validator, isNull);
  });

  testWidgets('tapping empty form space dismisses the tag keyboard', (
    tester,
  ) async {
    await showForm(tester);
    await tester.tap(input());
    await tester.pump();
    expect(focusNode(tester).hasFocus, isTrue);

    final list = tester.getRect(find.byType(ListView));
    await tester.tapAt(Offset(list.left + 2, list.top + 2));
    await tester.pump();
    expect(focusNode(tester).hasFocus, isFalse);
  });

  testWidgets('Android-style text deletion removes a selected tag', (
    tester,
  ) async {
    await showForm(tester);
    await tester.enterText(input(), 'Insurance,');
    await tester.pump();
    await tester.tap(find.text('Insurance'));
    await tester.pump();

    // Android software keyboards can update the editing value without
    // routing a Flutter KeyEvent. Deleting the selected-tag marker is the
    // path used by the field on those keyboards.
    tester.testTextInput.updateEditingValue(TextEditingValue.empty);
    await tester.pump();

    expect(vm.tags, isEmpty);
    expect(vm.tagController.text, isEmpty);
    expect(focusNode(tester).hasFocus, isTrue);
  });

  testWidgets('invalid tags keep their text and validation clears on editing', (
    tester,
  ) async {
    await showForm(tester);
    await tester.enterText(input(), 'Insurance,');
    await tester.pump();
    await tester.enterText(input(), 'insurance,');
    await tester.pump();
    expect(vm.tags, ['Insurance']);
    expect(vm.tagController.text, 'insurance');
    expect(vm.tagError, TagError.duplicate);
    expect(
      tester.widget<InputDecorator>(decorator()).decoration.errorText,
      isNotNull,
    );
    expect(focusNode(tester).hasFocus, isTrue);

    await tester.enterText(input(), 'Family');
    await tester.pump();
    expect(vm.tagError, isNull);
    expect(
      tester.widget<InputDecorator>(decorator()).decoration.errorText,
      isNull,
    );
    await tester.enterText(input(), '${'a' * 21},');
    await tester.pump();
    expect(vm.tagController.text, 'a' * 21);
    expect(vm.tagError, TagError.tooLong);
    expect(vm.tags, ['Insurance']);
  });

  testWidgets('comma commits an IME-composed tag immediately', (tester) async {
    await showForm(tester);
    await tester.showKeyboard(input());
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '保険,',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      ),
    );
    await tester.pump();
    expect(vm.tags, ['保険']);
    expect(vm.tagController.text, isEmpty);
    expect(focusNode(tester).hasFocus, isTrue);
  });

  testWidgets(
    'deferred comma does not consume a newer edit or a disposed field',
    (tester) async {
      await showForm(tester);
      final formatter = tester.widget<TextField>(input()).inputFormatters!.last;
      final stripped = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'Insurance,'),
      );
      expect(stripped.text, 'Insurance');
      expect(vm.tags, isEmpty);
      vm.tagController.value = stripped;
      vm.tagController.text = 'New edit';
      await tester.pump();
      expect(vm.tags, isEmpty);
      expect(vm.tagController.text, 'New edit');

      await tester.pumpWidget(const SizedBox.shrink());
      formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'Insurance,'),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'comma commits when Android restores the comma after formatting',
    (tester) async {
      await showForm(tester);
      final formatter = tester.widget<TextField>(input()).inputFormatters!.last;

      formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'Insurance,'),
      );
      // Some Android IMEs send this value after the formatter has already
      // returned the comma-stripped value to the framework.
      vm.tagController.text = 'Insurance,';
      await tester.pump();

      expect(vm.tags, ['Insurance']);
      expect(vm.tagController.text, isEmpty);
      expect(focusNode(tester).hasFocus, isTrue);
    },
  );

  testWidgets(
    'controller fallback commits a comma Android leaves in the field',
    (tester) async {
      await showForm(tester);

      // Some Android IMEs bypass the formatter for a composing update and
      // leave this final value directly in the controller.
      vm.tagController.text = 'Insurance,';
      await tester.pump();

      expect(vm.tags, ['Insurance']);
      expect(vm.tagController.text, isEmpty);
      expect(focusNode(tester).hasFocus, isTrue);
    },
  );

  testWidgets('save requires at least one attached document', (tester) async {
    await showForm(tester);

    expect(vm.validateAttachments(), isFalse);
    await tester.pump();

    expect(vm.showAttachmentError, isTrue);
    expect(find.text('Add at least one document to save'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'chips wrap inside one ${brightness.name} field on a narrow screen',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await showForm(tester, brightness: brightness, textScale: 1.5);
        for (final tag in [
          'Car Insurance',
          'Family Documents',
          'Medical Records',
        ]) {
          vm.tagController.text = tag;
          vm.addTag();
        }
        await tester.pump();
        await tester.ensureVisible(input());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(decorator(), findsOneWidget);
        final box = tester.getRect(decorator());
        final chipRects = [
          for (final chip in find.byType(Chip).evaluate())
            tester.getRect(find.byWidget(chip.widget)),
        ];
        expect(
          chipRects.map((rect) => rect.top).toSet().length,
          greaterThan(1),
        );
        for (final rect in [...chipRects, tester.getRect(input())]) {
          expect(box.contains(rect.topLeft), isTrue);
          expect(box.contains(rect.bottomRight), isTrue);
        }
        expect(tester.getSize(input()).width, 140);
      },
    );
  }
}
