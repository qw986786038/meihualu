import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/create_and_pay_result.dart';
import 'package:watermark_camera/models/api/vip_plan.dart';
import 'package:watermark_camera/services/api_client.dart';

class OrderApiService extends GetxService {
  ApiClient get _client => Get.find<ApiClient>();

  /// 套餐类型：0 个人，1 团队。
  Future<ApiResponse<List<VipPlan>>> listPlans({
    required String accessToken,
    required String planType,
  }) {
    return _client.postAuth(
      'app/order/list',
      accessToken: accessToken,
      body: {'planType': planType},
      dataFromListJson: (list) {
        final plans = list
            .whereType<Map>()
            .map((item) => VipPlan.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        plans.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return plans;
      },
    );
  }

  Future<ApiResponse<CreateAndPayResult>> createAndPay({
    required String accessToken,
    required String planId,
    required String channel,
    required String tradeType,
    String returnUrl = '',
    String orderType = '0',
  }) {
    return _client.postAuth(
      'pay/createAndPay',
      accessToken: accessToken,
      body: {
        'planId': planId,
        'orderType': orderType,
        'channel': channel,
        'tradeType': tradeType,
        'returnUrl': returnUrl,
      },
      dataFromJson: CreateAndPayResult.fromJson,
    );
  }
}
