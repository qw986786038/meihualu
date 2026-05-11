import 'package:flutter/widgets.dart';

typedef ValueBuilderUpdateCallback<T> = void Function(T snapshot);
typedef ValueBuilderBuilder<T> =
    Widget Function(T snapshot, ValueBuilderUpdateCallback<T> updater);
