import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/services/api_client.dart';

class SpaceApiService extends GetxService {
  ApiClient get _client => Get.find<ApiClient>();

  Future<ApiResponse<void>> createTeamSpace({
    required String accessToken,
    required String name,
    required String logo,
  }) {
    return _client.postAuth<void>(
      'space/createTeamSpace',
      accessToken: accessToken,
      body: {
        'name': name,
        'logo': logo,
      },
    );
  }
}
