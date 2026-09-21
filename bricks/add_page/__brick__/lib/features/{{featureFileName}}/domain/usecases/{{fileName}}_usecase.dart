import '../../../../core/shared/shared_exports.dart';
import '../repositories/{{featureFileName}}_repository.dart';

/// TODO: this is a stub — `I{{featureClassName}}Repository` doesn't have a
/// `{{camelName}}(...)` method yet. Add one to it (and its impl) with
/// whatever request/response types this page actually needs, replace
/// `dynamic`/`NoParams` below with those types, and replace the
/// `UnimplementedError` with the real call.
class {{className}}Usecase implements Usecase<dynamic, NoParams> {
  final I{{featureClassName}}Repository repository;

  {{className}}Usecase({required this.repository});

  @override
  Future<Result<dynamic>> call(NoParams params) {
    throw UnimplementedError(
      'Wire {{className}}Usecase up to I{{featureClassName}}Repository once '
      'you\'ve added a {{camelName}}(...) method to it.',
    );
  }
}
