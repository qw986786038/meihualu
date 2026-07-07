import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_watermark_template.dart';
import 'package:watermark_camera/pages/camera/WaterMarkController.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';
import 'package:watermark_camera/widgets/work_mode_switch_sheet.dart';

enum _WatermarkSourceTab { team, mine }

class _PersonalWatermarkItem {
  const _PersonalWatermarkItem({
    required this.templateId,
    required this.title,
    required this.previewTemplateId,
    required this.category,
    this.badge,
  });

  final String templateId;
  final String title;
  final String previewTemplateId;
  final String category;
  final String? badge;
}

const _primaryBlue = Color(0xFF1677FF);

const _personalCategories = ['我的', '餐饮业', '品牌图'];

const List<_PersonalWatermarkItem> _personalWatermarkItems = [
  _PersonalWatermarkItem(
    templateId: 'classic',
    title: '时间地点天气',
    previewTemplateId: 'classic',
    category: '餐饮业',
    badge: '简单通用',
  ),
  _PersonalWatermarkItem(
    templateId: 'panel',
    title: '考勤打卡',
    previewTemplateId: 'panel',
    category: '我的',
    badge: '简单通用',
  ),
  _PersonalWatermarkItem(
    templateId: 'minimal',
    title: '自定义水印',
    previewTemplateId: 'minimal',
    category: '我的',
  ),
  _PersonalWatermarkItem(
    templateId: 'classic',
    title: '餐饮水印',
    previewTemplateId: 'classic',
    category: '餐饮业',
    badge: '餐饮专用',
  ),
  _PersonalWatermarkItem(
    templateId: 'panel',
    title: '工程水印',
    previewTemplateId: 'panel',
    category: '品牌图',
  ),
  _PersonalWatermarkItem(
    templateId: 'minimal',
    title: '物业水印',
    previewTemplateId: 'minimal',
    category: '品牌图',
  ),
  _PersonalWatermarkItem(
    templateId: 'classic',
    title: '品牌水印',
    previewTemplateId: 'classic',
    category: '品牌图',
  ),
  _PersonalWatermarkItem(
    templateId: 'panel',
    title: '现场拍照',
    previewTemplateId: 'panel',
    category: '我的',
  ),
];

class WaterMarkSelectPage extends StatefulWidget {
  const WaterMarkSelectPage({super.key});

  @override
  State<WaterMarkSelectPage> createState() => _WaterMarkSelectPageState();
}

class _WaterMarkSelectPageState extends State<WaterMarkSelectPage> {
  _WatermarkSourceTab _activeTab = _WatermarkSourceTab.mine;
  int _selectedCategoryIndex = 0;
  final _searchController = TextEditingController();

  WaterMarkController get _controller => Get.find<WaterMarkController>();
  AuthService get _auth => Get.find<AuthService>();
  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  static const _sampleAddress = '深圳市南山区 · 科技园';
  static const _sampleWeather = '晴';
  static const _sampleTemperature = '26';
  static const _sampleCoordinate = '经纬度 22.540503, 113.934528';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTemplate(String templateId) {
    _controller.selectTemplate(templateId);
    Navigator.of(context).pop();
  }

