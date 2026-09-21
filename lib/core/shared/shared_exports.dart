// Barrel export for lib/core/shared — the Clean Architecture base classes
// every feature's data/domain layer builds on: BaseRemoteDatasource,
// BaseRepository, Usecase, UseCaseExecutor, PaginationExecutor (for
// paginated lists), and Result (this project's own success/failure
// wrapper — see domain/result/result.dart for why it's not just fpdart's
// Either exposed directly).
export 'datasource/base_datasource.dart';
export 'domain/repository/base_repository.dart';
export 'domain/result/result.dart';
export 'domain/usecase/base_usecase.dart';
export 'domain/usecase/execute_usecase.dart';
export 'domain/usecase/pagination_executor.dart';
