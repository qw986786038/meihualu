import 'package:flutter/material.dart';

import 'bind.dart';

/// **Deprecated.** The `Binds` widget is no longer used by route [Binding]s.
/// Use [MultiBinding] or nest [GetBinding] widgets instead.
@Deprecated('Use MultiBinding or nest GetBinding widgets instead.')
class Binds extends StatelessWidget {
  // ignore: deprecated_member_use_from_same_package
  final List<Bind<dynamic>> binds;
  final Widget child;

  // ignore: deprecated_member_use_from_same_package
  Binds({super.key, required this.binds, required this.child})
    : assert(binds.isNotEmpty);

  @override
  Widget build(BuildContext context) =>
      // ignore: deprecated_member_use_from_same_package
      binds.reversed.fold(child, (widget, e) => e.copyWithChild(widget));
}
