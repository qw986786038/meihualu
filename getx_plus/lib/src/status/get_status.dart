import 'package:equatable/equatable.dart';

import 'custom_status.dart';
import 'empty_status.dart';
import 'error_status.dart';
import 'loading_status.dart';
import 'success_status.dart';

abstract class GetStatus<T> extends Equatable {
  const GetStatus();

  factory GetStatus.loading() => LoadingStatus<T>();

  factory GetStatus.error(Object message) => ErrorStatus<T, Object>(message);

  factory GetStatus.empty() => EmptyStatus<T>();

  factory GetStatus.success(T data) => SuccessStatus<T>(data);

  factory GetStatus.custom() => CustomStatus<T>();
}
