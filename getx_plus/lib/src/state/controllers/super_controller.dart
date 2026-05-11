import 'package:getx_plus/getx_plus.dart';

abstract class SuperController<T> extends FullLifeCycleController
    with FullLifeCycleMixin, StateMixin<T> {}
