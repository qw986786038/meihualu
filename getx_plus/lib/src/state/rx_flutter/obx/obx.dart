import 'package:flutter/widgets.dart';

import 'obx_widget.dart';

typedef WidgetCallback = Widget Function();

class Obx extends ObxWidget {
  final WidgetCallback builder;

  const Obx(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}
