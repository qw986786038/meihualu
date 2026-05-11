import 'dart:collection';

import 'package:flutter/foundation.dart';

// Callback to remove the listener on addListener function
typedef Disposer = void Function();

// State update callback for widget rebuilds
typedef GetStateUpdate = void Function();

class ListNotifier extends Listenable
    with ListNotifierSingleMixin, ListNotifierGroupMixin {}

/// A Notifier with single listeners
class ListNotifierSingle = ListNotifier with ListNotifierSingleMixin;

/// A notifier with group of listeners identified by id
class ListNotifierGroup = ListNotifier with ListNotifierGroupMixin;

/// This mixin add to Listenable the addListener, removerListener and
/// containsListener implementation
mixin ListNotifierSingleMixin on Listenable {
  List<GetStateUpdate?>? _updaters = <GetStateUpdate?>[];
  int _activeListeners = 0;
  int _notificationCallDepth = 0;

  @override
  Disposer addListener(GetStateUpdate listener) {
    assert(_debugAssertNotDisposed());
    _updaters!.add(listener);
    _activeListeners++;
    return () => removeListener(listener);
  }

  bool containsListener(GetStateUpdate listener) {
    final updaters = _updaters;
    if (updaters == null || _activeListeners == 0) return false;
    for (final updater in updaters) {
      if (identical(updater, listener)) return true;
    }
    return false;
  }

  @override
  void removeListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    final updaters = _updaters;
    if (updaters == null || _activeListeners == 0) return;
    for (var i = 0; i < updaters.length; i++) {
      if (identical(updaters[i], listener)) {
        if (_notificationCallDepth > 0) {
          updaters[i] = null;
        } else {
          updaters.removeAt(i);
        }
        _activeListeners--;
        return;
      }
    }
  }

  @protected
  void refresh() {
    assert(_debugAssertNotDisposed());
    _notifyUpdate();
  }

  @protected
  void reportRead() {
    Notifier.instance.read(this);
  }

  @protected
  void reportAdd(VoidCallback disposer) {
    Notifier.instance.add(disposer);
  }

  void _notifyUpdate() {
    final updaters = _updaters;
    if (updaters == null || _activeListeners == 0) return;
    // Fast path: single listener — avoid iterating sparse/null entries.
    if (_activeListeners == 1) {
      for (final updater in updaters) {
        if (updater != null) {
          updater();
          break;
        }
      }
      return;
    }
    // Iterate in-place to avoid per-refresh list copy allocations.
    // Removals during notification are marked as null and compacted later.
    _notificationCallDepth++;
    for (var i = 0; i < updaters.length; i++) {
      final element = updaters[i];
      if (element != null) {
        element();
      }
    }
    _notificationCallDepth--;

    if (_notificationCallDepth == 0 &&
        _activeListeners > 0 &&
        updaters.length > (_activeListeners * 2)) {
      updaters.removeWhere((listener) => listener == null);
    }
  }

  bool get isDisposed => _updaters == null;

  bool _debugAssertNotDisposed() {
    assert(() {
      if (isDisposed) {
        throw FlutterError(
          '''A $runtimeType was used after being disposed.\n
'Once you have called dispose() on a $runtimeType, it can no longer be used.''',
        );
      }
      return true;
    }());
    return true;
  }

  int get listenersLength {
    assert(_debugAssertNotDisposed());
    return _activeListeners;
  }

  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updaters = null;
    _activeListeners = 0;
    _notificationCallDepth = 0;
  }
}

mixin ListNotifierGroupMixin on Listenable {
  HashMap<Object?, ListNotifierSingleMixin>? _updatersGroupIds =
      HashMap<Object?, ListNotifierSingleMixin>();

  void _notifyGroupUpdate(Object id) {
    if (_updatersGroupIds!.containsKey(id)) {
      _updatersGroupIds![id]!._notifyUpdate();
    }
  }

  @protected
  void notifyGroupChildrens(Object id) {
    assert(_debugAssertNotDisposed());
    Notifier.instance.read(_updatersGroupIds![id]!);
  }

  bool containsId(Object id) {
    return _updatersGroupIds?.containsKey(id) ?? false;
  }

  @protected
  void refreshGroup(Object id) {
    assert(_debugAssertNotDisposed());
    _notifyGroupUpdate(id);
  }

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_updatersGroupIds == null) {
        throw FlutterError(
          '''A $runtimeType was used after being disposed.\n
'Once you have called dispose() on a $runtimeType, it can no longer be used.''',
        );
      }
      return true;
    }());
    return true;
  }

  void removeListenerId(Object id, VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    if (_updatersGroupIds!.containsKey(id)) {
      _updatersGroupIds![id]!.removeListener(listener);
    }
  }

  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updatersGroupIds?.forEach((key, value) => value.dispose());
    _updatersGroupIds = null;
  }

  Disposer addListenerId(Object? key, GetStateUpdate listener) {
    _updatersGroupIds![key] ??= ListNotifierSingle();
    return _updatersGroupIds![key]!.addListener(listener);
  }

  /// To dispose an [id] from future updates(), this ids are registered
  /// by `GetBuilder()` or similar, so is a way to unlink the state change with
  /// the Widget from the Controller.
  void disposeId(Object id) {
    _updatersGroupIds?[id]?.dispose();
    _updatersGroupIds!.remove(id);
  }
}

class Notifier {
  Notifier._();

  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();

  NotifyData? _notifyData;

  /// Whether we are currently inside a reactive `append()` call.
  /// Used by [bindStream] to assert it is called in the right context.
  bool get hasActiveContext => _notifyData != null;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  void read(ListNotifierSingleMixin updaters) {
    final data = _notifyData;
    final listener = data?.updater;
    // seenUpdaters.add() returns true only on the first encounter of this
    // updater in the current build — O(1) vs the previous O(n) containsListener
    // scan. Using the disposer returned by addListener also avoids allocating a
    // second redundant closure (previously: add(() => removeListener(…))).
    if (listener != null && data!.seenUpdaters.add(updaters)) {
      add(updaters.addListener(listener));
    }
  }

  T append<T>(NotifyData data, T Function() builder) {
    _notifyData = data;
    final result = builder();
    if (data.disposers.isEmpty && data.throwException) {
      throw const ObxError();
    }
    _notifyData = null;
    return result;
  }
}

class NotifyData {
  NotifyData({
    required this.updater,
    required this.disposers,
    this.throwException = true,
  });
  final GetStateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;

  /// Tracks which [ListNotifierSingleMixin] instances have already been
  /// registered during the current build so we can skip duplicates in O(1)
  /// instead of O(n) list scans.
  /// Uses identity equality to avoid calling hashCode/== on Rx objects, whose
  /// hashCode getter reads `value` and would trigger reportRead() recursively.
  final Set<ListNotifierSingleMixin> seenUpdaters = Set.identity();
}

class ObxError {
  const ObxError();
  @override
  String toString() {
    return """
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      """;
  }
}
