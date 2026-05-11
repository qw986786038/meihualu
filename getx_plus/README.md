# GetX Plus

轻量、可维护的 GetX 分支，当前只保留两件事：

- 状态管理（Rx / Obx / GetBuilder）
- 依赖注入（Get.put / Get.lazyPut / Get.find）

内置导航模块已移除，请使用 Flutter 原生 `MaterialApp` / `Navigator`。

## 版本

当前文档对应版本：`5.2.0`

## 安装

```yaml
dependencies:
  getx_plus: ^5.2.0
```

```dart
import 'package:getx_plus/getx_plus.dart';
```

环境要求：

- Dart `^3.10.0`
- Flutter `>=3.38.1`

## 核心能力

### 1) 响应式状态管理

```dart
final count = 0.obs;
final name = ''.obs;
final items = <String>[].obs;
```

```dart
Obx(() => Text('count: ${count.value}'));
```

支持组件：

- `Obx`
- `ObxValue`
- `GetX<T>`
- `GetBuilder<T>`
- `MixinBuilder<T>`

### 2) 依赖注入

```dart
// register
Get.put(AuthService());
Get.lazyPut(() => UserRepo());
Get.create(() => TempController());

// find
final auth = Get.find<AuthService>();
final repo = Get<UserRepo>();
```

生命周期/清理：

```dart
Get.delete<AuthService>();
Get.deleteAll();
Get.resetInstance(); // 通常用于测试
```

## Binding 用法（非路由）

`Binding` 现在是纯依赖注册契约，可在原生 Navigator 架构下手动执行。

```dart
class HomeBinding extends Binding {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => UserRepository());
  }
}

void main() {
  Get.runBinding(HomeBinding());
  runApp(const MyApp());
}
```

批量执行：

```dart
Get.runBindings([SplashBinding(), MainBinding()]);
```

## 快速示例（原生 Navigator）

```dart
import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

void main() {
  Get.put(CounterController());
  runApp(const MyApp());
}

class CounterController extends GetxController {
  final count = 0.obs;
  void inc() => count.value++;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GetX Plus')),
        body: Center(
          child: Obx(() => Text('count: ${Get.find<CounterController>().count.value}')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: Get.find<CounterController>().inc,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## 迁移提示

如果你从旧版本迁移，请注意：

- 移除 `GetMaterialApp` / `GetPage` / `Get.to()` / `Get.back()` 等导航 API
- 改用 Flutter 原生导航
- 保留并继续使用状态管理与 DI API

## 示例工程

`example/` 已切换为原生 `MaterialApp + Navigator`，包含：

- 状态管理示例页面
- DI + Binding 示例
- 性能测试页面（含动态 ListView 压测）

## License

MIT
