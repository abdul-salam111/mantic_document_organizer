import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/login_user/login_user.dart';
import '../models/request_models/signup_user/signup_user.dart';
import '../models/response_models/user_data_model/user_model.dart';

abstract interface class IRemoteAuthDataSource {
  Future<UserModel> loginUser({required LoginUser loginUser});
  Future<UserModel> signupUser({required SignupUser signupUser});
}

class RemoteAuthDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteAuthDataSource {
  RemoteAuthDataSourceImpl({required super.dioHelper});

  @override
  Future<UserModel> loginUser({required LoginUser loginUser}) async {
    return post(
      url: ApiEndPoints.loginByUid,
      parser: (json) => UserModel.fromJson(json),
      body: loginUser.toJson(),
    );
  }

  @override
  Future<UserModel> signupUser({required SignupUser signupUser}) async {
    return post(
      url: ApiEndPoints.signupUser,
      parser: (json) => UserModel.fromJson(json),
      body: signupUser.toJson(),
    );
  }
}
