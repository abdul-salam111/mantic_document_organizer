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
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (model) => Success(_toEntity(model)),
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

  /// Maps the raw API response model to this feature's domain entity, so
  /// nothing above the repository boundary needs to know about
  /// `UserModel`'s response-JSON shape.
  AuthEntity _toEntity(UserModel model) {
    final data = model.data;
    return AuthEntity(
      id: data?.id?.toString() ?? '',
      name: data?.name,
      email: data?.email,
      token: data?.token,
    );
  }
}
