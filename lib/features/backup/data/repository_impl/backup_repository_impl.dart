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

    // The saved id is only trusted if it still genuinely names the
    // personal backup space. A Space can also be a shared category (see
    // ShareCategoryUsecase) -- matching by id alone let a previous bug
    // save one of those here by mistake (e.g. right after sharing a
    // category, before this device ever had a real personal space),
    // silently uploading personal, unshared documents into a space other
    // people can join. Re-checking the name heals a device that already
    // has the wrong id saved, instead of trusting it forever.
    for (final item in existing) {
      if (item.id == savedSpaceId && item.name == personalBackupSpaceName) {
        return Success(_toEntity(item));
      }
    }
    // Secure storage is intentionally cleared on uninstall. Reuse the
    // account's existing personal backup space on a new device instead of
    // creating a second "My backup" and restoring from the wrong one --
    // matched by name, not "any active space": a shared category's space
    // is just as "active" once its owner has Drive connected, so that
    // used to match here too.
    for (final item in existing) {
      if (item.name == personalBackupSpaceName) {
        return Success(_toEntity(item));
      }
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
