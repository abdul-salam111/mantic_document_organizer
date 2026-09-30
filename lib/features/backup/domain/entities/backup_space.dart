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
