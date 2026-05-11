import 'dart:async';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

/// Metadata about a registered dependency.
class InstanceInfo {
  final bool? isPermanent;
  final bool? isSingleton;
  bool get isFactory => isSingleton == false;
  final bool isRegistered;
  final bool isPrepared;
  final bool? isInit;
  const InstanceInfo({
    required this.isPermanent,
    required this.isSingleton,
    required this.isRegistered,
    required this.isPrepared,
    required this.isInit,
  });

  @override
  String toString() {
    return 'InstanceInfo(isPermanent: $isPermanent, isSingleton: $isSingleton, '
        'isRegistered: $isRegistered, isPrepared: $isPrepared, isInit: $isInit)';
  }
}

extension ResetInstance on GetInterface {
  /// Clears all registered instances (and/or tags).
  /// Even the persistent ones.
  /// This should be used at the end or tearDown of unit tests.
  bool resetInstance({bool clearRouteBindings = true}) {
    Inst._singl.clear();
    if (!clearRouteBindings) {
      Get.log(
        'resetInstance: clearRouteBindings=false is ignored; getx_plus has '
        'no separate route-binding store — the full DI map was cleared.',
      );
    }
    return true;
  }
}

extension Inst on GetInterface {
  T call<T>() => find<T>();

  /// Holds references to every registered Instance when using
  /// `Get.put()`
  static final Map<String, _InstanceBuilderFactory> _singl = {};

