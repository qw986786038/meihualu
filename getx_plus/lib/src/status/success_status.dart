import 'get_status.dart';

class SuccessStatus<T> extends GetStatus<T> {
  final T data;

  const SuccessStatus(this.data);

  @override
  List get props => [data];
}
