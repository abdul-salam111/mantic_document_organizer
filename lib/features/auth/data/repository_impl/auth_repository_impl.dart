import '../../../../core/shared/shared_exports.dart';
import '../datasources/remote_auth_datasource.dart';
import '../datasources/social_identity_datasource.dart';
import '../models/request_models/login_user/login_user.dart';
import '../models/request_models/signup_user/signup_user.dart';
import '../models/response_models/user_data_model/user_model.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends BaseRepository implements IAuthRepository {
  final IRemoteAuthDataSource dataSource;
  final ISocialIdentityDataSource socialIdentityDataSource;

  AuthRepositoryImpl({
    required this.dataSource,
    required this.socialIdentityDataSource,
  });

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

  @override
  Future<Result<AuthEntity>> signInWithGoogle() async {
    final identityResult = await execute(
      call: socialIdentityDataSource.signInWithGoogle,
    );
    return identityResult.fold(
      onFailure: Failure.new,
      onSuccess: (identity) => _completeSocialSignIn(
        () => dataSource.signInWithGoogle(idToken: identity.idToken),
      ),
    );
  }

  @override
  Future<Result<AuthEntity>> signInWithApple() async {
    final identityResult = await execute(
      call: socialIdentityDataSource.signInWithApple,
    );
    return identityResult.fold(
      onFailure: Failure.new,
      onSuccess: (identity) => _completeSocialSignIn(
        () => dataSource.signInWithApple(
          identityToken: identity.idToken,
          displayName: identity.displayName,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> signOut({required String refreshToken}) {
    return execute(call: () => dataSource.signOut(refreshToken: refreshToken));
  }

  @override
  Future<Result<AuthEntity>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final result = await execute(
      call: () => dataSource.verifyEmail(email: email, code: code),
    );
    return result.fold(
      onFailure: (error) => Failure(error),
      onSuccess: (model) => Success(_toEntity(model)),
    );
  }

  @override
  Future<Result<void>> resendVerificationEmail({required String email}) {
    return execute(
      call: () => dataSource.resendVerificationEmail(email: email),
    );
  }

  Future<Result<AuthEntity>> _completeSocialSignIn(
    Future<AuthTokenPairModel> Function() exchangeToken,
  ) async {
    final tokensResult = await execute(call: exchangeToken);
    return tokensResult.fold(
      onFailure: Failure.new,
      onSuccess: (tokens) async {
        final userResult = await execute(
          call: () => dataSource.currentUser(accessToken: tokens.accessToken),
        );
        return userResult.fold(
          onFailure: Failure.new,
          onSuccess: (user) => Success(
            _toEntity(
              user,
              accessToken: tokens.accessToken,
              refreshToken: tokens.refreshToken,
            ),
          ),
        );
      },
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
