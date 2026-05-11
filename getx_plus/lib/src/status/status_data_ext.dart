import 'empty_status.dart';
import 'error_status.dart';
import 'get_status.dart';
import 'loading_status.dart';
import 'success_status.dart';

extension StatusDataExt<T> on GetStatus<T> {
  bool get isLoading => this is LoadingStatus;

  bool get isSuccess => this is SuccessStatus;

  bool get isError => this is ErrorStatus;

  bool get isEmpty => this is EmptyStatus;

  bool get isCustom => !isLoading && !isSuccess && !isError && !isEmpty;

  dynamic get error {
    if (this is ErrorStatus) {
      return (this as ErrorStatus).error;
    }
    return null;
  }

  String get errorMessage {
    final isError = this is ErrorStatus;
    if (isError) {
      final err = this as ErrorStatus;
      if (err.error != null) {
        if (err.error is String) {
          return err.error as String;
        }
        return err.error.toString();
      }
    }

    return '';
  }

  T? get data {
    if (this is SuccessStatus<T>) {
      final success = this as SuccessStatus<T>;
      return success.data;
    }
    return null;
  }
}
