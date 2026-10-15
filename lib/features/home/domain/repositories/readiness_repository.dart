import '../../../../core/shared/domain/result/result.dart';
import '../entities/document_readiness.dart';

abstract interface class IReadinessRepository {
  Future<Result<ReadinessPreferences>> load();
  Future<Result<ReadinessPreferences>> save(ReadinessPreferences preferences);
}
