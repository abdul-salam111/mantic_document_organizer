import '../../../../core/shared/shared_exports.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/entities/backup_space.dart';
import '../datasources/backup_remote_datasource.dart';

class BackupRepositoryImpl extends BaseRepository implements IBackupRepository {
  final IBackupRemoteDataSource remote;
  BackupRepositoryImpl({required this.remote});
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
    // Secure storage is intentionally cleared on uninstall. Reuse the
    // account's existing active backup space on a new device instead of
    // creating an empty "My backup" space and restoring from the wrong one.
    for (final item in existing) {
      if (item.storageStatus.toLowerCase() == 'active') {
        return Success(_toEntity(item));
      }
    }
    if (existing.isNotEmpty) {
      return Success(_toEntity(existing.first));
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
  Future<Result<String>> connectGoogleDrive(
    String token,
    String spaceId,
  ) async {
    return execute(
      call: () => remote.googleDriveAuthorizationUrl(token, spaceId),
    );
  }

  BackupSpace _toEntity(BackupSpaceModel model) => BackupSpace(
    id: model.id,
    name: model.name,
    storageStatus: model.storageStatus,
  );
}
