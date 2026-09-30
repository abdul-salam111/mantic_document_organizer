import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/login_user/login_user.dart';
import '../models/request_models/signup_user/signup_user.dart';
import '../models/response_models/user_data_model/user_model.dart';

abstract interface class IRemoteAuthDataSource {
  Future<AuthTokenPairModel> loginUser({required LoginUser loginUser});
  Future<UserModel> signupUser({required SignupUser signupUser});
  Future<UserModel> currentUser({required String accessToken});
}

class RemoteAuthDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteAuthDataSource {
  RemoteAuthDataSourceImpl({required super.dioHelper});

  @override
  Future<AuthTokenPairModel> loginUser({required LoginUser loginUser}) async {
    return post(
      url: ApiEndPoints.signIn,
      parser: (json) =>
          AuthTokenPairModel.fromJson(Map<String, dynamic>.from(json as Map)),
      body: loginUser.toJson(),
    );
  }

  @override
  Future<UserModel> signupUser({required SignupUser signupUser}) async {
    return post(
      url: ApiEndPoints.signUp,
      parser: (json) =>
          UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
      body: signupUser.toJson(),
    );
  }

  @override
  Future<UserModel> currentUser({required String accessToken}) => get(
    url: ApiEndPoints.currentUser,
    authToken: accessToken,
    parser: (json) =>
        UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );
}
