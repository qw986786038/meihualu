import 'package:flutter/material.dart';

const String kDefaultWatermarkTemplateId = 'classic';
const String kWatermarkDataTemplateId = 'templateId';
const String kWatermarkDataShowAddress = 'showAddress';
const String kWatermarkDataShowCoordinate = 'showCoordinate';
const String kWatermarkDataShowWeekday = 'showWeekday';

class WatermarkTemplatePreset {
  const WatermarkTemplatePreset({
    required this.id,
    required this.title,
    required this.badge,
  });

  final String id;
  final String title;
  final String badge;
}

const List<WatermarkTemplatePreset> kWatermarkTemplatePresets = [
  WatermarkTemplatePreset(id: 'classic', title: '经典水印', badge: '现场'),
  WatermarkTemplatePreset(id: 'panel', title: '卡片水印', badge: '记录'),
  WatermarkTemplatePreset(id: 'minimal', title: '极简水印', badge: '定位'),
];

WatermarkTemplatePreset watermarkTemplateById(String? id) {
  for (final preset in kWatermarkTemplatePresets) {
    if (preset.id == id) return preset;
  }
  return kWatermarkTemplatePresets.first;
}

class WatermarkTemplateView extends StatelessWidget {
  const WatermarkTemplateView({
    super.key,
    required this.templateId,
    required this.now,
    required this.address,
    this.coordinateText,
    this.districtText,
    this.poiText,
    this.showAddress = true,
    this.showCoordinate = true,
    this.showWeekday = true,
    this.compact = false,
  });

  final String templateId;
  final DateTime now;
  final String address;
  final String? coordinateText;
  final String? districtText;
  final String? poiText;
  final bool showAddress;
  final bool showCoordinate;
  final bool showWeekday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final preset = watermarkTemplateById(templateId);
    switch (preset.id) {
      case 'panel':
        return _PanelTemplate(
          preset: preset,
          now: now,
          address: address,
          coordinateText: coordinateText,
          districtText: districtText,
          poiText: poiText,
          showAddress: showAddress,
          showCoordinate: showCoordinate,
          showWeekday: showWeekday,
          compact: compact,
        );
      case 'minimal':
        return _MinimalTemplate(
          preset: preset,
          now: now,
          address: address,
          coordinateText: coordinateText,
          districtText: districtText,
          poiText: poiText,
          showAddress: showAddress,
          showCoordinate: showCoordinate,
          showWeekday: showWeekday,
          compact: compact,
        );
      case 'classic':
      default:
        return _ClassicTemplate(
          preset: preset,
          now: now,
          address: address,
          coordinateText: coordinateText,
          districtText: districtText,
          poiText: poiText,
          showAddress: showAddress,
          showCoordinate: showCoordinate,
          showWeekday: showWeekday,
          compact: compact,
        );
    }
  }
}

class _ClassicTemplate extends StatelessWidget {
  const _ClassicTemplate({
    required this.preset,
    required this.now,
    required this.address,
    required this.coordinateText,
    required this.districtText,
    required this.poiText,
    required this.showAddress,
    required this.showCoordinate,
    required this.showWeekday,
    required this.compact,
  });

  final WatermarkTemplatePreset preset;
  final DateTime now;
  final String address;
  final String? coordinateText;
  final String? districtText;
  final String? poiText;
  final bool showAddress;
  final bool showCoordinate;
  final bool showWeekday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final timeStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 22 : 30,
      fontWeight: FontWeight.w700,
      shadows: _textShadows,
    );
    final metaStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 11 : 13,
      shadows: _textShadows,
    );
    final addressStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 12 : 14,
      fontWeight: FontWeight.w500,
      shadows: _textShadows,
    );
    final detailText = _joinParts([districtText, poiText], separator: ' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatHm(now), style: timeStyle),
            Container(
              margin: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
              width: 3,
              height: compact ? 22 : 30,
              color: Colors.amber,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatYmd(now), style: metaStyle),
                if (showWeekday) Text(_weekdayLabel(now), style: metaStyle),
              ],
            ),
          ],
        ),
        if (showAddress) ...[
          SizedBox(height: compact ? 3 : 4),
          Text(address, style: addressStyle),
        ],
        if (detailText != null) ...[
          SizedBox(height: compact ? 1 : 2),
          Text(detailText, style: metaStyle),
        ],
        if (showCoordinate && coordinateText != null) ...[
          SizedBox(height: compact ? 1 : 2),
          Text(coordinateText!, style: metaStyle),
        ],
      ],
    );
  }
}

