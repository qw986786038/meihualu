import 'package:flutter/widgets.dart';
import 'package:getx_plus/getx_plus.dart';

mixin ScrollMixin on GetLifeCycleMixin {
  final ScrollController scroll = ScrollController();

  @override
  void onInit() {
    super.onInit();
    scroll.addListener(_listener);
  }

  bool _canFetchBottom = true;
  bool _canFetchTop = true;

  void _listener() {
    if (scroll.position.atEdge) {
      _checkIfCanLoadMore();
    }
  }

  Future<void> _checkIfCanLoadMore() async {
    if (scroll.position.pixels == 0) {
      if (!_canFetchTop) return;
      _canFetchTop = false;
      await onTopScroll();
      _canFetchTop = true;
    } else {
      if (!_canFetchBottom) return;
      _canFetchBottom = false;
      await onEndScroll();
      _canFetchBottom = true;
    }
  }

  Future<void> onEndScroll();

  Future<void> onTopScroll();

  @override
  void onClose() {
    scroll.removeListener(_listener);
    scroll.dispose();
    super.onClose();
  }
}
