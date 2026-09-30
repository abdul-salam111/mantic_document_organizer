import 'package:flutter_test/flutter_test.dart';
import 'package:mantic_doc_org/features/auth/data/models/request_models/signup_user/signup_user.dart';
import 'package:mantic_doc_org/features/auth/data/models/response_models/user_data_model/user_model.dart';

void main() {
  test('sign-up sends FastAPI display_name field', () {
    final request = SignupUser(
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      password: 'correct-horse-battery-staple',
    );

    expect(request.toJson(), {
      'display_name': 'Ada Lovelace',
      'email': 'ada@example.com',
      'password': 'correct-horse-battery-staple',
    });
  });

  test('parses FastAPI user and token-pair responses', () {
    final user = UserModel.fromJson({
      'id': 'e0c68ef3-0dab-4dbf-a8a5-80e4c65ff098',
      'email': 'ada@example.com',
      'display_name': 'Ada Lovelace',
      'email_verified_at': null,
      'created_at': '2026-09-30T00:00:00Z',
    });
    final tokens = AuthTokenPairModel.fromJson({
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
      'token_type': 'bearer',
    });

    expect(user.id, 'e0c68ef3-0dab-4dbf-a8a5-80e4c65ff098');
    expect(user.displayName, 'Ada Lovelace');
    expect(tokens.accessToken, 'access-token');
    expect(tokens.refreshToken, 'refresh-token');
  });
}
