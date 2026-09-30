/// The domain-layer representation of an authenticated account. Tokens are
/// issued only by FastAPI's sign-in endpoint; sign-up returns a user profile
/// and deliberately leaves both tokens null until the user signs in.
class AuthEntity {
  final String id;
  final String? name;
  final String? email;
  final String? token;
  final String? refreshToken;

  const AuthEntity({
    required this.id,
    this.name,
    this.email,
    this.token,
    this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'token': token,
    'refreshToken': refreshToken,
  };

  factory AuthEntity.fromJson(Map<String, dynamic> json) => AuthEntity(
    id: json['id'] as String? ?? '',
    name: json['name'] as String?,
    email: json['email'] as String?,
    token: json['token'] as String?,
    refreshToken: json['refreshToken'] as String?,
  );
}
