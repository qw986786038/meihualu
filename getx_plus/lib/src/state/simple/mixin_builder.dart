import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

/// Combines [GetBuilder] and [Obx] so the widget responds to both
/// `controller.update()` calls **and** changes to Rx observables inside the
/// builder function.
///
/// Prefer composing [GetBuilder] + [Obx] manually for clarity.
class MixinBuilder<T extends GetController> extends StatelessWidget {
  const MixinBuilder({
    super.key,
    this.init,
    this.global = true,
    required this.builder,
    this.autoRemove = true,
    this.tag,
    this.id,
  });

  final T? init;
  final bool global;
  final bool autoRemove;
  final String? tag;
  final Object? id;
  final Widget Function(T controller) builder;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<T>(
      init: init,
      global: global,
      autoRemove: autoRemove,
      tag: tag,
      id: id,
      builder: (controller) => Obx(() => builder(controller)),
    );
  }
}
