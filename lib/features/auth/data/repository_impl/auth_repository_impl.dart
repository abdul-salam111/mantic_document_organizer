import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_auth_datasource.dart';
import '../models/request_models/login_user/login_user.dart';
import '../models/request_models/signup_user/signup_user.dart';
import '../models/response_models/user_data_model/user_model.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends BaseRepository implements IAuthRepository {
  final IRemoteAuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Result<AuthEntity>> signinUser({required LoginUser loginUser}) async {
    final result = await execute(
      call: () => dataSource.loginUser(loginUser: loginUser),
    );
    if (result case Failure<AuthTokenPairModel>(:final error)) {
      return Failure(error);
    }
    final tokens = (result as Success<AuthTokenPairModel>).value;
    final userResult = await execute(
      call: () => dataSource.currentUser(accessToken: tokens.accessToken),
    );
    return userResult.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (user) => Success(
        _toEntity(
          user,
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        ),
      ),
    );
  }

  @override
  Future<Result<AuthEntity>> signupUser({
    required SignupUser signupUser,
  }) async {
    final result = await execute(
      call: () => dataSource.signupUser(signupUser: signupUser),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (model) => Success(_toEntity(model)),
    );
  }

  /// Maps FastAPI response DTOs at the data/domain boundary.
  AuthEntity _toEntity(
    UserModel model, {
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthEntity(
      id: model.id,
      name: model.displayName,
      email: model.email,
      token: accessToken,
      refreshToken: refreshToken,
    );
  }
}
