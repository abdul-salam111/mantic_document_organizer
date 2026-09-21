// Regression test for TEMPLATE_REVIEW.txt §2.9: validateAge must account
// for whether today's month/day has passed the birth month/day yet, not
// just subtract calendar years.

import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

void main() {
  group('Validator.validateAge', () {
    test(
      'rejects someone whose birthday this year has not happened yet, '
      'even though the plain year subtraction would meet minAge',
      () {
        final today = DateTime.now();
        // Birthday is tomorrow (wrapping within the year) — plain year
        // subtraction says minAge, but they haven't actually turned it yet.
        final notYetBirthday = DateTime(
          today.year - 18,
          today.month,
          today.day,
        ).add(const Duration(days: 1));

        final result = Validator.validateAge(_isoDate(notYetBirthday), 18);

        expect(result, 'You must be at least 18 years old');
      },
    );

    test('accepts someone whose birthday today or earlier already makes '
        'them minAge', () {
      final today = DateTime.now();
      final justTurned = DateTime(today.year - 18, today.month, today.day);

      final result = Validator.validateAge(_isoDate(justTurned), 18);

      expect(result, isNull);
    });
  });
}
