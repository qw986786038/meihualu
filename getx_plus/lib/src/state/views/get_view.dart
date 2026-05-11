import 'package:flutter/widgets.dart';
import 'package:getx_plus/getx_plus.dart';

/// A convenient base for views that need a single [GetController].
///
/// The [controller] is resolved from the DI container via [Get.find].
/// Extend this class and implement [build]:
///
/// ```dart
/// class HomePage extends GetView<HomeController> {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Obx(() => Text('${controller.count}')),
///       floatingActionButton: FloatingActionButton(
///         onPressed: controller.increment,
///       ),
///     );
///   }
/// }
/// ```
abstract class GetView<T> extends StatelessWidget {
  const GetView({super.key});

  final String? tag = null;

  T get controller => Get.find<T>(tag: tag);

  @override
  Widget build(BuildContext context);
}
