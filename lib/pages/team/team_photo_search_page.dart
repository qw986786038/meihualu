import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/space_media_list_data.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/utils/api_date_format.dart';
import 'package:watermark_camera/utils/space_media_image.dart';
import 'package:watermark_camera/utils/space_media_viewer.dart';
import 'package:watermark_camera/models/space_media_viewer_item.dart';
import 'package:watermark_camera/widgets/team_date_filter_sheet.dart';
import 'package:watermark_camera/widgets/team_member_filter_sheet.dart';
import 'package:watermark_camera/widgets/team_watermark_filter_sheet.dart';

class TeamPhotoSearchPage extends StatefulWidget {
  const TeamPhotoSearchPage({super.key, this.teamId, this.spaceId});

  final String? teamId;
  final String? spaceId;

  String get resolvedSpaceId => spaceId ?? teamId ?? '';

  @override
  State<TeamPhotoSearchPage> createState() => _TeamPhotoSearchPageState();
}

class _TeamPhotoSearchPageState extends State<TeamPhotoSearchPage> {
  static const _primaryBlue = Color(0xFF1677FF);

  final _searchController = TextEditingController();

  DateTime? _beginDate;
  DateTime? _endDate;
  String? _shootUserId;
  String? _shootUserName;
  int? _watermarkId;
  String? _watermarkLabel;

  bool _isSearching = false;
  SpaceMediaListData? _result;
  String? _errorMessage;

  AuthService get _auth => Get.find<AuthService>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _dateRangeLabel {
    if (_beginDate == null && _endDate == null) return '日期范围';
    if (_beginDate != null && _endDate != null) {
      return '${formatApiDate(_beginDate!)}-${formatApiDate(_endDate!)}';
    }
    final date = _beginDate ?? _endDate!;
    return formatApiDate(date);
  }

  Future<void> _pickDateRange() async {
    final spaceId =
        widget.resolvedSpaceId.isEmpty ? null : widget.resolvedSpaceId;
    final begin = await showTeamDateFilterSheet(
      context,
      initialDate: _beginDate ?? DateTime.now(),
      spaceId: spaceId,
    );
    if (begin == null || !mounted) return;

    final end = await showTeamDateFilterSheet(
      context,
      initialDate: _endDate ?? begin,
      spaceId: spaceId,
    );
    if (!mounted) return;

    setState(() {
      _beginDate = begin;
      _endDate = end ?? begin;
    });
  }

  Future<void> _pickShooter() async {
    final spaceId = widget.resolvedSpaceId;
    if (spaceId.isEmpty) return;

    final result = await showTeamMemberFilterSheet(
      context,
      teamId: spaceId,
      initialSelectedMemberIds:
          _shootUserId == null ? {} : {_shootUserId!},
    );
    if (result == null || !mounted) return;

    setState(() {
      if (result.memberIds.isEmpty) {
        _shootUserId = null;
        _shootUserName = null;
        return;
      }
      _shootUserId = result.memberIds.first;
      final members = Get.find<TeamWorkspaceService>().membersForTeam(spaceId);
      TeamMember? matched;
      for (final member in members) {
        if (member.id == _shootUserId) {
          matched = member;
          break;
        }
      }
      _shootUserName = matched?.name;
    });
  }

  Future<void> _pickWatermark() async {
    final picked = await showTeamWatermarkFilterSheet(context);
    if (picked == null || !mounted) return;

    setState(() {
      if (picked.watermarkIds.isEmpty) {
        _watermarkId = null;
        _watermarkLabel = null;
        return;
      }
      final id = picked.watermarkIds.first;
      _watermarkId = int.tryParse(id);
      _watermarkLabel = id;
    });
  }

  Future<void> _search() async {
    final spaceId = widget.resolvedSpaceId;
    final token = _auth.accessToken.value.trim();
    if (spaceId.isEmpty) {
      setState(() => _errorMessage = '空间信息无效');
      return;
    }
    if (token.isEmpty) {
      setState(() => _errorMessage = '请先登录');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final keyword = _searchController.text.trim();
      final response = await Get.find<SpaceApiService>().searchMediaList(
        accessToken: token,
        spaceId: spaceId,
        shootBeginDate:
            _beginDate == null ? null : formatApiDate(_beginDate!),
        shootEndDate: _endDate == null ? null : formatApiDate(_endDate!),
        shootUserId: _shootUserId,
        shootPlace: keyword.isEmpty ? null : keyword,
        watermarkId: _watermarkId,
      );

      if (!mounted) return;

      if (!response.isSuccess || response.data == null) {
        setState(() {
          _result = null;
          _errorMessage = response.msg ?? '搜索失败，请稍后重试';
        });
        return;
      }

      setState(() {
        _result = response.data;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _errorMessage = '搜索失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '查找照片',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '水印文字，人名，地点...一句话搜索',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: _dateRangeLabel,
                  onTap: _pickDateRange,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _shootUserName ?? '拍摄人',
                  onTap: _pickShooter,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _searchController.text.trim().isEmpty
                      ? '地点'
                      : _searchController.text.trim(),
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _watermarkLabel ?? '水印',
                  onTap: _pickWatermark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildResultBody(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
            child: FilledButton(
              onPressed: _isSearching ? null : _search,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '查找照片',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBody() {
    if (_isSearching && _result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Text(
          '设置筛选条件后点击查找照片',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final groups = _result!.groups;
    if (groups.isEmpty) {
      return Center(
        child: Text(
          '未找到符合条件的照片',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _SearchResultGroup(group: group);
      },
    );
  }
}

class _SearchResultGroup extends StatelessWidget {
  const _SearchResultGroup({required this.group});

  final SpaceMediaGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.date,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.files.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final file = group.files[index];
              return GestureDetector(
                onTap: () => openSpaceMediaViewer(
                  context,
                  items: SpaceMediaViewerItem.fromSpaceMediaFiles(group.files),
                  initialIndex: index,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SpaceMediaThumbnail(
                    url: file.displayUrl,
                    isVideo: file.isVideo,
                    proofMark: file.proofMark,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Icon(Icons.expand_more, size: 18, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
