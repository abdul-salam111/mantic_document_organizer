import 'space_role.dart';

class MemberEntity {
  final String userId;
  final SpaceRole role;
  final String displayName;
  final String email;
  final DateTime joinedAt;

  const MemberEntity({
    required this.userId,
    required this.role,
    required this.displayName,
    required this.email,
    required this.joinedAt,
  });
}
