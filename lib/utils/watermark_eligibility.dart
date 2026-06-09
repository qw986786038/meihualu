import 'package:photo_manager/photo_manager.dart';

/// 本应用保存水印媒体的相册名称。
const String kWatermarkCameraAlbumName = '水印相机';

/// 判断媒体是否支持 AI 去水印。
class WatermarkEligibility {
  const WatermarkEligibility._();

  /// 仅本应用「水印相机」相册中的媒体可编辑水印。
  static bool isEditable({
    required AssetEntity asset,
    required Set<String> watermarkAlbumAssetIds,
  }) {
    if (asset.type != AssetType.image && asset.type != AssetType.video) {
      return false;
    }
    return watermarkAlbumAssetIds.contains(asset.id);
  }

  /// 与 [isEditable] 相同：仅「水印相机」相册内媒体可去水印。
  static bool isRemovable({
    required AssetEntity asset,
    required Set<String> watermarkAlbumAssetIds,
  }) {
    return isEditable(
      asset: asset,
      watermarkAlbumAssetIds: watermarkAlbumAssetIds,
    );
  }

  static Future<AssetPathEntity?> findWatermarkAlbum() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    for (final album in albums) {
      if (album.name == kWatermarkCameraAlbumName) {
        return album;
      }
    }
    return null;
  }

  static Future<Set<String>> loadWatermarkAlbumAssetIds() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) return {};

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    AssetPathEntity? watermarkAlbum;
    for (final album in albums) {
      if (album.name == kWatermarkCameraAlbumName) {
        watermarkAlbum = album;
        break;
      }
    }
    if (watermarkAlbum == null) return {};

    final ids = <String>{};
    var start = 0;
    const pageSize = 200;
    while (true) {
      final total = await watermarkAlbum.assetCountAsync;
      if (start >= total) break;
      final end = (start + pageSize).clamp(0, total);
      final batch = await watermarkAlbum.getAssetListRange(start: start, end: end);
      if (batch.isEmpty) break;
      for (final asset in batch) {
        ids.add(asset.id);
      }
      start += batch.length;
      if (batch.length < pageSize) break;
    }
    return ids;
  }
}
