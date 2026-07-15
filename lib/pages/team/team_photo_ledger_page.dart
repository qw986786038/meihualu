import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/utils/space_media_image.dart';
import 'package:watermark_camera/widgets/team_date_range_filter_sheet.dart';
import 'package:watermark_camera/widgets/team_watermark_filter_sheet.dart';
import 'package:watermark_camera/widgets/team_member_filter_sheet.dart';

class TeamPhotoLedgerPage extends StatefulWidget {
  const TeamPhotoLedgerPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamPhotoLedgerPage> createState() => _TeamPhotoLedgerPageState();
}

class _TeamPhotoLedgerPageState extends State<TeamPhotoLedgerPage> {
  static const _primaryBlue = Color(0xFF1677FF);

  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  Set<String> _selectedMemberIds = {};
  Set<String> _selectedWatermarkIds = {};

  Team get _team => widget.team;
  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month, now.day);
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
                  SizedBox(
                    height: 48,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            '照片明细',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: _rangeLabel,
                          onTap: _openDateFilter,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _selectedMemberIds.isEmpty
                              ? '筛选成员'
                              : '已选${_selectedMemberIds.length}人',
                          onTap: _openMemberFilter,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _selectedWatermarkIds.isEmpty
                              ? '筛选水印'
                              : '已选${_selectedWatermarkIds.length}个',
                          onTap: _openWatermarkFilter,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _PhotoDetailTab(
              photosBuilder: _filteredPhotos,
              memberForPhoto: _memberForPhoto,
              formatDateTime: _formatDateTime,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
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
            child: _PhotoThumb(
              filePath: photo.filePath,
              proofMark: photo.proofMark,
            ),
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
  const _PhotoThumb({
    required this.filePath,
    this.proofMark = false,
  });

  final String filePath;
  final bool proofMark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SpaceMediaThumbnail(
          url: filePath,
          placeholderColor: Colors.grey.shade200,
          proofMark: proofMark,
        ),
      ),
    );
  }
}
