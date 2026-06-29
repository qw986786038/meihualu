import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/widgets/team_date_range_filter_sheet.dart';
import 'package:watermark_camera/widgets/team_watermark_filter_sheet.dart';
import 'package:watermark_camera/widgets/team_member_filter_sheet.dart';

class TeamPhotoLedgerPage extends StatefulWidget {
  const TeamPhotoLedgerPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamPhotoLedgerPage> createState() => _TeamPhotoLedgerPageState();
}

class _TeamPhotoLedgerPageState extends State<TeamPhotoLedgerPage>
    with SingleTickerProviderStateMixin {
  static const _primaryBlue = Color(0xFF1677FF);
  static const _wechatGreen = Color(0xFF07C160);

  late final TabController _tabController;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  Set<String> _selectedMemberIds = {};
  Set<String> _selectedWatermarkIds = {};

  Team get _team => widget.team;
  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  String _formatRangeDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month月$day日';
  }

  String get _rangeLabel =>
      '${_formatRangeDate(_rangeStart)}~${_formatRangeDate(_rangeEnd)}';

  bool _isInRange(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final end = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  Future<void> _openDateFilter() async {
    final result = await showTeamDateRangeFilterSheet(
      context,
      initialStart: _rangeStart,
      initialEnd: _rangeEnd,
    );
    if (result == null || !mounted) return;
    setState(() {
      _rangeStart = result.start;
      _rangeEnd = result.end;
    });
  }

  Future<void> _openMemberFilter() async {
    final result = await showTeamMemberFilterSheet(
      context,
      teamId: _team.id,
      initialSelectedMemberIds: _selectedMemberIds,
    );
    if (result == null || !mounted) return;
    setState(() => _selectedMemberIds = result.memberIds);
  }

  Future<void> _openWatermarkFilter() async {
    final result = await showTeamWatermarkFilterSheet(
      context,
      initialSelectedWatermarkIds: _selectedWatermarkIds,
    );
    if (result == null || !mounted) return;
    setState(() => _selectedWatermarkIds = result.watermarkIds);
  }

  bool _photoMatchesWatermarkFilter(TeamAlbumPhoto photo) {
    if (_selectedWatermarkIds.isEmpty) return true;
    final templateId = photo.watermarkTemplateId;
    for (final id in _selectedWatermarkIds) {
      if (id == kNoWatermarkFilterId && templateId == null) return true;
      if (id == templateId) return true;
      if (id.startsWith('team_') && id.substring(5) == templateId) return true;
    }
    return false;
  }

  List<TeamAlbumPhoto> _filteredPhotos() {
    var photos = _workspace.photosForTeam(_team.id);
    photos = photos.where((photo) => _isInRange(photo.capturedAt)).toList();
    if (_selectedMemberIds.isNotEmpty) {
      photos = photos
          .where((photo) => _selectedMemberIds.contains(photo.memberId))
          .toList();
    }
    if (_selectedWatermarkIds.isNotEmpty) {
      photos = photos.where(_photoMatchesWatermarkFilter).toList();
    }
    return photos;
  }

  TeamMember? _memberForPhoto(TeamAlbumPhoto photo) {
    for (final member in _workspace.membersForTeam(_team.id)) {
      if (member.id == photo.memberId) return member;
    }
    return null;
  }

  String _formatDateTime(DateTime time) {
    final year = time.year;
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        ),
                        Expanded(
                          child: TabBar(
                            controller: _tabController,
                            labelColor: _primaryBlue,
                            unselectedLabelColor: Colors.grey.shade600,
                            indicatorColor: _primaryBlue,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            tabs: [
                              const Tab(text: '照片明细'),
                              Tab(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Text('拍照统计'),
                                    Positioned(
                                      right: -8,
                                      top: -2,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE64545),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Tab(text: '拜访记录'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: _rangeLabel,
                            onTap: _openDateFilter,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: _selectedMemberIds.isEmpty
                                ? '筛选成员'
                                : '已选${_selectedMemberIds.length}人',
                            onTap: _openMemberFilter,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: _selectedWatermarkIds.isEmpty
                                ? '筛选水印'
                                : '已选${_selectedWatermarkIds.length}个',
                            onTap: _openWatermarkFilter,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PhotoDetailTab(
                  photosBuilder: _filteredPhotos,
                  memberForPhoto: _memberForPhoto,
                  formatDateTime: _formatDateTime,
                ),
                _PlaceholderTab(message: '拍照统计功能开发中'),
                _PlaceholderTab(message: '拜访记录功能开发中'),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset > 0 ? 6 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  _HistoryAction(
                    onTap: () => _showComingSoon('历史记录'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VipActionButton(
                      label: '分享到微信',
                      icon: Icons.wechat,
                      color: _wechatGreen,
                      onTap: () => _showComingSoon('分享到微信'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VipActionButton(
                      label: '保存Excel',
                      icon: Icons.download_outlined,
                      color: _primaryBlue,
                      onTap: () => _showComingSoon('保存Excel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Icon(Icons.expand_more, size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoDetailTab extends StatelessWidget {
  const _PhotoDetailTab({
    required this.photosBuilder,
    required this.memberForPhoto,
    required this.formatDateTime,
  });

  final List<TeamAlbumPhoto> Function() photosBuilder;
  final TeamMember? Function(TeamAlbumPhoto photo) memberForPhoto;
  final String Function(DateTime time) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = photosBuilder();
      final memberCount =
          photos.map((photo) => photo.memberId).toSet().length;
      final watermarkCount = photos
          .map((photo) => photo.watermarkTemplateId ?? kNoWatermarkFilterId)
          .toSet()
          .length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: '共计'),
                  TextSpan(
                    text: '$memberCount',
                    style: const TextStyle(
                      color: Color(0xFF1677FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '人拍照，拍照'),
                  TextSpan(
                    text: '${photos.length}',
                    style: const TextStyle(
                      color: Color(0xFF1677FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '张，使用'),
                  TextSpan(
                    text: '$watermarkCount',
                    style: const TextStyle(
                      color: Color(0xFF1677FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '个水印'),
                ],
              ),
            ),
          ),
          const _LedgerTableHeader(),
          Expanded(
            child: photos.isEmpty
                ? Center(
                    child: Text(
                      '暂无照片记录',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final member = memberForPhoto(photo);
                      return _LedgerTableRow(
                        photo: photo,
                        memberName: member?.name ?? '未知',
                        capturedAtLabel: formatDateTime(photo.capturedAt),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

class _LedgerTableHeader extends StatelessWidget {
  const _LedgerTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 56, child: Text('照片', style: _headerStyle)),
          SizedBox(width: 56, child: Text('拍摄人', style: _headerStyle)),
          Expanded(child: Text('水印名称', style: _headerStyle)),
          SizedBox(width: 132, child: Text('拍摄时间', style: _headerStyle)),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF666666),
    fontWeight: FontWeight.w500,
  );
}

class _LedgerTableRow extends StatelessWidget {
  const _LedgerTableRow({
    required this.photo,
    required this.memberName,
    required this.capturedAtLabel,
  });

  final TeamAlbumPhoto photo;
  final String memberName;
  final String capturedAtLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: _PhotoThumb(filePath: photo.filePath),
          ),
          SizedBox(
            width: 56,
            child: Text(
              memberName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          ),
          const Expanded(
            child: Text(
              '',
              style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          ),
          SizedBox(
            width: 132,
            child: Text(
              capturedAtLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    if (filePath.isNotEmpty) {
      final file = File(filePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            file,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.image_outlined, size: 20, color: Colors.grey.shade400),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }
}

class _HistoryAction extends StatelessWidget {
  const _HistoryAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 22, color: Colors.grey.shade700),
            const SizedBox(height: 2),
            Text(
              '历史记录',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _VipActionButton extends StatelessWidget {
  const _VipActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(icon, size: 18),
            label: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const Positioned(
          right: -2,
          top: -6,
          child: Icon(
            Icons.workspace_premium,
            size: 18,
            color: Color(0xFFFFB020),
          ),
        ),
      ],
    );
  }
}
