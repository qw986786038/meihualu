import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

extension _Empty on Object {
  bool _isEmpty() {
    final val = this;
    var result = false;
    if (val is Iterable) {
      result = val.isEmpty;
    } else if (val is String) {
      result = val.trim().isEmpty;
    } else if (val is Map) {
      result = val.isEmpty;
    }
    return result;
  }
}

mixin StateMixin<T> on ListNotifier {
  T? _value;
  GetStatus<T>? _status;

  void _fillInitialStatus() {
    _status = (_value == null || _value!._isEmpty())
        ? GetStatus<T>.loading()
        : GetStatus<T>.success(_value as T);
  }

  GetStatus<T> get status {
    reportRead();
    return _status ??= GetStatus.loading();
  }

  T get state => value;

  set status(GetStatus<T> newStatus) {
    if (newStatus == _status) return;
    _status = newStatus;
    if (newStatus is SuccessStatus<T>) {
      _value = newStatus.data;
    }
    refresh();
  }

  @protected
  T get value {
    reportRead();
    return _value as T;
  }

  @protected
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    refresh();
  }

  @protected
  void change(GetStatus<T> status) {
    // Compare against the backing field directly to avoid calling the getter,
    // which would invoke reportRead() unnecessarily in this write-only path.
    if (status != _status) {
      this.status = status;
    }
  }

  void setSuccess(T data) {
    change(GetStatus<T>.success(data));
  }

  void setError(Object error) {
    change(GetStatus<T>.error(error));
  }

  void setLoading() {
    change(GetStatus<T>.loading());
  }

  void setEmpty() {
    change(GetStatus<T>.empty());
  }

  void futurize(
    Future<T> Function() body, {
    T? initialData,
    String? errorMessage,
    bool useEmpty = true,
  }) {
    final compute = body;
    _value ??= initialData;
    status = GetStatus<T>.loading();
    compute().then(
      (newValue) {
        if ((newValue == null || newValue._isEmpty()) && useEmpty) {
          status = GetStatus<T>.empty();
        } else {
          status = GetStatus<T>.success(newValue);
        }
        // Do NOT call refresh() here — the status setter already calls it.
      },
      onError: (err) {
        status = GetStatus.error(
          err is Exception ? err : Exception(errorMessage ?? err.toString()),
        );
        // Do NOT call refresh() here — the status setter already calls it.
      },
    );
  }
}

class GetListenable<T> extends ListNotifierSingle implements RxInterface<T> {
  GetListenable(T val) : _value = val;

  StreamController<T>? _controller;

  // Elevated from a closure variable to a field so that close() can cancel
  // the listener bridge before the StreamController fires onCancel
  // asynchronously (which would happen after dispose() nullifies _updaters).
  Disposer? _streamDisposer;

  StreamController<T> get subject {
    if (_controller == null) {
      // Use onListen/onCancel so that _streamListener is only registered while
      // there are active subscribers. This avoids wasting CPU when no one is
      // listening and allows re-subscription after every unsubscribe cycle.
      _controller = StreamController<T>.broadcast(
        onListen: () {
          _streamDisposer = addListener(_streamListener);
        },
        onCancel: () {
          // Guard: onCancel can fire asynchronously (via microtask) after
          // close() has already called dispose(), which sets _updaters=null.
          // Calling the disposer at that point would crash with a null
          // dereference inside _updaters!.remove(). Skip if already disposed.
          if (!isDisposed) _streamDisposer?.call();
          _streamDisposer = null;
        },
      );
    }
    return _controller!;
  }

  void _streamListener() {
    _controller?.add(_value);
  }

  @override
  @mustCallSuper
  void close() {
    // Cancel the listener bridge first, while _updaters is still valid.
    // Do NOT rely on onCancel for this: it fires asynchronously and could
    // run after dispose() has already nullified _updaters.
    _streamDisposer?.call();
    _streamDisposer = null;
    _controller?.close();
    dispose();
  }

  Stream<T> get stream {
    return subject.stream;
  }

  T _value;

  @override
  T get value {
    reportRead();
    return _value;
  }

  void _notify() {
    refresh();
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    _notify();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  @override
  StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError ?? false,
  );

  @override
  String toString() => value.toString();
}

class Value<T> extends ListNotifier
    with StateMixin<T>
    implements ValueListenable<T?> {
  Value(T val) {
    _value = val;
    _fillInitialStatus();
  }

  @override
  T get value {
    reportRead();
    return _value as T;
  }

  @override
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    refresh();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  void update(T Function(T? value) fn) {
    value = fn(value);
  }

  @override
  String toString() => value.toString();

  dynamic toJson() => (value as dynamic)?.toJson();
}

/// GetNotifier has a native status and state implementation, with the
/// Get Lifecycle
abstract class GetNotifier<T> extends Value<T> with GetLifeCycleMixin {
  GetNotifier(super.initial);
}

extension StateExt<T> on StateMixin<T> {
  Widget obx(
    NotifierBuilder<T> widget, {
    Widget Function(String? error)? onError,
    Widget? onLoading,
    Widget? onEmpty,
    WidgetBuilder? onCustom,
  }) {
    return Observer(
      builder: (context) {
        if (status.isLoading) {
          return onLoading ?? const Center(child: CircularProgressIndicator());
        } else if (status.isError) {
          return onError != null
              ? onError(status.errorMessage)
              : Center(child: Text('A error occurred: ${status.errorMessage}'));
        } else if (status.isEmpty) {
          return onEmpty ??
              const SizedBox.shrink(); // Also can be widget(null); but is risky
        } else if (status.isSuccess) {
          return widget(value);
        } else if (status.isCustom) {
          return onCustom?.call(context) ??
              const SizedBox.shrink(); // Also can be widget(null); but is risky
        }
        return widget(value);
      },
    );
  }
}
