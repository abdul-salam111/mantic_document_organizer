import '../../../networks/exceptions/app_exceptions.dart';

/// This project's own success/failure wrapper — used everywhere a
/// datasource/repository/usecase would otherwise return
/// `Either<AppException, T>` from a third-party package (fpdart).
///
/// Keeping this as an app-owned type (rather than exposing `Either`
/// directly through every domain contract) means the domain layer's public
/// API doesn't leak a specific FP library's types, the same way
/// [Usecase]/`BaseUsecase` already wraps "a function that can fail" instead
/// of every feature reinventing that shape by hand.
///
/// A `switch` on [Result] is exhaustive without a default case, since
/// [Success] and [Failure] are the only subtypes.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Collapses the two branches into a single value — the direct
  /// replacement for `Either.fold((error) {...}, (data) {...})`, just with
  /// named parameters so it's unambiguous which callback is which at the
  /// call site.
  R fold<R>({
    required R Function(AppException error) onFailure,
    required R Function(T value) onSuccess,
  }) {
    final self = this;
    return switch (self) {
      Success<T>() => onSuccess(self.value),
      Failure<T>() => onFailure(self.error),
    };
  }
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}