  S put<S>(S dependency, {String? tag, bool permanent = false}) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: (() => dependency),
    );
    return find<S>(tag: tag);
  }

  /// Registers [S] asynchronously. Awaits [builder], then inserts the resolved
  /// instance as a singleton — exactly like [put], but for async initialization.
  ///
  /// ```dart
  /// // In a Binding or onInit:
  /// await Get.putAsync<DatabaseService>(() async {
  ///   final db = DatabaseService();
  ///   await db.init();
  ///   return db;
  /// });
  /// ```
  ///
  /// - [permanent] keeps the instance alive even when [SmartManagement] would
  ///   normally remove it (e.g. on route pop).
  /// - Subsequent calls with the same [S] + [tag] are silently ignored once the
  ///   instance is already registered.
  Future<S> putAsync<S>(
    AsyncInstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = false,
  }) async {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }
    final S instance = await builder();
    if (isRegistered<S>(tag: tag)) {
      if (instance is GetLifeCycleMixin) {
        (instance as GetLifeCycleMixin).onDelete();
      }
      return find<S>(tag: tag);
    }
    return put<S>(instance, tag: tag, permanent: permanent);
  }

  /// Registers [S] lazily — the instance is only created on first [find].
  ///
  /// When [fenix] is true (or when [SmartManagement.keepFactory] is active),
  /// the builder is kept in memory so the instance can be recreated after
  /// deletion. Suitable for per-route controllers.
  ///
  /// Subsequent calls with the same type and tag are ignored.
  void lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool? fenix,
    bool permanent = false,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: builder,
      fenix: fenix ?? Get.smartManagement == SmartManagement.keepFactory,
    );
  }

  /// Registers a **factory** for [S]: each [find] call creates a fresh instance.
  ///
  /// Unlike [put]/[lazyPut], factory instances are NOT singletons.
  /// Each [Get.find<S>()] returns a brand-new object.
  ///
  /// ```dart
  /// Get.create(() => ApiClient());
  /// final c1 = Get.find<ApiClient>(); // new instance
  /// final c2 = Get.find<ApiClient>(); // another new instance
  /// print(c1 == c2); // false
  /// ```
  void create<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    _insert(
      isSingleton: false,
      name: tag,
      builder: builder,
      permanent: permanent,
    );
  }

  /// Backward-compatible alias for [create].
  @Deprecated('Use Get.create() instead.')
  void spawn<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    create<S>(builder, tag: tag, permanent: permanent);
  }

  /// Injects the Instance [S] builder into the `_singleton` HashMap.
  void _insert<S>({
    required bool isSingleton,
    String? name,
    bool permanent = false,
    required InstanceBuilderCallback<S> builder,
    bool fenix = false,
  }) {
    final key = _getKey(S, name);

    _InstanceBuilderFactory<S>? dep;
    if (_singl.containsKey(key)) {
      final newDep = _singl[key];
      if (newDep == null || !newDep.isDirty) {
        return;
      } else {
        dep = newDep as _InstanceBuilderFactory<S>;
      }
    }
    _singl[key] = _InstanceBuilderFactory<S>(
      isSingleton: isSingleton,
      builderFunc: builder,
      permanent: permanent,
      isInit: false,
      fenix: fenix,
      tag: name,
      lateRemove: dep,
    );
  }

  /// Initializes the dependencies for a Class Instance [S] (or tag),
  /// If its a Controller, it starts the lifecycle process.
  /// Only flags `isInit` if it's using `Get.create()` (not for singleton
  /// access). Returns the instance if not initialized, required for
  /// [Get.create] to work properly.
  S? _initDependencies<S>({String? name}) {
    final key = _getKey(S, name);
    final isInit = _singl[key]!.isInit;
    S? i;
    if (!isInit) {
      final isSingleton = _singl[key]?.isSingleton ?? false;
      if (isSingleton) {
        _singl[key]!.isInit = true;
      }
      i = _startController<S>(tag: name);
    }
    return i;
  }

  InstanceInfo getInstanceInfo<S>({String? tag}) {
    final build = _getDependency<S>(tag: tag);

    return InstanceInfo(
      isPermanent: build?.permanent,
      isSingleton: build?.isSingleton,
      isRegistered: isRegistered<S>(tag: tag),
      isPrepared: !(build?.isInit ?? true),
      isInit: build?.isInit,
    );
  }

  _InstanceBuilderFactory? _getDependency<S>({String? tag, String? key}) {
    final newKey = key ?? _getKey(S, tag);

    if (!_singl.containsKey(newKey)) {
      Get.log('Instance "$newKey" is not registered.', isError: true);
      return null;
    } else {
      return _singl[newKey];
    }
  }

  void markAsDirty<S>({String? tag, String? key}) {
    final newKey = key ?? _getKey(S, tag);
    if (_singl.containsKey(newKey)) {
      final dep = _singl[newKey];
      if (dep != null && !dep.permanent) {
        dep.isDirty = true;
      }
    }
  }

  /// Initializes the controller
  S _startController<S>({String? tag}) {
    final key = _getKey(S, tag);
    final i = _singl[key]!.getDependency() as S;
    if (i is GetLifeCycleMixin) {
      i.onStart();
      if (tag == null) {
        Get.log('Instance "$S" has been initialized');
      } else {
        Get.log('Instance "$S" with tag "$tag" has been initialized');
      }
    }
    return i;
  }

  S putOrFind<S>(InstanceBuilderCallback<S> dep, {String? tag}) {
    final key = _getKey(S, tag);

    if (_singl.containsKey(key)) {
      return _singl[key]!.getDependency() as S;
    } else {
      return put(dep(), tag: tag);
    }
  }

  /// Finds the registered type <[S]> (or [tag])
  /// In case of using Get.[create] to register a type <[S]> or [tag],
  /// it will create an instance each time you call [find].
  /// If the registered type <[S]> (or [tag]) is a Controller,
  /// it will initialize it's lifecycle.
  S find<S>({String? tag}) {
    final key = _getKey(S, tag);
    if (isRegistered<S>(tag: tag)) {
      final dep = _singl[key];
      if (dep == null) {
        if (tag == null) {
          throw GetDependencyNotFound('Class "$S" is not registered');
        } else {
          throw GetDependencyNotFound(
            'Class "$S" with tag "$tag" is not registered',
          );
        }
      }

      /// although dirty solution, the lifecycle starts inside
      /// `initDependencies`, so we have to return the instance from there
      /// to make it compatible with `Get.create()`.
      final i = _initDependencies<S>(name: tag);
      return i ?? dep.getDependency() as S;
    } else {
      throw GetDependencyNotFound(
        '"$S" not found. You need to call "Get.put($S())" or '
        '"Get.lazyPut(()=>$S())"',
      );
    }
  }

  /// Returns the instance of [S] if registered, otherwise `null`.
  /// A null-safe alternative to [find].
  S? tryFind<S>({String? tag}) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }
    return null;
  }

  /// Backward-compatible alias for [tryFind].
  S? findOrNull<S>({String? tag}) => tryFind<S>(tag: tag);

  /// Replace a parent instance of a class in dependency management
  /// with a [child] instance
  /// - [tag] optional, if you use a [tag] to register the Instance.
  void replace<P>(P child, {String? tag}) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    put(child, tag: tag, permanent: permanent);
  }

  /// Replaces a parent instance with a new Instance<P> lazily from the
  /// `<P>builder()` callback.
  /// - [tag] optional, if you use a [tag] to register the Instance.
  /// - [fenix] optional
  ///
  ///  Note: if fenix is not provided it will be set to true if
  /// the parent instance was permanent
  void lazyReplace<P>(
    InstanceBuilderCallback<P> builder, {
    String? tag,
    bool? fenix,
  }) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    lazyPut(builder, tag: tag, fenix: fenix ?? permanent);
  }

  /// Generates the key based on [type] (and optionally a [name])
  /// to register an Instance Builder in the hashmap.
  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }

  /// Delete registered Class Instance [S] (or [tag]) and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// /// Deletes the Instance<[S]>, cleaning the memory.
  //  ///
  //  /// - [tag] Optional "tag" used to register the Instance
  //  /// - [key] For internal usage, is the processed key used to register
  //  ///   the Instance. **don't use** it unless you know what you are doing.

  /// Deletes the Instance<[S]>, cleaning the memory and closes any open
  /// controllers (`DisposableInterface`).
  ///
  /// - [tag] Optional "tag" used to register the Instance
  /// - [key] For internal usage, is the processed key used to register
  ///   the Instance. **don't use** it unless you know what you are doing.
  /// - [force] Will delete an Instance even if marked as `permanent`.
  bool delete<S>({String? tag, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, tag);

    if (!_singl.containsKey(newKey)) {
      Get.log('Instance "$newKey" already removed.', isError: true);
      return false;
    }

    final dep = _singl[newKey];

    if (dep == null) return false;

    final _InstanceBuilderFactory builder;
    if (dep.isDirty) {
      builder = dep.lateRemove ?? dep;
    } else {
      builder = dep;
    }

    if (builder.permanent && !force) {
      Get.log(
        // ignore: lines_longer_than_80_chars
        '"$newKey" has been marked as permanent, SmartManagement is not authorized to delete it.',
        isError: true,
      );
      return false;
    }
    final i = builder.dependency;

    if (i is GetxServiceMixin && !force) {
      return false;
    }

    if (i is GetLifeCycleMixin) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }

    if (builder.fenix) {
      builder.dependency = null;
      builder.isInit = false;
      return true;
    } else {
      if (dep.lateRemove != null) {
        dep.lateRemove = null;
        Get.log('"$newKey" deleted from memory');
        return false;
      } else {
        _singl.remove(newKey);
        if (_singl.containsKey(newKey)) {
          Get.log('Error removing object "$newKey"', isError: true);
        } else {
          Get.log('"$newKey" deleted from memory');
        }
        return true;
      }
    }
  }

  /// Delete all registered Class Instances and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// - [force] Will delete the Instances even if marked as `permanent`.
  void deleteAll({bool force = false}) {
    final keys = _singl.keys.toList();
    for (final key in keys) {
      delete(key: key, force: force);
    }
  }

  void reloadAll({bool force = false}) {
    _singl.forEach((key, value) {
      if (value.permanent && !force) {
        Get.log('Instance "$key" is permanent. Skipping reload');
      } else {
        value.dependency = null;
        value.isInit = false;
        Get.log('Instance "$key" was reloaded.');
      }
    });
  }

  void reload<S>({String? tag, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, tag);

    final builder = _getDependency<S>(tag: tag, key: newKey);
    if (builder == null) return;

    if (builder.permanent && !force) {
      Get.log(
        '''Instance "$newKey" is permanent. Use [force = true] to force the restart.''',
        isError: true,
      );
      return;
    }

    final i = builder.dependency;

    if (i is GetxServiceMixin && !force) {
      return;
    }

    if (i is GetLifeCycleMixin) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }

    builder.dependency = null;
    builder.isInit = false;
    Get.log('Instance "$newKey" was restarted.');
  }

  /// Check if a Class Instance<[S]> (or [tag]) is registered in memory.
  /// - [tag] is optional, if you used a [tag] to register the Instance.
  bool isRegistered<S>({String? tag}) => _singl.containsKey(_getKey(S, tag));

  /// Checks if a lazy factory callback `Get.lazyPut()` that returns an
  /// Instance<[S]> is registered in memory.
  /// - [tag] is optional, if you used a [tag] to register the lazy Instance.
  bool isPrepared<S>({String? tag}) {
    final newKey = _getKey(S, tag);

    final builder = _getDependency<S>(tag: tag, key: newKey);
    if (builder == null) {
      return false;
    }

    if (!builder.isInit) {
      return true;
    }
    return false;
  }

  /// Executes a [Binding] immediately.
  ///
  /// Useful when wiring dependencies with plain Flutter navigation or during
  /// app startup.
  void runBinding(Binding binding) {
    binding.dependencies();
  }

  /// Executes multiple bindings in order.
  void runBindings(Iterable<Binding> bindings) {
    for (final binding in bindings) {
      binding.dependencies();
    }
  }
}

