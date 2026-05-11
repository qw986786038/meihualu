import 'package:getx_plus/getx_plus.dart';

class HomeLogic extends GetxController {
  final articles = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadArticles();
  }

  void _loadArticles() {
    articles.addAll([
      'Flutter 状态管理最佳实践',
      'GetX 路由导航指南',
      'Dart 异步编程详解',
      '响应式编程入门',
      'Widget 生命周期管理',
    ]);
  }

  void shuffleArticles() {
    articles.shuffle();
  }
}
