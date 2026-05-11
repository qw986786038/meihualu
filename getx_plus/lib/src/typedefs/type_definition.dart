import 'package:flutter/material.dart';

import 'package:getx_plus/getx_plus.dart';

typedef NotifierBuilder<T> = Widget Function(T state);

typedef InitBuilder<T> = T Function();

typedef GetControllerBuilder<T extends GetLifeCycleMixin> =
    Widget Function(T controller);
