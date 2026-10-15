import '../../../../core/shared/domain/result/result.dart';
import '../../../../core/shared/domain/usecase/base_usecase.dart';
import '../entities/document_readiness.dart';
import '../repositories/readiness_repository.dart';

class LoadReadiness implements Usecase<ReadinessPreferences, NoParams> {
  final IReadinessRepository repository;
  LoadReadiness(this.repository);
  @override
  Future<Result<ReadinessPreferences>> call(NoParams params) => repository.load();
}
class SaveReadiness implements Usecase<ReadinessPreferences, ReadinessPreferences> {
  final IReadinessRepository repository;
  SaveReadiness(this.repository);
  @override
  Future<Result<ReadinessPreferences>> call(ReadinessPreferences params) => repository.save(params);
}
