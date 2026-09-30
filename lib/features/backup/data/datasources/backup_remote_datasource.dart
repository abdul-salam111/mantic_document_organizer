import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';

class BackupSpaceModel {
  final String id;
  final String name;
  final String storageStatus;
  const BackupSpaceModel({
    required this.id,
    required this.name,
    required this.storageStatus,
  });
  factory BackupSpaceModel.fromJson(Map<String, dynamic> json) =>
      BackupSpaceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        storageStatus: json['storage_status'] as String? ?? 'unconfigured',
      );
}

abstract interface class IBackupRemoteDataSource {
  Future<List<BackupSpaceModel>> listSpaces(String token);
  Future<BackupSpaceModel> createPersonalSpace(String token);
  Future<BackupSpaceModel> connectGoogleDrive(
    String token,
    String spaceId,
    String authorizationCode,
  );
}

class BackupRemoteDataSourceImpl extends BaseRemoteDatasource
    implements IBackupRemoteDataSource {
  BackupRemoteDataSourceImpl({required super.dioHelper});
  @override
  Future<List<BackupSpaceModel>> listSpaces(String token) => getList(
    url: ApiEndPoints.spaces,
    authToken: token,
    parser: (json) =>
        BackupSpaceModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );
  @override
  Future<BackupSpaceModel> createPersonalSpace(String token) => post(
    url: ApiEndPoints.spaces,
    authToken: token,
    body: const {'name': 'My backup'},
    parser: (json) =>
        BackupSpaceModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );
  @override
  Future<BackupSpaceModel> connectGoogleDrive(
    String token,
    String spaceId,
    String authorizationCode,
  ) => post(
    url: '${ApiEndPoints.spaces}/$spaceId/connect-google-drive',
    authToken: token,
    body: {'authorization_code': authorizationCode},
    parser: (json) =>
        BackupSpaceModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );
}
