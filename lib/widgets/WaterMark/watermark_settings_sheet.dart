import 'dart:async';

import 'package:flutter/material.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

class WatermarkSettingsSheet extends StatefulWidget {
  const WatermarkSettingsSheet({
    super.key,
    required this.templateId,
    required this.templateTitle,
    required this.initialNow,
    required this.address,
    this.coordinateText,
    this.districtText,
    this.poiText,
    required this.initialShowAddress,
    required this.initialShowCoordinate,
    required this.initialShowWeekday,
    required this.onShowAddressChanged,
    required this.onShowCoordinateChanged,
    required this.onShowWeekdayChanged,
  });

  final String templateId;
  final String templateTitle;
  final DateTime initialNow;
  final String address;
  final String? coordinateText;
  final String? districtText;
  final String? poiText;
  final bool initialShowAddress;
  final bool initialShowCoordinate;
  final bool initialShowWeekday;
  final ValueChanged<bool> onShowAddressChanged;
  final ValueChanged<bool> onShowCoordinateChanged;
  final ValueChanged<bool> onShowWeekdayChanged;

  @override
  State<WatermarkSettingsSheet> createState() => _WatermarkSettingsSheetState();
}

class _WatermarkSettingsSheetState extends State<WatermarkSettingsSheet> {
  late bool _showAddress = widget.initialShowAddress;
  late bool _showCoordinate = widget.initialShowCoordinate;
  late bool _showWeekday = widget.initialShowWeekday;
  late DateTime _now = widget.initialNow;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '水印设置',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '当前模板：${widget.templateTitle}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '当前效果',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _SettingsPreviewCard(
              child: WatermarkTemplateView(
                templateId: widget.templateId,
                now: _now,
                address: widget.address,
                coordinateText: widget.coordinateText,
                districtText: widget.districtText,
                poiText: widget.poiText,
                showAddress: _showAddress,
                showCoordinate: _showCoordinate,
                showWeekday: _showWeekday,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '字段显示',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _SettingSwitchTile(
              label: '显示地址',
              value: _showAddress,
              onChanged: (value) {
                setState(() => _showAddress = value);
                widget.onShowAddressChanged(value);
              },
            ),
            _SettingSwitchTile(
              label: '显示经纬度',
              value: _showCoordinate,
              onChanged: (value) {
                setState(() => _showCoordinate = value);
                widget.onShowCoordinateChanged(value);
              },
            ),
            _SettingSwitchTile(
              label: '显示星期',
              value: _showWeekday,
              onChanged: (value) {
                setState(() => _showWeekday = value);
                widget.onShowWeekdayChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPreviewCard extends StatelessWidget {
  const _SettingsPreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: FittedBox(
          alignment: Alignment.bottomLeft,
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

String watermarkTemplateTitle(String? templateId) {
  return watermarkTemplateById(templateId).title;
}