  void _disableWatermark() {
    _controller.removeWaterMark();
    Navigator.of(context).pop();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  Future<void> _openSwitchTeam() async {
    await showWorkModeSwitchSheet(
      context,
      currentTeam: _auth.activeTeam.value,
      currentWorkspace: WorkspaceContext.camera,
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAddTeamWatermark() async {
    final team = _auth.activeTeam.value;
    if (team == null) {
      _showComingSoon('请先加入团队');
      return;
    }
    Navigator.of(context).pop();
    await context.push(AppPaths.teamWatermarkTemplates, extra: team);
  }

  List<_PersonalWatermarkItem> get _visiblePersonalItems {
    final keyword = _searchController.text.trim();
    final category = _personalCategories[_selectedCategoryIndex];
    var items = _personalWatermarkItems;
    if (category != '我的') {
      items = items.where((item) => item.category == category).toList();
    }
    if (keyword.isNotEmpty) {
      items = items
          .where((item) => item.title.contains(keyword))
          .toList(growable: false);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sampleNow = DateTime(2026, 5, 12, 10, 40);

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _activeTab == _WatermarkSourceTab.mine
              ? _buildMineTab(sampleNow, bottom)
              : _buildTeamTab(sampleNow, bottom),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _disableWatermark,
            icon: Icon(Icons.block, size: 22, color: Colors.grey.shade700),
            tooltip: '无水印',
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HeaderTab(
                    label: '团队水印',
                    selected: _activeTab == _WatermarkSourceTab.team,
                    badge: '团队提效',
                    onTap: () => setState(
                      () => _activeTab = _WatermarkSourceTab.team,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _HeaderTab(
                    label: '我的水印',
                    selected: _activeTab == _WatermarkSourceTab.mine,
                    onTap: () => setState(
                      () => _activeTab = _WatermarkSourceTab.mine,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, size: 22, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildMineTab(DateTime sampleNow, double bottom) {
    final items = _visiblePersonalItems;
    final mineCount = _personalWatermarkItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜水印',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _personalCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == _selectedCategoryIndex;
              final label = index == 0
                  ? '${_personalCategories[index]}($mineCount)'
                  : _personalCategories[index];
              return Material(
                color: selected
                    ? const Color(0xFFEAF3FF)
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? _primaryBlue : const Color(0xFF666666),
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (index == 2) ...[
                          const SizedBox(width: 2),
                          Icon(
                            Icons.expand_more,
                            size: 16,
                            color: selected ? _primaryBlue : Colors.grey.shade600,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    '暂无匹配水印',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : Obx(() {
                  final selectedId = _controller.selectedTemplateId.value;
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = selectedId == item.templateId;
                      return _PersonalTemplateCard(
                        item: item,
                        selected: selected,
                        sampleNow: sampleNow,
                        onTap: () => _selectTemplate(item.templateId),
                      );
                    },
                  );
                }),
        ),
      ],
    );
  }

  Widget _buildTeamTab(DateTime sampleNow, double bottom) {
    return Obx(() {
      final team = _auth.activeTeam.value;
      final memberCount =
          team == null ? 0 : _workspace.membersForTeam(team.id).length;
      const teamWatermarkCount = 0;
      final usedTemplates = kTeamWatermarkTemplates
          .where((item) => item.usedByMe)
          .toList(growable: false);

      return ListView(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
        children: [
          if (team != null)
            _TeamInfoCard(
              team: team,
              memberCount: memberCount,
              watermarkCount: teamWatermarkCount,
              onSwitchTeam: _openSwitchTeam,
            )
          else
            _NoTeamCard(onJoinTeam: _openSwitchTeam),
          const SizedBox(height: 12),
          if (teamWatermarkCount == 0) ...[
            _TeamWatermarkEmptyCard(onAdd: _openAddTeamWatermark),
            const SizedBox(height: 16),
          ],
          if (usedTemplates.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  '优质水印推荐',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const Spacer(),
                Text(
                  '您使用过',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: usedTemplates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final template = usedTemplates[index];
                  return _RecommendedTemplateCard(
                    template: template,
                    sampleNow: sampleNow,
                    onTap: () => _selectTemplate(template.previewTemplateId),
                  );
                },
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            child: badge == null
                ? null
                : Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? const Color(0xFF111111) : const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 24 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalTemplateCard extends StatelessWidget {
  const _PersonalTemplateCard({
    required this.item,
    required this.selected,
    required this.sampleNow,
    required this.onTap,
  });

  final _PersonalWatermarkItem item;
  final bool selected;
  final DateTime sampleNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _primaryBlue : const Color(0xFFEEEEEE),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(8),
                      child: FittedBox(
                        alignment: Alignment.bottomLeft,
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: WatermarkTemplateView(
                            templateId: item.previewTemplateId,
                            now: sampleNow,
                            address: _WaterMarkSelectPageState._sampleAddress,
                            weatherText:
                                _WaterMarkSelectPageState._sampleWeather,
                            temperatureText:
                                _WaterMarkSelectPageState._sampleTemperature,
                            coordinateText:
                                _WaterMarkSelectPageState._sampleCoordinate,
                            showCoordinate: true,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D4F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: selected ? _primaryBlue : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamInfoCard extends StatelessWidget {
  const _TeamInfoCard({
    required this.team,
    required this.memberCount,
    required this.watermarkCount,
    required this.onSwitchTeam,
  });

  final Team team;
  final int memberCount;
  final int watermarkCount;
  final VoidCallback onSwitchTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _TeamAvatar(team: team),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberCount位成员，$watermarkCount个团队水印',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onSwitchTeam,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('切换团队'),
            style: TextButton.styleFrom(
              foregroundColor: _primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final brandPath = team.brandImagePath;
    if (brandPath != null && brandPath.isNotEmpty && File(brandPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(brandPath),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }

    final initial = team.name.isNotEmpty ? team.name.substring(0, 1) : '团';
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1677FF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _primaryBlue,
        ),
      ),
    );
  }
}

class _NoTeamCard extends StatelessWidget {
  const _NoTeamCard({required this.onJoinTeam});

  final VoidCallback onJoinTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '加入团队后可使用团队共享水印',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onJoinTeam,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('加入或创建团队'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamWatermarkEmptyCard extends StatelessWidget {
  const _TeamWatermarkEmptyCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFDDDDDD),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '多人共享水印',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            '(待添加)',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '去添加',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedTemplateCard extends StatelessWidget {
  const _RecommendedTemplateCard({
    required this.template,
    required this.sampleNow,
    required this.onTap,
  });

  final TeamWatermarkTemplate template;
  final DateTime sampleNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    alignment: Alignment.bottomLeft,
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: WatermarkTemplateView(
                        templateId: template.previewTemplateId,
                        now: sampleNow,
                        address: _WaterMarkSelectPageState._sampleAddress,
                        weatherText: _WaterMarkSelectPageState._sampleWeather,
                        temperatureText:
                            _WaterMarkSelectPageState._sampleTemperature,
                        coordinateText:
                            _WaterMarkSelectPageState._sampleCoordinate,
                        showCoordinate: true,
                        compact: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
