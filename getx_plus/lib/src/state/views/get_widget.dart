import 'package:flutter/widgets.dart';
import 'package:getx_plus/getx_plus.dart';

abstract class GetWidget<S extends GetLifeCycleMixin> extends GetWidgetCache {
  const GetWidget({super.key});

  @protected
  final String? tag = null;

  String? get widgetTag => tag;

  S get controller => GetWidget.cacheStore[this] as S;

  static final cacheStore = Expando<GetLifeCycleMixin>();

  @protected
  Widget build(BuildContext context);

  Widget buildWidget(BuildContext context) => build(context);

  @override
  WidgetCache createWidgetCache() => GetWidgetCacheImpl<S>();
}
