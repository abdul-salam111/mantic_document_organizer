import '../../../../core/shared/shared_exports.dart';
import '../repositories/backup_repository.dart';
import '../entities/backup_space.dart';

class PrepareBackupUsecase
    implements Usecase<BackupSpace, ({String token, String? savedSpaceId})> {
  final IBackupRepository repository;
  PrepareBackupUsecase(this.repository);
  @override
  Future<Result<BackupSpace>> call(
    ({String token, String? savedSpaceId}) params,
  ) => repository.preparePersonalSpace(params.token, params.savedSpaceId);
}

class ConnectGoogleDriveUsecase
    implements Usecase<BackupSpace, ({String token, String spaceId})> {
  final IBackupRepository repository;
  ConnectGoogleDriveUsecase(this.repository);
  @override
  Future<Result<BackupSpace>> call(({String token, String spaceId}) params) =>
      repository.connectGoogleDrive(params.token, params.spaceId);
}
