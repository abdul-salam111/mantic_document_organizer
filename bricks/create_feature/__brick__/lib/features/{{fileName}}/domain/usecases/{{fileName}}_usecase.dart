import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/{{fileName}}_params.dart';
import '../entities/{{fileName}}_entity.dart';
import '../repositories/{{fileName}}_repository.dart';

class {{className}}Usecase implements Usecase<{{className}}Entity, {{className}}Params> {
  final I{{className}}Repository repository;

  {{className}}Usecase({required this.repository});

  @override
  Future<Result<{{className}}Entity>> call({{className}}Params params) {
    return repository.performAction(params: params);
  }
}
