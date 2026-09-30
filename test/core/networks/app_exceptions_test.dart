import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/core/networks/exceptions/app_exceptions.dart';

void main() {
  test('keeps FastAPI detail free of an HTTP status prefix for users', () {
    final error = NotFoundException('No account found with this email.');

    expect(error.message, 'No account found with this email.');
    expect(
      error.toString(),
      'Resource Not Found: No account found with this email.',
    );
  });
}
