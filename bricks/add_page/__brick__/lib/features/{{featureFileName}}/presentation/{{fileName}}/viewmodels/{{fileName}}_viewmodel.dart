import 'package:flutter/foundation.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../domain/usecases/{{fileName}}_usecase.dart';

class {{className}}ViewModel extends ChangeNotifier with UseCaseExecutor {
  final {{className}}Usecase _{{camelName}}Usecase;

  {{className}}ViewModel({required {{className}}Usecase {{camelName}}Usecase})
    : _{{camelName}}Usecase = {{camelName}}Usecase;

  Future<void> performAction() async {
    await execute(
      call: () => _{{camelName}}Usecase(NoParams()),
      onSuccess: (result) {},
    );
  }
}
