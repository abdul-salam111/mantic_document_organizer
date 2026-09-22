// Regression test for TEMPLATE_REVIEW_NEW.txt §2.9: DateTime.getAge() is the
// single implementation `Validator.validateAge` now delegates to — this
// covers it directly instead of only through the validator.

import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/utils/date_utils.dart';

void main() {
  group('DateTime.getAge', () {
    test(
      'does not count this year if the birthday has not happened yet',
      () {
        final today = DateTime.now();
        final notYetBirthday = DateTime(
          today.year - 18,
          today.month,
          today.day,
        ).add(const Duration(days: 1));

        expect(notYetBirthday.getAge(), 17);
      },
    );

    test('counts this year once the birthday has happened (today or '
        'earlier)', () {
      final today = DateTime.now();
      final justTurned = DateTime(today.year - 18, today.month, today.day);

      expect(justTurned.getAge(), 18);
    });
  });
}
