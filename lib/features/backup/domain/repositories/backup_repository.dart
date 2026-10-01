import '../../../../core/shared/shared_exports.dart';
import '../entities/backup_space.dart';

abstract interface class IBackupRepository {
  Future<Result<BackupSpace>> preparePersonalSpace(
    String token,
    String? savedSpaceId,
  );

  /// Returns the backend-issued Google consent URL bound to this backup space.
  Future<Result<String>> connectGoogleDrive(String token, String spaceId);
}
