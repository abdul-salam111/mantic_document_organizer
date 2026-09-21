/// The domain-layer representation of a signed-in user — what the rest of
/// the app (presentation, session storage) works with, decoupled from
/// `UserModel`'s API response shape (see `AuthRepositoryImpl._toEntity`,
/// which maps one to the other at the repository boundary).
class AuthEntity {
  final String id;
  final String? name;
  final String? email;
  final String? token;

  const AuthEntity({required this.id, this.name, this.email, this.token});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'token': token,
  };

  factory AuthEntity.fromJson(Map<String, dynamic> json) => AuthEntity(
    id: json['id'] as String? ?? '',
    name: json['name'] as String?,
    email: json['email'] as String?,
    token: json['token'] as String?,
  );
}
