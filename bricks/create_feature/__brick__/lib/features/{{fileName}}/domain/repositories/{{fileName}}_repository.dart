import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/{{fileName}}_params.dart';
import '../entities/{{fileName}}_entity.dart';

abstract interface class I{{className}}Repository {
  Future<Result<{{className}}Entity>> performAction({
    required {{className}}Params params,
  });
}
