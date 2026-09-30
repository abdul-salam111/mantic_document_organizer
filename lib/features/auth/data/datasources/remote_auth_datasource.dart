import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/login_user/login_user.dart';
import '../models/request_models/signup_user/signup_user.dart';
import '../models/response_models/user_data_model/user_model.dart';

abstract interface class IRemoteAuthDataSource {
  Future<AuthTokenPairModel> loginUser({required LoginUser loginUser});
  Future<UserModel> signupUser({required SignupUser signupUser});
  Future<AuthTokenPairModel> signInWithGoogle({required String idToken});
  Future<AuthTokenPairModel> signInWithApple({
    required String identityToken,
    String? displayName,
  });
  Future<void> signOut({required String refreshToken});
  Future<UserModel> verifyEmail({required String email, required String code});
  Future<void> resendVerificationEmail({required String email});
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
  Future<AuthTokenPairModel> signInWithGoogle({required String idToken}) =>
      post(
        url: ApiEndPoints.signInWithGoogle,
        body: {'id_token': idToken},
        parser: (json) =>
            AuthTokenPairModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );

  @override
  Future<AuthTokenPairModel> signInWithApple({
    required String identityToken,
    String? displayName,
  }) => post(
    url: ApiEndPoints.signInWithApple,
    body: {
      'identity_token': identityToken,
      if (displayName != null) 'display_name': displayName,
    },
    parser: (json) =>
        AuthTokenPairModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<void> signOut({required String refreshToken}) async {
    await dioHelper.postApi(
      url: ApiEndPoints.signOut,
      requestBody: {'refresh_token': refreshToken},
    );
  }

  @override
  Future<UserModel> verifyEmail({
    required String email,
    required String code,
  }) => post(
    url: ApiEndPoints.verifyEmail,
    body: {'email': email, 'code': code},
    parser: (json) =>
        UserModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    await dioHelper.postApi(
      url: ApiEndPoints.resendVerificationEmail,
      requestBody: {'email': email},
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
