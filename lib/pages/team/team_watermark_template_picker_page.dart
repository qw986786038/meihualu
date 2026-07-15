import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_watermark_template.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';
import 'package:watermark_camera/widgets/team_watermark_add_sheet.dart';

class TeamWatermarkTemplatePickerPage extends StatefulWidget {
  const TeamWatermarkTemplatePickerPage({super.key, this.team});

  final Team? team;

  @override
  State<TeamWatermarkTemplatePickerPage> createState() =>
      _TeamWatermarkTemplatePickerPageState();
}

class _TeamWatermarkTemplatePickerPageState
    extends State<TeamWatermarkTemplatePickerPage> {
  static const _primaryBlue = Color(0xFF1677FF);

  final _searchController = TextEditingController();
  int _selectedCategoryIndex = 1;

  String get _selectedCategory =>
      kTeamWatermarkTemplateCategories[_selectedCategoryIndex];

  List<TeamWatermarkTemplate> get _visibleTemplates {
    final keyword = _searchController.text.trim();
    Iterable<TeamWatermarkTemplate> items = kTeamWatermarkTemplates;

    switch (_selectedCategory) {
      case '我用过':
        items = items.where((item) => item.usedByMe);
        break;
      case '建筑工程':
        items = items.where(
          (item) => item.category == TeamWatermarkTemplateCategory.construction,
        );
        break;
      case '通用模板':
        items = items.where(
          (item) => item.category == TeamWatermarkTemplateCategory.general,
        );
        break;
    }

    if (keyword.isNotEmpty) {
      items = items.where(
        (item) =>
            item.title.contains(keyword) ||
            item.description.contains(keyword),
      );
    }

    return items.toList();
  }

  Future<void> _onAddTemplate(
    TeamWatermarkTemplate template,
    Widget preview,
  ) async {
    final result = await showTeamWatermarkAddSheet(
      context,
      template: template,
      preview: preview,
    );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加「${result.watermarkName}」到团队水印')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = _visibleTemplates;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sampleNow = DateTime(2026, 5, 12, 10, 40);
    const sampleAddress = '深圳市南山区 · 科技园';
    const sampleWeather = '晴';
    const sampleTemperature = '26';
    const sampleCoordinate = '经纬度 22.540503, 113.934528';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryTabs(),
            const Divider(height: 1),
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Text(
                        '暂无匹配模板',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        24 + bottomInset,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        final preview = WatermarkTemplateView(
                          templateId: template.previewTemplateId,
                          now: sampleNow,
                          address: sampleAddress,
                          weatherText: sampleWeather,
                          temperatureText: sampleTemperature,
                          coordinateText: sampleCoordinate,
                          showCoordinate: true,
                          compact: true,
                        );
                        return _TemplateCard(
                          template: template,
                          preview: preview,
                          onAdd: () => _onAddTemplate(template, preview),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: const Color(0xFF333333),
          ),
          const Expanded(
            child: Text(
              '选择模板',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: '搜水印，行业/公司/品牌',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
          filled: true,
          fillColor: const Color(0xFFF5F6F8),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kTeamWatermarkTemplateCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final selected = index == _selectedCategoryIndex;
          return InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: SizedBox(
              height: 44,
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        kTeamWatermarkTemplateCategories[index],
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.0,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected
                              ? _primaryBlue
                              : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 24 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.preview,
    required this.onAdd,
  });

  final TeamWatermarkTemplate template;
  final Widget preview;
  final VoidCallback onAdd;

  static const _primaryBlue = Color(0xFF1677FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
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
                  child: preview,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
            child: Text(
              template.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              template.usageCountLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
            child: Text(
              template.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                backgroundColor: const Color(0xFFEAF3FF),
                side: BorderSide.none,
                minimumSize: const Size.fromHeight(32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                '添加',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
