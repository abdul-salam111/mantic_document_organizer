import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/builtin_categories.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';

void main() {
  group('isBuiltInCategoryId', () {
    test('is true for every shipped built-in id', () {
      for (final category in builtInCategories) {
        expect(isBuiltInCategoryId(category.id), isTrue, reason: category.id);
      }
    });

    test('is false for a custom category id', () {
      expect(isBuiltInCategoryId('some-custom-uuid'), isFalse);
    });

    test('is false for the uncategorized sentinel', () {
      expect(isBuiltInCategoryId('uncategorized'), isFalse);
    });
  });

  group('builtInCategoryDefault', () {
    test('returns the shipped default for a known built-in id', () {
      final bank = builtInCategoryDefault('bank');
      expect(bank, isNotNull);
      expect(bank!.name, 'Bank');
      expect(bank.iconKey, 'buildingColumns');
    });

    test('returns null for a non-built-in id', () {
      expect(builtInCategoryDefault('some-custom-uuid'), isNull);
    });
  });

  group('builtInCategoryDivergesFromDefault', () {
    test('is false for an untouched built-in', () {
      const bank = CategoryItem(
        id: 'bank',
        name: 'Bank',
        iconKey: 'buildingColumns',
        colorValue: 0xFF4CAF50,
      );
      expect(builtInCategoryDivergesFromDefault(bank), isFalse);
    });

    test('is true once the name has been edited', () {
      const renamed = CategoryItem(
        id: 'bank',
        name: 'Banking & Finance',
        iconKey: 'buildingColumns',
        colorValue: 0xFF4CAF50,
      );
      expect(builtInCategoryDivergesFromDefault(renamed), isTrue);
    });

    test('is true once the color has been edited', () {
      const recolored = CategoryItem(
        id: 'bank',
        name: 'Bank',
        iconKey: 'buildingColumns',
        colorValue: 0xFF112233,
      );
      expect(builtInCategoryDivergesFromDefault(recolored), isTrue);
    });

    test('is true once the icon has been edited', () {
      const reIconed = CategoryItem(
        id: 'bank',
        name: 'Bank',
        iconKey: 'star',
        colorValue: 0xFF4CAF50,
      );
      expect(builtInCategoryDivergesFromDefault(reIconed), isTrue);
    });

    test('is false for a category that is not a built-in at all', () {
      const custom = CategoryItem(
        id: 'some-custom-uuid',
        name: 'Kids School Forms',
        iconKey: 'star',
        colorValue: 0xFF112233,
      );
      expect(builtInCategoryDivergesFromDefault(custom), isFalse);
    });

    test('is false again after being edited back to the exact default', () {
      const revertedBank = CategoryItem(
        id: 'bank',
        name: 'Bank',
        iconKey: 'buildingColumns',
        colorValue: 0xFF4CAF50,
      );
      expect(builtInCategoryDivergesFromDefault(revertedBank), isFalse);
    });
  });
}
