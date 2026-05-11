import 'package:flutter/widgets.dart';

import 'full_life_cycle_controller.dart';

mixin FullLifeCycleMixin on FullLifeCycleController {
  @mustCallSuper
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @mustCallSuper
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @mustCallSuper
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.inactive:
        onInactive();
        break;
      case AppLifecycleState.paused:
        onPaused();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
      case AppLifecycleState.hidden:
        onHidden();
        break;
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    onMemoryPressure();
  }

  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    onAccessibilityChanged();
  }

  void onResumed() {}

  void onPaused() {}

  void onInactive() {}

  void onDetached() {}

  void onHidden() {}

  void onMemoryPressure() {}

  void onAccessibilityChanged() {}
}
