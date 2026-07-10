import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/space_batch_upload_data.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/utils/space_upload_helper.dart';

class SpaceMediaService extends GetxService {
  Future<SpaceBatchUploadData?> batchUploadMedia({
    required String spaceId,
    required String accessToken,
    required List<String> filePaths,
    List<DateTime>? captureTimes,
  }) async {
    if (spaceId.isEmpty || accessToken.isEmpty || filePaths.isEmpty) {
      return null;
    }

    try {
      final coordinates = Get.isRegistered<AMapLocationService>()
          ? Get.find<AMapLocationService>().currentCoordinateFields()
          : (latitude: '', longitude: '');

      final items = <SpaceBatchUploadItem>[];
      for (var i = 0; i < filePaths.length; i++) {
        final payload = await SpaceUploadHelper.buildForManualUpload(
          filePath: filePaths[i],
          captureTime: captureTimes != null && i < captureTimes.length
              ? captureTimes[i]
              : null,
        );
        items.add(
          SpaceBatchUploadItem(
            filePath: filePaths[i],
            sha256Hash: payload.sha256HashForSpace(spaceId),
            exifData: payload.exifData,
            watermarkId: payload.watermarkId,
            watermarkContent: payload.watermarkContent,
          ),
        );
      }

      final response = await Get.find<SpaceApiService>().batchUploadToSpace(
        accessToken: accessToken,
        spaceId: spaceId,
        items: items,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );
      if (!response.isSuccess || response.data == null) return null;
      return response.data;
    } catch (_) {
      return null;
    }
  }
}
