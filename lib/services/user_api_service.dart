import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/login_data.dart';
import 'package:watermark_camera/models/api/user_info.dart';
import 'package:watermark_camera/services/api_client.dart';

class UserApiService extends GetxService {
  ApiClient get _client => Get.find<ApiClient>();

  Future<ApiResponse<LoginData>> loginByPassword({
    required String phone,
    required String password,
  }) {
    return _client.post(
      'user/loginByPassword',
      body: {
        'clientId': ApiConfig.clientId,
        'grantType': ApiConfig.grantTypePassword,
        'phone': phone,
        'password': password,
      },
      dataFromJson: LoginData.fromJson,
    );
  }

  Future<ApiResponse<LoginData>> loginBySmsCode({
    required String phone,
    required String smsCode,
  }) {
    return _client.post(
      'user/loginBySmsCode',
      body: {
        'clientId': ApiConfig.clientId,
        'grantType': ApiConfig.grantTypeSms,
        'phone': phone,
        'smsCode': smsCode,
      },
      dataFromJson: LoginData.fromJson,
    );
  }

  Future<ApiResponse<LoginData>> loginByWechat({
    required String code,
  }) {
    return _client.post(
      'user/loginByWechat',
      body: {
        'code': code,
        'clientId': ApiConfig.clientId,
      },
      dataFromJson: LoginData.fromJson,
    );
  }

  Future<ApiResponse<LoginData>> bindPhoneByWechat({
    required String bindToken,
    required String phone,
    required String smsCode,
  }) {
    return _client.post(
      'user/bindPhoneByWechat',
      body: {
        'bindToken': bindToken,
        'phone': phone,
        'clientId': ApiConfig.clientId,
        'smsCode': smsCode,
      },
      dataFromJson: LoginData.fromJson,
    );
  }

  Future<ApiResponse<void>> sendSmsCode({required String phone}) {
    return _client.post<void>(
      'sms/sendCode',
      body: {'phone': phone},
    );
  }

  Future<ApiResponse<void>> updatePassword({
    required String phone,
    required String smsCode,
    required String password,
  }) {
    return _client.post<void>(
      'user/updatePassword',
      body: {
        'phone': phone,
        'smsCode': smsCode,
        'password': password,
      },
    );
  }

  Future<ApiResponse<UserInfo>> getUserInfo({required String accessToken}) {
    return _client.postAuth(
      'user/getUserInfo',
      accessToken: accessToken,
      dataFromJson: UserInfo.fromJson,
    );
  }

  Future<ApiResponse<int>> updateUserInfo({
    required String accessToken,
    required String userName,
    required String nickName,
    required String sex,
    required String email,
    required String avatarUrl,
  }) {
    return _client.postAuth<int>(
      'user/updateUserInfo',
      accessToken: accessToken,
      body: {
        'userName': userName,
        'nickName': nickName,
        'sex': sex,
        'email': email,
        'avatarUrl': avatarUrl,
      },
    );
  }
}
