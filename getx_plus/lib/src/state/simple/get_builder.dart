import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:getx_plus/getx_plus.dart';

/// Listens to a [GetController] and rebuilds whenever it calls [update()].
///
/// **Basic usage** (controller pre-registered with [Get.put]):
/// ```dart
/// GetBuilder<MyController>(
///   builder: (ctrl) => Text('${ctrl.count}'),
/// )
/// ```
///
/// **Auto-register** by providing [init]:
/// ```dart
/// GetBuilder<MyController>(
///   init: MyController(),
///   builder: (ctrl) => Text('${ctrl.count}'),
/// )
/// ```
///
/// **Targeted update** — only rebuild when `update(['section'])` is called:
/// ```dart
/// GetBuilder<MyController>(
///   id: 'section',
///   builder: (ctrl) => Text('${ctrl.count}'),
/// )
/// ```
///
/// **Local (non-global) controller** — lifecycle scoped to this widget:
/// ```dart
/// GetBuilder<MyController>(
///   global: false,
///   init: MyController(),
///   builder: (ctrl) => Text('${ctrl.count}'),
/// )
/// ```
class GetBuilder<T extends GetController> extends StatefulWidget {
  const GetBuilder({
    super.key,
    required this.builder,
    this.init,
    this.tag,
    this.id,
    this.autoRemove = true,
    this.global = true,
    this.initState,
    this.dispose,
    this.didChangeDependencies,
    this.didUpdateWidget,
  });

  /// Build function receiving the resolved controller.
  final Widget Function(T controller) builder;

  /// Provide an instance to auto-register if [T] is not yet in the DI container.
  final T? init;

  /// Optional tag for multiple instances of the same type.
  final String? tag;

  /// When set, this widget only rebuilds on `controller.update([id])` calls.
  final Object? id;

  /// Automatically deletes the controller when this widget is disposed.
  /// Only applies when this widget was the one that registered the controller.
  final bool autoRemove;

  /// `true` (default) — uses the global DI container via [Get.find].
  /// `false` — creates a local instance scoped to this widget's lifetime.
  final bool global;

  final void Function(GetBuilderState<T> state)? initState;
  final void Function(GetBuilderState<T> state)? dispose;
  final void Function(GetBuilderState<T> state)? didChangeDependencies;
  final void Function(GetBuilder<T> oldWidget, GetBuilderState<T> state)?
  didUpdateWidget;

  @override
  GetBuilderState<T> createState() => GetBuilderState<T>();
}

class GetBuilderState<T extends GetController> extends State<GetBuilder<T>> {
  T? controller;
  bool _isCreator = false;
  Disposer? _remove;
  bool _scheduledRebuild = false;

  @override
  void initState() {
    super.initState();
    widget.initState?.call(this);

    if (widget.global) {
      final isRegistered = Get.isRegistered<T>(tag: widget.tag);
      if (isRegistered) {
        _isCreator = Get.isPrepared<T>(tag: widget.tag);
        controller = Get.find<T>(tag: widget.tag);
      } else if (widget.init != null) {
        Get.put<T>(widget.init!, tag: widget.tag);
        _isCreator = true;
        controller = Get.find<T>(tag: widget.tag);
      } else {
        throw GetDependencyNotFound(
          '"${T.toString()}" is not registered. '
          'Provide [init] or call Get.put<${T.toString()}>() before this widget.',
        );
      }
    } else {
      assert(widget.init != null, 'GetBuilder(global:false) requires [init].');
      controller = widget.init!;
      _isCreator = true;
      if (controller is GetLifeCycleMixin) {
        (controller as GetLifeCycleMixin).onStart();
      }
    }

    _subscribe();
  }

  void _subscribe() {
    _remove?.call();
    if (widget.id == null) {
      _remove = controller!.addListener(_rebuild);
    } else {
      _remove = controller!.addListenerId(widget.id, _rebuild);
    }
  }

  void _rebuild() {
    if (!mounted || _scheduledRebuild) return;
    _scheduledRebuild = true;
    scheduleMicrotask(() {
      _scheduledRebuild = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call(this);
  }

  @override
  void didUpdateWidget(GetBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.didUpdateWidget?.call(oldWidget, this);
    if (oldWidget.id != widget.id) {
      _subscribe();
    }
  }

  @override
  void dispose() {
    widget.dispose?.call(this);
    _scheduledRebuild = false;
    _remove?.call();
    _remove = null;
    if (_isCreator && widget.autoRemove) {
      if (widget.global) {
        Get.delete<T>(tag: widget.tag);
      } else if (controller is GetLifeCycleMixin) {
        (controller as GetLifeCycleMixin).onDelete();
      }
    }
    controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(controller!);
}