class _PanelTemplate extends StatelessWidget {
  const _PanelTemplate({
    required this.preset,
    required this.now,
    required this.address,
    required this.coordinateText,
    required this.districtText,
    required this.poiText,
    required this.showAddress,
    required this.showCoordinate,
    required this.showWeekday,
    required this.compact,
  });

  final WatermarkTemplatePreset preset;
  final DateTime now;
  final String address;
  final String? coordinateText;
  final String? districtText;
  final String? poiText;
  final bool showAddress;
  final bool showCoordinate;
  final bool showWeekday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.92),
      fontSize: compact ? 10 : 12,
      fontWeight: FontWeight.w600,
    );
    final timeStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 20 : 28,
      fontWeight: FontWeight.w800,
    );
    final metaStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.92),
      fontSize: compact ? 10 : 12,
    );
    final bodyStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 11 : 13,
      height: 1.2,
    );
    final detailText = _joinParts([districtText, poiText], separator: ' · ');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 7,
                  vertical: compact ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  preset.badge,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(_formatYmd(now), style: titleStyle),
              if (showWeekday) ...[
                SizedBox(width: compact ? 4 : 6),
                Text(_weekdayLabel(now), style: titleStyle),
              ],
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(_formatHm(now), style: timeStyle),
          if (showAddress) ...[
            SizedBox(height: compact ? 4 : 6),
            Text(address, style: bodyStyle),
          ],
          if (detailText != null) ...[
            SizedBox(height: compact ? 2 : 4),
            Text(detailText, style: metaStyle),
          ],
          if (showCoordinate && coordinateText != null) ...[
            SizedBox(height: compact ? 2 : 4),
            Text(coordinateText!, style: metaStyle),
          ],
        ],
      ),
    );
  }
}

class _MinimalTemplate extends StatelessWidget {
  const _MinimalTemplate({
    required this.preset,
    required this.now,
    required this.address,
    required this.coordinateText,
    required this.districtText,
    required this.poiText,
    required this.showAddress,
    required this.showCoordinate,
    required this.showWeekday,
    required this.compact,
  });

  final WatermarkTemplatePreset preset;
  final DateTime now;
  final String address;
  final String? coordinateText;
  final String? districtText;
  final String? poiText;
  final bool showAddress;
  final bool showCoordinate;
  final bool showWeekday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 10 : 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final timeStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 18 : 24,
      fontWeight: FontWeight.w800,
    );
    final bodyStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.96),
      fontSize: compact ? 11 : 13,
      height: 1.2,
    );
    final metaStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.86),
      fontSize: compact ? 10 : 11,
    );
    final detailText = _joinParts([districtText, poiText], separator: ' · ');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.place_rounded,
                color: Colors.amber,
                size: compact ? 12 : 14,
              ),
              SizedBox(width: compact ? 4 : 6),
              Text(preset.title, style: titleStyle),
              SizedBox(width: compact ? 6 : 8),
              Text(
                showWeekday
                    ? '${_formatYmd(now)} ${_weekdayLabel(now)}'
                    : _formatYmd(now),
                style: metaStyle,
              ),
            ],
          ),
          SizedBox(height: compact ? 5 : 6),
          Text(_formatHm(now), style: timeStyle),
          if (showAddress) ...[
            SizedBox(height: compact ? 3 : 4),
            Text(address, style: bodyStyle),
          ],
          if (detailText != null) ...[
            SizedBox(height: compact ? 1 : 2),
            Text(detailText, style: metaStyle),
          ],
          if (showCoordinate && coordinateText != null) ...[
            SizedBox(height: compact ? 1 : 2),
            Text(coordinateText!, style: metaStyle),
          ],
        ],
      ),
    );
  }
}

String _formatHm(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _formatYmd(DateTime dt) {
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _weekdayLabel(DateTime dt) {
  const labels = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
  return labels[dt.weekday - 1];
}

String? _joinParts(Iterable<String?> values, {String separator = ' '}) {
  final parts = <String>[];
  for (final value in values) {
    final text = value?.trim();
    if (text == null || text.isEmpty) continue;
    if (parts.contains(text)) continue;
    parts.add(text);
  }
  if (parts.isEmpty) return null;
  return parts.join(separator);
}

const List<Shadow> _textShadows = [
  Shadow(color: Color(0x73000000), blurRadius: 8, offset: Offset(0, 1)),
];
