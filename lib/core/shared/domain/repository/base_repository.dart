import '../../../networks/exceptions/app_exceptions.dart';
import '../result/result.dart';

/* -------------------------------------------------------------------------- */
/*                             Base Repository                                 */
/* -------------------------------------------------------------------------- */

abstract class BaseRepository {
  /// Execute repository call with automatic error handling.
  /// Wraps the result in [Result]<[AppException], T>.
  Future<Result<T>> execute<T>({required Future<T> Function() call}) async {
    try {
      final result = await call();
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException(e.toString()));
    }
  }
}
