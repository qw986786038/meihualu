import 'package:flutter/widgets.dart';

import 'obx_stateless_widget.dart';

class Observer extends ObxStatelessWidget {
  final WidgetBuilder builder;

  const Observer({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context);
}
