/// Dependency registration contract.
///
/// Extend this class and override [dependencies] to register the
/// dependencies needed by a feature or screen. Call [Get.lazyPut], [Get.put], or
/// [Get.create] inside the method body:
///
/// ```dart
/// class HomeBinding extends Binding {
///   @override
///   void dependencies() {
///     Get.lazyPut(() => HomeController());
///     Get.lazyPut(() => UserRepository());
///   }
/// }
/// ```
///
/// Run it manually with [Get.runBinding]:
/// ```dart
/// Get.runBinding(HomeBinding());
/// ```
abstract class Binding {
  void dependencies();
}
