import 'dart:async';

import 'package:flutter/widgets.dart';

import '../simple/list_notifier.dart';

mixin StatelessObserverComponent on StatelessElement {
  List<Disposer>? disposers = <Disposer>[];

  // Prevents scheduling redundant microtasks when multiple Rx variables
  // change in the same synchronous call. Without this, N simultaneous Rx
  // writes schedule N microtasks, each allocating a closure and doing a
  // redundant (but idempotent) markNeedsBuild() call.
  bool _scheduledUpdate = false;

  void getUpdate() {
    if (disposers != null && !_scheduledUpdate) {
      _scheduledUpdate = true;
      scheduleMicrotask(() {
        _scheduledUpdate = false;
        if (mounted) markNeedsBuild();
      });
    }
  }

  @override
  Widget build() {
    // Clear stale subscriptions from the previous build before re-subscribing.
    // Without this, Rx variables accessed in conditional branches accumulate
    // listeners across rebuilds, causing phantom rebuilds and memory leaks.
    for (final d in disposers!) {
      d();
    }
    disposers!.clear();

    return Notifier.instance.append(
      NotifyData(disposers: disposers!, updater: getUpdate),
      super.build,
    );
  }

  @override
  void unmount() {
    super.unmount();
    _scheduledUpdate = false;
    for (final disposer in disposers!) {
      disposer();
    }
    disposers!.clear();
    disposers = null;
  }
}
