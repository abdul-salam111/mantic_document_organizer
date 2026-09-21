import 'package:flutter/foundation.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/{{fileName}}_params.dart';
import '../../../domain/entities/{{fileName}}_entity.dart';
import '../../../domain/usecases/{{fileName}}_usecase.dart';

class {{className}}ViewModel extends ChangeNotifier with UseCaseExecutor {
  final {{className}}Usecase _{{camelName}}Usecase;

  {{className}}ViewModel({required {{className}}Usecase {{camelName}}Usecase})
      : _{{camelName}}Usecase = {{camelName}}Usecase;

  {{className}}Entity? _data;
  {{className}}Entity? get data => _data;

  Future<void> performAction() async {
    await execute(
      call: () => _{{camelName}}Usecase(
        {{className}}Params(
          param1: 'value1',
          param2: 'value2',
        ),
      ),
      onSuccess: (result) {
        _data = result;
        // `execute()` already notified listeners for the loading→success
        // transition before calling this callback, so this second call is
        // what actually makes `_data`'s new value show up in a rebuild.
        notifyListeners();
      },
    );
  }
}
