import 'package:flutter/widgets.dart';
import 'package:getx_plus/getx_plus.dart';

class GetWidgetCacheImpl<S extends GetLifeCycleMixin>
    extends WidgetCache<GetWidget<S>> {
  S? _controller;
  bool _isCreator = false;
  InstanceInfo? info;

  @override
  void onInit() {
    info = Get.getInstanceInfo<S>(tag: widget!.widgetTag);

    _isCreator = info!.isPrepared && info!.isFactory;

    if (info!.isRegistered) {
      _controller = Get.find<S>(tag: widget!.widgetTag);
    }

    GetWidget.cacheStore[widget!] = _controller;

    super.onInit();
  }

  @override
  void onClose() {
    if (_isCreator) {
      Future.microtask(() {
        widget!.controller.onDelete();
        Get.log('"${widget!.controller.runtimeType}" onClose() called');
        Get.log('"${widget!.controller.runtimeType}" deleted from memory');
      });
    }
    info = null;
    super.onClose();
  }

  @override
  Widget build(BuildContext context) {
    // Controller is accessible via Get.find<S>() in descendant widgets.
    return widget!.buildWidget(context);
  }
}
