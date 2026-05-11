import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

/// **Deprecated.** Use [Get.put], [Get.lazyPut], [Get.find], or [GetBinding]
/// instead. This class is kept for backward compatibility only.
///
/// Migration guide:
/// - `Bind.put<T>(t)`        → `Get.put<T>(t)`
/// - `Bind.lazyPut<T>(() => t)` → `Get.lazyPut<T>(() => t)`
/// - `Bind.find<T>()`        → `Get.find<T>()`
/// - `Bind.delete<T>()`      → `Get.delete<T>()`
/// - `Bind.builder(...)`     → `GetBinding<T>(create: ..., child: ...)`
@Deprecated(
  'Use Get.put / Get.lazyPut / Get.find / GetBinding instead. '
  'Bind will be removed in a future version.',
)
abstract class Bind<T> extends StatelessWidget {
  const Bind({super.key, this.child});

  final Widget? child;

  @Deprecated('Use Get.put() instead.')
  static S put<S>(S dependency, {String? tag, bool permanent = false}) =>
      Get.put<S>(dependency, tag: tag, permanent: permanent);

  @Deprecated('Use Get.lazyPut() instead.')
  static void lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool? fenix,
    VoidCallback? onClose,
  }) => Get.lazyPut<S>(builder, tag: tag, fenix: fenix);

  @Deprecated('Use Get.find() instead.')
  static S find<S>({String? tag}) => Get.find<S>(tag: tag);

  @Deprecated('Use Get.delete() instead.')
  static bool delete<S>({String? tag, bool force = false}) =>
      Get.delete<S>(tag: tag, force: force);

  @Deprecated('Use Get.deleteAll() instead.')
  static void deleteAll({bool force = false}) => Get.deleteAll(force: force);

  @Deprecated('Use Get.isRegistered() instead.')
  static bool isRegistered<S>({String? tag}) => Get.isRegistered<S>(tag: tag);

  @Deprecated('Use Get.isPrepared() instead.')
  static bool isPrepared<S>({String? tag}) => Get.isPrepared<S>(tag: tag);

  @Deprecated('Use GetBinding<T> widget instead.')
  factory Bind.builder({
    Widget? child,
    T Function()? init,
    bool global = true,
    bool autoRemove = true,
    String? tag,
  }) => _LegacyBind<T>(
    child: child ?? const SizedBox.shrink(),
    init: init,
    tag: tag,
  );

  @factory
  Bind<T> copyWithChild(Widget child);
}

class _LegacyBind<T> extends Bind<T> {
  const _LegacyBind({super.key, super.child, this.init, this.tag});

  final T Function()? init;
  final String? tag;

  @override
  Bind<T> copyWithChild(Widget child) =>
      _LegacyBind<T>(child: child, init: init, tag: tag);

  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}
