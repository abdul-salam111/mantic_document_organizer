/// The fixed name every personal backup space is created with (see
/// BackupRemoteDataSourceImpl.createPersonalSpace) -- the one reliable way
/// to tell it apart from a Space that's actually a shared category (see
/// ShareCategoryUsecase), since the backend models both as a plain,
/// undifferentiated `Space` row with no "kind" field.
const personalBackupSpaceName = 'My backup';

class BackupSpace {
  final String id;
  final String name;
  final String storageStatus;
  const BackupSpace({
    required this.id,
    required this.name,
    required this.storageStatus,
  });
  bool get isDriveConnected => storageStatus.toLowerCase() == 'active';
}
