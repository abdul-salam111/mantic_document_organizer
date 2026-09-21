// Barrel export for the auth feature — this is what OTHER
// features/core files import to reach auth's public API (e.g. a page for
// routing, or its models for a DI registration). Files *inside* the auth
// feature should import each other with relative paths, not this file.
//
// data/ and domain/ are shared across every auth sub-flow (signin, and
// future signup/forgot-password/etc.). presentation/ is split one folder
// per sub-flow (presentation/signin/, presentation/signup/, ...), each
// with its own views/ and viewmodels/, since those are the only parts
// that don't overlap between sub-flows.
export 'data/datasources/remote_auth_datasource.dart';
export 'data/models/request_models/login_user/login_user.dart';
export 'data/models/request_models/signup_user/signup_user.dart';
export 'data/models/response_models/user_data_model/user_model.dart';
export 'data/repository_impl/auth_repository_impl.dart';
export 'domain/entities/auth_entity.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/signin_usecase.dart';
export 'domain/usecases/signup_usecase.dart';
export 'presentation/signin/views/signin_page.dart';
export 'presentation/signin/viewmodels/signin_viewmodel.dart';
export 'presentation/signup/views/signup_page.dart';
export 'presentation/signup/viewmodels/signup_viewmodel.dart';
