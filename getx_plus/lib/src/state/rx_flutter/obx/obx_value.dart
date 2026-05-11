import 'package:flutter/widgets.dart';
import 'package:getx_plus/getx_plus.dart';

class ObxValue<T extends RxInterface> extends ObxWidget {
  final Widget Function(T) builder;
  final T data;

  const ObxValue(this.builder, this.data, {super.key});

  @override
  Widget build(BuildContext context) => builder(data);
}
