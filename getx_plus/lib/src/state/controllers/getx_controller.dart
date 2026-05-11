import 'package:flutter/foundation.dart';
import 'package:getx_plus/getx_plus.dart';

/// A reactive controller that integrates with [GetBuilder] and the DI system.
///
/// Extend [GetController] to create controllers with automatic lifecycle
/// management and targeted UI rebuilds:
///
/// ```dart
/// class CounterController extends GetController {
///   int count = 0;
///
///   void increment() {
///     count++;
///     update(); // triggers all GetBuilder<CounterController> to rebuild
///   }
///
///   void incrementSection() {
///     count++;
///     update(['counter-section']); // only rebuilds widgets with id:'counter-section'
///   }
/// }
/// ```
// ignore: prefer_mixin
abstract class GetController extends ListNotifier with GetLifeCycleMixin {
  @override
  @mustCallSuper
  void onClose() {
    dispose();
  }

  /// Notifies listeners to rebuild.
  ///
  /// - Pass [ids] to only update [GetBuilder] widgets with a matching [id].
  /// - Use [condition] to conditionally skip an update.
  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) return;
    if (ids == null) {
      refresh();
    } else if (ids.length == 1) {
      refreshGroup(ids.first);
    } else {
      for (final id in ids.toSet()) {
        refreshGroup(id);
      }
    }
  }
}

/// Backward-compatible alias for [GetController].
typedef GetxController = GetController;
