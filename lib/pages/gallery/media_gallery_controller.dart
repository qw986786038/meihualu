import 'dart:async' show unawaited;

import 'package:getx_plus/getx_plus.dart';
import 'package:photo_manager/photo_manager.dart';

enum MediaGalleryFeature {
  editWatermark,
  aiRemoveWatermark,
  collageReport,
  batchAddWatermark,
  batchRemoveWatermark,
  batchEditWatermark,
}

class MediaDateGroup {
  const MediaDateGroup({
    required this.title,
    required this.assets,
  });

  final String title;
  final List<AssetEntity> assets;
}

class MediaGalleryController extends GetxController {
  final RxList<AssetEntity> assets = <AssetEntity>[].obs;
  final RxBool isLoading = true.obs;
  final RxSet<String> selectedIds = <String>{}.obs;
  final Rxn<String> permissionMessage = Rxn<String>();
  final Rxn<MediaGalleryFeature> activeFeature = Rxn<MediaGalleryFeature>();

  AssetPathEntity? _album;
  int _loadedCount = 0;
  static const int _pageSize = 60;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<MediaDateGroup> get groupedAssets {
    final map = <String, List<AssetEntity>>{};
    for (final asset in assets) {
      final key = _formatDateGroup(asset.createDateTime);
      map.putIfAbsent(key, () => <AssetEntity>[]).add(asset);
    }
    return map.entries
        .map((e) => MediaDateGroup(title: e.key, assets: e.value))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(loadInitialAssets());
  }

  Future<void> loadInitialAssets() async {
    isLoading.value = true;
    permissionMessage.value = null;
    assets.clear();
    _album = null;
    _loadedCount = 0;
    _hasMore = true;

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      permissionMessage.value = '相册权限未授予';
      isLoading.value = false;
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    if (albums.isEmpty) {
      isLoading.value = false;
      return;
    }

    _album = albums.first;
    await _loadNextPage();
    isLoading.value = false;
  }

  Future<void> loadMoreIfNeeded(int currentIndex) async {
    if (_isLoadingMore || !_hasMore || _album == null) return;
    if (currentIndex < assets.length - 12) return;
    _isLoadingMore = true;
    await _loadNextPage();
    _isLoadingMore = false;
  }

  Future<void> _loadNextPage() async {
    final album = _album;
    if (album == null) return;

    final batch = await album.getAssetListRange(
      start: _loadedCount,
      end: _loadedCount + _pageSize,
    );
    if (batch.isEmpty) {
      _hasMore = false;
      return;
    }

    assets.addAll(batch);
    _loadedCount += batch.length;
    if (batch.length < _pageSize) {
      _hasMore = false;
    }
  }

  void activateFeature(MediaGalleryFeature feature) {
    final batchFeatures = <MediaGalleryFeature>{
      MediaGalleryFeature.collageReport,
      MediaGalleryFeature.batchAddWatermark,
      MediaGalleryFeature.batchRemoveWatermark,
      MediaGalleryFeature.batchEditWatermark,
    };
    if (!batchFeatures.contains(feature)) {
      selectedIds.clear();
    }
    activeFeature.value = feature;
  }

  void clearActiveFeature() {
    activeFeature.value = null;
  }

  bool isSelected(AssetEntity asset) => selectedIds.contains(asset.id);

  void toggleSelection(AssetEntity asset) {
    if (selectedIds.contains(asset.id)) {
      selectedIds.remove(asset.id);
    } else {
      selectedIds.add(asset.id);
    }
  }

  void selectSingle(AssetEntity asset) {
    selectedIds
      ..clear()
      ..add(asset.id);
  }

  List<AssetEntity> get selectedAssets =>
      assets.where((asset) => selectedIds.contains(asset.id)).toList();

  String featureLabel(MediaGalleryFeature feature) {
    return switch (feature) {
      MediaGalleryFeature.editWatermark => '编辑水印',
      MediaGalleryFeature.aiRemoveWatermark => 'AI去水印',
      MediaGalleryFeature.collageReport => '拼图汇报',
      MediaGalleryFeature.batchAddWatermark => '批量加水印',
      MediaGalleryFeature.batchRemoveWatermark => '批量去水印',
      MediaGalleryFeature.batchEditWatermark => '批量编辑水印',
    };
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return '今天';
    if (day == today.subtract(const Duration(days: 1))) return '昨天';
    return '${date.year}年${date.month}月${date.day}日';
  }
}
