import '../../../../core/shared/shared_exports.dart';
import '../entities/backup_space.dart';

abstract interface class IBackupRepository {
  Future<Result<BackupSpace>> preparePersonalSpace(
    String token,
    String? savedSpaceId,
  );
  Future<Result<BackupSpace>> connectGoogleDrive(String token, String spaceId);
}
