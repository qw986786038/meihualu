import 'dart:async' show unawaited;

import 'package:getx_plus/getx_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/gallery/media_gallery_controller.dart';

class MediaVerifyPickerController extends GetxController {
  final RxList<AssetEntity> assets = <AssetEntity>[].obs;
  final RxBool isLoading = true.obs;
  final Rxn<String> permissionMessage = Rxn<String>();

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
    if (currentIndex < assets.length - 9) return;
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

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
