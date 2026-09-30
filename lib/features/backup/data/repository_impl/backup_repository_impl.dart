import '../../../../core/shared/shared_exports.dart';
import '../../../auth/data/datasources/social_identity_datasource.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/entities/backup_space.dart';
import '../datasources/backup_remote_datasource.dart';

class BackupRepositoryImpl extends BaseRepository implements IBackupRepository {
  final IBackupRemoteDataSource remote;
  final ISocialIdentityDataSource identity;
  BackupRepositoryImpl({required this.remote, required this.identity});
  @override
  Future<Result<BackupSpace>> preparePersonalSpace(
    String token,
    String? savedSpaceId,
  ) async {
    final spaces = await execute(call: () => remote.listSpaces(token));
    if (spaces case Failure<List<BackupSpaceModel>>(:final error)) {
      return Failure(error);
    }
    final existing = (spaces as Success<List<BackupSpaceModel>>).value;
    BackupSpaceModel? space;
    for (final item in existing) {
      if (item.id == savedSpaceId) {
        space = item;
        break;
      }
    }
    if (space != null) {
      return Success(_toEntity(space));
    }
    final created = await execute(
      call: () => remote.createPersonalSpace(token),
    );
    return created.fold(
      onFailure: Failure.new,
      onSuccess: (value) => Success(_toEntity(value)),
    );
  }

  @override
  Future<Result<BackupSpace>> connectGoogleDrive(
    String token,
    String spaceId,
  ) async {
    final codeResult = await execute(
      call: identity.requestGoogleDriveAuthorizationCode,
    );
    return codeResult.fold(
      onFailure: Failure.new,
      onSuccess: (code) async {
        final remoteResult = await execute(
          call: () => remote.connectGoogleDrive(token, spaceId, code),
        );
        return remoteResult.fold(
          onFailure: Failure.new,
          onSuccess: (value) => Success(_toEntity(value)),
        );
      },
    );
  }

  BackupSpace _toEntity(BackupSpaceModel model) => BackupSpace(
    id: model.id,
    name: model.name,
    storageStatus: model.storageStatus,
  );
}
