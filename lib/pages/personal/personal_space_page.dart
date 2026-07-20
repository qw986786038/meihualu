import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/personal_album_photo.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/models/space_media_viewer_item.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/utils/media_capture_summary.dart';
import 'package:watermark_camera/utils/space_media_downloader.dart';
import 'package:watermark_camera/utils/space_media_image.dart';
import 'package:watermark_camera/utils/space_media_viewer.dart';
import 'package:watermark_camera/widgets/work_mode_switch_sheet.dart';

class PersonalSpacePage extends StatefulWidget {
  const PersonalSpacePage({super.key});

  static const debugSpace = PersonalSpace(
    id: 'debug_personal',
    name: '李的空间',
    avatarText: '李',
  );

  @override
  State<PersonalSpacePage> createState() => _PersonalSpacePageState();
}

class _PersonalSpacePageState extends State<PersonalSpacePage> {
  static const _primaryBlue = Color(0xFF1677FF);

  AuthService get _auth => Get.find<AuthService>();
  PersonalSpaceService get _personalService => Get.find<PersonalSpaceService>();

  PersonalSpace get _space => resolvePersonalSpace(_auth);

  @override
  void initState() {
    super.initState();
    _auth.setWorkMode(WorkMode.personal);
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (!_auth.isLoggedIn.value) return;
    final spaceId = _auth.personalSpace.value?.id;
    final token = _auth.accessToken.value.trim();
    if (spaceId == null || spaceId.isEmpty || token.isEmpty) return;
    await _personalService.fetchMediaList(
      spaceId: spaceId,
      accessToken: token,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openPhotoSearch() async {
    final spaceId = _auth.personalSpace.value?.id ?? _space.id;
    if (spaceId.isEmpty || spaceId == 'debug_personal') {
      _showSnack('暂无法搜索');
      return;
    }
    await context.push(AppPaths.teamPhotoSearch, extra: spaceId);
  }

  Future<void> _openWorkModeSwitchSheet() async {
    await showWorkModeSwitchSheet(
      context,
      currentTeam: _auth.activeTeam.value,
      currentWorkspace: WorkspaceContext.personal,
    );
  }

  Future<void> _openCreateOrJoinTeam() async {
    await showWorkModeSwitchSheet(
      context,
      currentTeam: _auth.activeTeam.value,
      currentWorkspace: WorkspaceContext.personal,
    );
  }

  String _formatDateGroup(DateTime date, int count) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month月$day日·$count张';
  }

  Map<DateTime, List<PersonalAlbumPhoto>> _groupPhotosByDay(
    List<PersonalAlbumPhoto> photos,
  ) {
    final grouped = <DateTime, List<PersonalAlbumPhoto>>{};
    for (final photo in photos) {
      final day = DateTime(
        photo.capturedAt.year,
        photo.capturedAt.month,
        photo.capturedAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(photo);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                if (_personalService.isLoadingMedia.value &&
                    _personalService.photosForSpace(_space.id).isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final photos = _personalService.photosForSpace(_space.id);
                final syncedPhotos =
                    photos.where((photo) => photo.filePath.isNotEmpty).toList();
                final groupedPhotos = _groupPhotosByDay(syncedPhotos);
                final sortedDays = groupedPhotos.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    SliverToBoxAdapter(child: _buildGalleryHeader(syncedPhotos.length)),
                    if (syncedPhotos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            '暂无照片\n开启拍照自动同步后，拍摄的照片会显示在这里',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                          ),
                        ),
                      )
                    else
                      ...sortedDays.map((day) {
                        final dayPhotos = groupedPhotos[day]!;
                        return SliverToBoxAdapter(
                          child: _PhotoDaySection(
                            title: _formatDateGroup(day, dayPhotos.length),
                            photos: dayPhotos,
                          ),
                        );
                      }),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: const Color(0xFF333333),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _openWorkModeSwitchSheet,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          label: const Text('1', style: TextStyle(fontSize: 10)),
                          child: Text(
                            _space.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.expand_more, size: 20, color: Colors.grey.shade700),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _openCreateOrJoinTeam,
              child: const Text(
                '创建/加入团队',
                style: TextStyle(fontSize: 14, color: _primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        readOnly: true,
        onTap: _openPhotoSearch,
        decoration: InputDecoration(
          hintText: '搜水印内容、拍摄地点...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _openUploadPicker() async {
    final spaceId = _auth.personalSpace.value?.id ?? _space.id;
    if (spaceId.isEmpty || spaceId == 'debug_personal') {
      _showSnack('暂无法上传照片');
      return;
    }
    await context.push<bool>(AppPaths.personalSpaceUpload, extra: spaceId);
  }

  Widget _buildQuickActions() {
    const actions = [
      _QuickAction(icon: Icons.file_upload_outlined, label: '上传照片'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: _QuickActionTile(
                  action: action,
                  onTap: _openUploadPicker,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGalleryHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Text(
            '全部照片 $count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.onTap});

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(action.icon, size: 28, color: const Color(0xFF1677FF)),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoDaySection extends StatelessWidget {
  const _PhotoDaySection({required this.title, required this.photos});

  final String title;
  final List<PersonalAlbumPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3;
              const spacing = 8.0;
              final cellSize =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (var index = 0; index < photos.length; index++)
                    SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: _PersonalPhotoTile(
                        photo: photos[index],
                        allPhotos: photos,
                        photoIndex: index,
                        compact: true,
                      ),
                    ),
                ],
              );
            },
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DayCaptureSummary(photos: photos),
          ],
        ],
      ),
    );
  }
}

class _PersonalPhotoTile extends StatelessWidget {
  const _PersonalPhotoTile({
    required this.photo,
    required this.allPhotos,
    required this.photoIndex,
    this.compact = false,
  });

  final PersonalAlbumPhoto photo;
  final List<PersonalAlbumPhoto> allPhotos;
  final int photoIndex;
  final bool compact;

  Future<void> _openViewer(BuildContext context) async {
    await openSpaceMediaViewer(
      context,
      items: SpaceMediaViewerItem.fromPersonalPhotos(allPhotos),
      initialIndex: photoIndex,
    );
  }

  Future<void> _download(BuildContext context) async {
    final url = photo.downloadUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可下载的文件')),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('正在下载...')));

    final success = await SpaceMediaDownloader.downloadToGallery(
      ossUrl: url,
      isVideo: photo.isVideo,
      fileName: photo.fileName,
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(success ? '已保存到相册' : '下载失败，请稍后重试'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      onLongPress: () => _download(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox.expand(
          child: SpaceMediaThumbnail(
            url: photo.filePath,
            isVideo: photo.isVideo,
            proofMark: photo.proofMark,
            videoIconSize: compact ? 24 : 40,
            bottomOverlay: !compact
                ? Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: _PhotoWatermarkOverlay(photo: photo),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _PhotoWatermarkOverlay extends StatelessWidget {
  const _PhotoWatermarkOverlay({required this.photo});

  final PersonalAlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    final time = photo.capturedAt;
    final watermarkTime = photo.watermarkTime;
    final displayTime = watermarkTime != null && watermarkTime.isNotEmpty
        ? _formatWatermarkTime(watermarkTime, time)
        : time;
    final hour = displayTime.hour.toString().padLeft(2, '0');
    final minute = displayTime.minute.toString().padLeft(2, '0');
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekday = weekdays[displayTime.weekday - 1];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$hour:$minute',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${displayTime.year}-${displayTime.month.toString().padLeft(2, '0')}-${displayTime.day.toString().padLeft(2, '0')} $weekday',
            style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
          ),
          if (photo.location != null) ...[
            const SizedBox(height: 2),
            Text(
              photo.location!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.2),
            ),
          ],
        ],
      ),
    );
  }

  DateTime _formatWatermarkTime(String watermarkTime, DateTime fallback) {
    final normalized = watermarkTime.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized) ?? fallback;
  }
}

class _DayCaptureSummary extends StatelessWidget {
  const _DayCaptureSummary({required this.photos});

  final List<PersonalAlbumPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final latest = photos.reduce(
      (a, b) => a.capturedAt.isAfter(b.capturedAt) ? a : b,
    );
    final summary = MediaCaptureSummary.buildLastCaptureLine(
      lastCaptureTime: latest.capturedAt,
      distanceMeters: null,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        summary,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }
}
