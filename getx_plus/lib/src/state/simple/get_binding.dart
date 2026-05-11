import 'package:flutter/widgets.dart';
import 'package:getx_plus/getx_plus.dart';

/// Scopes a single dependency to a widget subtree.
///
/// Registers [T] when this widget enters the tree and disposes it when removed.
/// Preferred over [Get.put] when you want the lifecycle bound to a specific
/// widget rather than the entire app.
///
/// ```dart
/// GetBinding<CounterController>(
///   create: () => CounterController(),
///   child: CounterPage(),
/// )
/// ```
///
/// For app startup setup, prefer [Binding] with [Get.runBinding].
/// For app-wide singletons, prefer [Get.put] or [Get.lazyPut].
class GetBinding<T> extends StatefulWidget {
  const GetBinding({
    super.key,
    required this.create,
    required this.child,
    this.tag,
  });

  /// Factory that creates the instance to register.
  final T Function() create;

  final Widget child;

  /// Optional tag if you need multiple instances of the same type.
  final String? tag;

  @override
  State<GetBinding<T>> createState() => _GetBindingState<T>();
}

class _GetBindingState<T> extends State<GetBinding<T>> {
  @override
  void initState() {
    super.initState();
    Get.put<T>(widget.create(), tag: widget.tag);
  }

  @override
  void dispose() {
    Get.delete<T>(tag: widget.tag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Scopes multiple dependencies to a widget subtree.
///
/// Registers all [binds] when entering the tree and removes them on disposal.
///
/// ```dart
/// MultiBinding(
///   binds: [
///     () => Get.lazyPut(() => AuthController()),
///     () => Get.lazyPut(() => ProfileController()),
///   ],
///   dispose: [
///     () => Get.delete<AuthController>(),
///     () => Get.delete<ProfileController>(),
///   ],
///   child: ProfilePage(),
/// )
/// ```
class MultiBinding extends StatefulWidget {
  const MultiBinding({
    super.key,
    required this.binds,
    required this.dispose,
    required this.child,
  });

  final List<void Function()> binds;
  final List<void Function()> dispose;
  final Widget child;

  @override
  State<MultiBinding> createState() => _MultiBindingState();
}

class _MultiBindingState extends State<MultiBinding> {
  @override
  void initState() {
    super.initState();
    for (final bind in widget.binds) {
      bind();
    }
  }

  @override
  void dispose() {
    for (final disposer in widget.dispose) {
      disposer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
