# Getx Plus

## 5.2.0

- 优化状态管理性能：减少高频通知路径中的临时分配，降低 `GetBuilder` 同帧重复重建。
- 文档更新：README 全面同步为“状态管理 + 依赖注入 + 原生 Navigator”模式。

## 5.1.2

- **Breaking**: 完全移除内置路由导航模块，仅保留状态管理与依赖注入。
- 新增 `Get.runBinding()` / `Get.runBindings()`，用于在纯 Flutter `MaterialApp` / `Navigator` 架构下执行依赖注册。
- 示例工程切换为 Flutter 原生导航。

## 5.1.1

- ** Fix Bugs

## 5.1.0

- ** Fix Bugs

## 5.0.3

- ** Fix Bugs

## 5.0.1

- **修复了在使用home参数时无法正确解析路由参数的问题**：之前版本中，如果在 `GetMaterialApp` 中使用了 `home` 参数，路由参数无法正确解析。现在已修复该问题，确保无论是使用 `home` 还是 `initialRoute`，路由参数都能正确工作。

## 5.0.0

### 重大变更 (Breaking Changes)

本版本对原始 GetX 进行了大规模精简，移除了多个非核心模块，仅保留**状态管理、依赖注入、路由导航**三大核心能力。

#### 已删除的模块与功能

- **GetConnect（HTTP 客户端 & WebSocket）**：整个 `get_connect` 模块已移除，包括 `GetConnect`、`GetHttpClient`、`GetSocket`、`GraphQLMixin` 等。请使用 `dio`、`http` 等社区包替代。
- **国际化系统（i18n）**：移除 `Translations` 基类、`.tr` / `.trArgs` / `.trPlural` 扩展、`Get.locale`、`Get.fallbackLocale`、`Get.updateLocale`、`Get.translations` 等全部自定义国际化 API。请使用 Flutter 原生 `Localizations` 或 `intl` 包替代。
- **GetUtils / 扩展工具集**：移除 `get_utils` 模块，包括字符串校验（`isEmail`、`isPhoneNumber`、`isCpf` 等）、`num` 延时扩展（`delay()`）、`Widget` padding/margin 扩展（`paddingAll`、`marginOnly` 等）、上下文扩展等。
- **动画模块（GetAnimations）**：移除 `get_animations` 模块，包括 `OpacityTransition`、`FadeInTransition` 等预封装动画组件。
- **GetCommon**：移除 `get_common` 模块（`GetReset` 等）。
- **go_router 依赖**：移除对 `go_router` 的依赖。
- **冗余的 Binding 基类**：合并 `Binding` 与 `Bindings`，仅保留 `Bindings` 接口。

#### 改进与修复

- **路由参数自动同步**：`onGenerateRoute` 提取的路径参数和查询参数现在会自动同步到 `Get.parameters`，初始路由的参数也能正确读取。
- **中间件系统**：`GetMiddleware` 的 `redirect` 和 `onPageCalled` 在 Navigator 2.0 下正常工作。
- **嵌套路由**：`GetPage.children` 会被自动展开为扁平路由表，子路由名称自动拼接父路径。
- **路由转场**：保留全部 16 种内置转场动画。
- **控制器生命周期**：`GetxController`、`GetxService`、`RxController` 生命周期管理不变。
- **响应式组件**：`GetResponsiveView` / `GetResponsiveWidget` 保留。
- **依赖项**：移除 `go_router`，仅依赖 Flutter SDK + `web` 包。
- **Dart / Flutter 版本**：要求 Dart `^3.10.0`、Flutter `^3.38.1`。

---
