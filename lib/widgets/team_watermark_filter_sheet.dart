import 'package:flutter/material.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

const String kNoWatermarkFilterId = 'none';

enum WatermarkFilterKind { none, team, normal }

class TeamWatermarkFilterResult {
  const TeamWatermarkFilterResult({required this.watermarkIds});

  final Set<String> watermarkIds;

  bool get hasFilter => watermarkIds.isNotEmpty;
}

class WatermarkFilterOption {
  const WatermarkFilterOption({
    required this.id,
    required this.kind,
    required this.title,
    this.templateId,
    this.lastUsedAt,
  });

  final String id;
  final WatermarkFilterKind kind;
  final String title;
  final String? templateId;
  final DateTime? lastUsedAt;
}

List<WatermarkFilterOption> defaultWatermarkFilterOptions() {
  final now = DateTime.now();
  return [
    WatermarkFilterOption(
      id: kNoWatermarkFilterId,
      kind: WatermarkFilterKind.none,
      title: '无水印',
      lastUsedAt: DateTime(now.year, now.month, 12),
    ),
    WatermarkFilterOption(
      id: 'team_classic',
      kind: WatermarkFilterKind.team,
      title: '团队经典水印',
      templateId: 'classic',
      lastUsedAt: DateTime(now.year, now.month, 18),
    ),
    for (final preset in kWatermarkTemplatePresets)
      WatermarkFilterOption(
        id: preset.id,
        kind: WatermarkFilterKind.normal,
        title: preset.title,
        templateId: preset.id,
        lastUsedAt: DateTime(now.year, now.month, now.day),
      ),
  ];
}

Future<TeamWatermarkFilterResult?> showTeamWatermarkFilterSheet(
  BuildContext context, {
  Set<String>? initialSelectedWatermarkIds,
  List<WatermarkFilterOption>? options,
}) {
  return showModalBottomSheet<TeamWatermarkFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => TeamWatermarkFilterSheet(
      initialSelectedWatermarkIds: initialSelectedWatermarkIds ?? const {},
      options: options ?? defaultWatermarkFilterOptions(),
    ),
  );
}

class TeamWatermarkFilterSheet extends StatefulWidget {
  const TeamWatermarkFilterSheet({
    super.key,
    required this.initialSelectedWatermarkIds,
    required this.options,
  });

  final Set<String> initialSelectedWatermarkIds;
  final List<WatermarkFilterOption> options;

  @override
  State<TeamWatermarkFilterSheet> createState() =>
      _TeamWatermarkFilterSheetState();
}

class _TeamWatermarkFilterSheetState extends State<TeamWatermarkFilterSheet>
    with SingleTickerProviderStateMixin {
  static const _primaryBlue = Color(0xFF1677FF);
  static const _tabs = ['全部水印', '团队水印', '普通水印'];

  late final TabController _tabController;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _selectedIds = Set<String>.from(widget.initialSelectedWatermarkIds);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<WatermarkFilterOption> _optionsForTab(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return widget.options
            .where((option) => option.kind == WatermarkFilterKind.team)
            .toList();
      case 2:
        return widget.options
            .where((option) => option.kind == WatermarkFilterKind.normal)
            .toList();
      default:
        return widget.options;
    }
  }

  void _toggleOption(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    Navigator.pop(
      context,
      TeamWatermarkFilterResult(watermarkIds: Set<String>.from(_selectedIds)),
    );
  }

  String _formatLastUsed(DateTime? date) {
    if (date == null) return '';
    return '${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;
    final sampleNow = DateTime(2021, 9, 15, 11, 30);
    const sampleAddress = '北京市 · 三里屯';

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '选择水印',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  const SizedBox(width: 64),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: _primaryBlue,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: _primaryBlue,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: [for (final tab in _tabs) Tab(text: tab)],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (tabIndex) {
                  final options = _optionsForTab(tabIndex);
                  if (options.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无水印',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = _selectedIds.contains(option.id);
                      return _WatermarkFilterTile(
                        option: option,
                        selected: selected,
                        lastUsedLabel: _formatLastUsed(option.lastUsedAt),
                        onTap: () => _toggleOption(option.id),
                        preview: option.kind == WatermarkFilterKind.none
                            ? const _NoWatermarkPreview()
                            : WatermarkTemplateView(
                                templateId: option.templateId ?? 'classic',
                                now: sampleNow,
                                address: sampleAddress,
                                weatherText: '晴',
                                temperatureText: '22',
                                showCoordinate: false,
                                compact: true,
                              ),
                      );
                    },
                  );
                }),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatermarkFilterTile extends StatelessWidget {
  const _WatermarkFilterTile({
    required this.option,
    required this.selected,
    required this.lastUsedLabel,
    required this.onTap,
    required this.preview,
  });

  final WatermarkFilterOption option;
  final bool selected;
  final String lastUsedLabel;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: option.kind == WatermarkFilterKind.none
                    ? Colors.white
                    : const Color(0xFF4A4A4A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              alignment: option.kind == WatermarkFilterKind.none
                  ? Alignment.center
                  : Alignment.bottomLeft,
              padding: option.kind == WatermarkFilterKind.none
                  ? null
                  : const EdgeInsets.all(8),
              child: option.kind == WatermarkFilterKind.none
                  ? preview
                  : FittedBox(
                      alignment: Alignment.bottomLeft,
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: preview,
                      ),
                    ),
            ),
          ),
          if (lastUsedLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              lastUsedLabel,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? const Color(0xFF1677FF) : Colors.grey.shade400,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _NoWatermarkPreview extends StatelessWidget {
  const _NoWatermarkPreview();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          '无水印',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
