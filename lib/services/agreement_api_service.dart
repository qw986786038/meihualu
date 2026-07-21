import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/agreement_data.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/services/api_client.dart';

class AgreementApiService extends GetxService {
  ApiClient get _client => Get.find<ApiClient>();

  Future<ApiResponse<AgreementData>> getAgreement(String type) {
    final normalized = type.trim().toLowerCase();
    return _client.get(
      'agreement/$normalized',
      dataFromJson: AgreementData.fromJson,
    );
  }

  Future<ApiResponse<AgreementData>> getServiceAgreement() {
    return getAgreement(AgreementType.service);
  }

  Future<ApiResponse<AgreementData>> getPrivacyPolicy() {
    return getAgreement(AgreementType.privacy);
  }
}
