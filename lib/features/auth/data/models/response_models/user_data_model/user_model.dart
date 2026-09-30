/// FastAPI's `UserResponse`. It is kept as a data DTO; the repository maps it
/// to [AuthEntity] before presentation sees it.
class UserModel {
  final String id;
  final String email;
  final String displayName;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['display_name'] as String,
  );
}

/// FastAPI's `TokenPairResponse`. Profile data is intentionally fetched from
/// `/auth/me` after sign-in instead of attempting to decode an access JWT in
/// the mobile client.
class AuthTokenPairModel {
  final String accessToken;
  final String refreshToken;

  const AuthTokenPairModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokenPairModel.fromJson(Map<String, dynamic> json) =>
      AuthTokenPairModel(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
