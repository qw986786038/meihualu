import 'package:getx_plus/getx_plus.dart';
import 'package:tobias/tobias.dart';

enum AlipayPayStatus { success, cancelled, failed, notInstalled }

class AlipayPayResult {
  const AlipayPayResult({
    required this.status,
    this.message = '',
  });

  final AlipayPayStatus status;
  final String message;

  bool get isSuccess => status == AlipayPayStatus.success;
}

class AlipayService extends GetxService {
  final Tobias _tobias = Tobias();

  /// 当前使用沙箱；上线改为 [AliPayEvn.online]。
  static const AliPayEvn _payEnv = AliPayEvn.sandbox;

  Future<bool> isInstalled() async {
    try {
      return await _tobias.isAliPayInstalled;
    } catch (_) {
      return false;
    }
  }

  /// 使用 /pay/createAndPay 返回的 [payPayload] 唤起支付宝（沙箱）。
  Future<AlipayPayResult> pay(String payPayload) async {
    // 接口可能把订单串拆成多行日志，去掉空白换行后再唤起。
    final orderInfo = payPayload.replaceAll(RegExp(r'\s+'), '').trim();
    if (orderInfo.isEmpty) {
      return const AlipayPayResult(
        status: AlipayPayStatus.failed,
        message: '支付参数为空',
      );
    }

    try {
      final appId = _parseAppId(orderInfo);
      if (appId != null && appId.isNotEmpty) {
        try {
          await _tobias.registerApp(appId);
        } catch (_) {
          // registerApp 非强制，失败不影响支付。
        }
      }

      // 沙箱需安装「支付宝沙箱版」；正式环境再校验正式客户端。
      if (_payEnv == AliPayEvn.online) {
        final installed = await isInstalled();
        if (!installed) {
          return const AlipayPayResult(
            status: AlipayPayStatus.notInstalled,
            message: '未安装支付宝',
          );
        }
      }

      final raw = await _tobias.pay(
        orderInfo,
        evn: _payEnv,
        showPayLoading: true,
      );
      final resultStatus = raw['resultStatus']?.toString() ?? '';
      final memo = raw['memo']?.toString() ?? '';

      if (resultStatus == '9000') {
        return const AlipayPayResult(status: AlipayPayStatus.success);
      }
      if (resultStatus == '6001') {
        return AlipayPayResult(
          status: AlipayPayStatus.cancelled,
          message: memo.isEmpty ? '已取消支付' : memo,
        );
      }
      return AlipayPayResult(
        status: AlipayPayStatus.failed,
        message: memo.isEmpty ? '支付失败($resultStatus)' : memo,
      );
    } catch (error) {
      return AlipayPayResult(
        status: AlipayPayStatus.failed,
        message: error.toString(),
      );
    }
  }

  String? _parseAppId(String orderInfo) {
    final match = RegExp(r'app_id=([^&]+)').firstMatch(orderInfo);
    if (match == null) return null;
    return Uri.decodeQueryComponent(match.group(1)!);
  }
}