typedef InstanceBuilderCallback<S> = S Function();

typedef InstanceCreateBuilderCallback<S> = S Function(BuildContext _);

// typedef InstanceBuilderCallback<S> = S Function();

// typedef InjectorBuilderCallback<S> = S Function(Inst);

typedef AsyncInstanceBuilderCallback<S> = Future<S> Function();

/// Internal class to register instances with `Get.put<S>()`.
class _InstanceBuilderFactory<S> {
  /// Marks the Builder as a single instance.
  /// For reusing [dependency] instead of [builderFunc]
  bool isSingleton;

  /// When fenix mode is available, when a new instance is need
  /// Instance manager will recreate a new instance of S
  bool fenix;

  /// Stores the actual object instance when [isSingleton]=true.
  S? dependency;

  /// Generates (and regenerates) the instance when [isSingleton]=false.
  /// Usually used by factory methods
  InstanceBuilderCallback<S> builderFunc;

  /// Flag to persist the instance in memory,
  /// without considering `Get.smartManagement`
  bool permanent = false;

  bool isInit = false;

  _InstanceBuilderFactory<S>? lateRemove;

  bool isDirty = false;

  String? tag;

  _InstanceBuilderFactory({
    required bool isSingleton,
    required this.builderFunc,
    required this.permanent,
    required this.isInit,
    required this.fenix,
    required this.tag,
    required this.lateRemove,
  }) : isSingleton = isSingleton;

  void _showInitLog() {
    if (tag == null) {
      Get.log('Instance "$S" has been created');
    } else {
      Get.log('Instance "$S" has been created with tag "$tag"');
    }
  }

  /// Gets the actual instance by it's [builderFunc] or the persisted instance.
  S getDependency() {
    if (isSingleton) {
      if (dependency == null) {
        _showInitLog();
        dependency = builderFunc();
      }
      return dependency!;
    } else {
      return builderFunc();
    }
  }
}
