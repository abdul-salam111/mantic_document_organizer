import '../result/result.dart';

abstract interface class Usecase<SuccessType, Params> {
  Future<Result<SuccessType>> call(Params params);
}

class NoParams {}
