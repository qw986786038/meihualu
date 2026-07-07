import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/services/api_client.dart';

class FileApiService extends GetxService {
  ApiClient get _client => Get.find<ApiClient>();

  Future<ApiResponse<String>> uploadImage({
    required String accessToken,
    required String filePath,
  }) {
    return _client.uploadAuth(
      path: ApiConfig.uploadPath,
      accessToken: accessToken,
      filePath: filePath,
    );
  }
}
