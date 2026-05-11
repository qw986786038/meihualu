import 'get_interface.dart';

/// The central `Get` singleton — your one-stop-shop for:
/// - **Dependency Injection**: `Get.put()`, `Get.lazyPut()`, `Get.find()`
/// - **Reactive state**: use `Rx` types + `Obx()` / `GetBuilder<T>`
///
/// No boilerplate for registering or looking up shared objects.
///
/// ```dart
/// Get.put(AuthService());
/// Get.find<AuthService>().login();
/// ```
final Get = GetInterface();
