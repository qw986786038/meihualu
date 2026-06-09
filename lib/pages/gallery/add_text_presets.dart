const String kOverlayTextPresetId = 'presetId';
const String kOverlayTextContent = 'text';
const String kOverlayTextRotation = 'rotation';
const String kOverlayTextStyle = 'style';

enum AddTextStyle {
  label,
  annotation,
  outline,
  background,
  dimension,
  artistic,
  location,
  clockIn,
  problem,
  frame,
  hazard,
  banner,
  badgeBefore,
  badgeAfter,
  stampPass,
  stampFail,
  stampRecord,
  sprint,
  notebook,
}

class AddTextPreset {
  const AddTextPreset({
    required this.id,
    required this.name,
    required this.defaultText,
    required this.style,
    this.limitedFree = false,
  });

  final String id;
  final String name;
  final String defaultText;
  final AddTextStyle style;
  final bool limitedFree;

  Map<String, dynamic> toOverlayData({String? text}) {
    return {
      kOverlayTextPresetId: id,
      kOverlayTextContent: text ?? defaultText,
      kOverlayTextRotation: 0.0,
      kOverlayTextStyle: style.name,
    };
  }
}

const List<AddTextPreset> kAddTextPresets = [
  AddTextPreset(
    id: 'label',
    name: '标签',
    defaultText: '标签',
    style: AddTextStyle.label,
  ),
  AddTextPreset(
    id: 'annotation',
    name: '标注',
    defaultText: '标注',
    style: AddTextStyle.annotation,
  ),
  AddTextPreset(
    id: 'outline',
    name: '描边文字',
    defaultText: '描边文字',
    style: AddTextStyle.outline,
  ),
  AddTextPreset(
    id: 'background',
    name: '背景文字',
    defaultText: '背景文字',
    style: AddTextStyle.background,
  ),
  AddTextPreset(
    id: 'dimension',
    name: '尺寸',
    defaultText: '尺寸',
    style: AddTextStyle.dimension,
  ),
  AddTextPreset(
    id: 'artistic',
    name: '艺术字',
    defaultText: '艺术字',
    style: AddTextStyle.artistic,
    limitedFree: true,
  ),
  AddTextPreset(
    id: 'location',
    name: '位置描述',
    defaultText: '位置描述',
    style: AddTextStyle.location,
  ),
  AddTextPreset(
    id: 'clock_in',
    name: '上班打卡',
    defaultText: '上班打卡',
    style: AddTextStyle.clockIn,
  ),
  AddTextPreset(
    id: 'problem',
    name: '问题描写',
    defaultText: '问题描写',
    style: AddTextStyle.problem,
  ),
  AddTextPreset(
    id: 'construction_content',
    name: '施工内容',
    defaultText: '施工内容',
    style: AddTextStyle.frame,
  ),
  AddTextPreset(
    id: 'construction_area',
    name: '施工区域',
    defaultText: '施工区域',
    style: AddTextStyle.frame,
  ),
  AddTextPreset(
    id: 'under_construction',
    name: '施工中',
    defaultText: '施工中',
    style: AddTextStyle.hazard,
    limitedFree: true,
  ),
  AddTextPreset(
    id: 'inspection',
    name: '巡检巡查',
    defaultText: '巡检巡查',
    style: AddTextStyle.banner,
  ),
  AddTextPreset(
    id: 'before_fix',
    name: '整改前',
    defaultText: '整改前',
    style: AddTextStyle.badgeBefore,
  ),
  AddTextPreset(
    id: 'after_fix',
    name: '整改后',
    defaultText: '整改后',
    style: AddTextStyle.badgeAfter,
  ),
  AddTextPreset(
    id: 'passed',
    name: '合格',
    defaultText: '合格',
    style: AddTextStyle.stampPass,
  ),
  AddTextPreset(
    id: 'acceptance',
    name: '验收记录',
    defaultText: '验收记录',
    style: AddTextStyle.stampRecord,
  ),
  AddTextPreset(
    id: 'failed',
    name: '不合格',
    defaultText: '不合格',
    style: AddTextStyle.stampFail,
  ),
  AddTextPreset(
    id: 'sprint',
    name: '业绩冲刺',
    defaultText: '业绩冲刺',
    style: AddTextStyle.sprint,
  ),
  AddTextPreset(
    id: 'self_check',
    name: '内部自检',
    defaultText: '内部自检',
    style: AddTextStyle.stampFail,
  ),
  AddTextPreset(
    id: 'normal',
    name: '无异常',
    defaultText: '无异常',
    style: AddTextStyle.notebook,
  ),
];

AddTextStyle addTextStyleFromData(Map<String, dynamic> data) {
  final raw = data[kOverlayTextStyle]?.toString();
  return AddTextStyle.values.firstWhere(
    (style) => style.name == raw,
    orElse: () => AddTextStyle.background,
  );
}

String overlayTextFromData(Map<String, dynamic> data) {
  return (data[kOverlayTextContent] ?? '文字').toString();
}

double overlayRotationFromData(Map<String, dynamic> data) {
  final raw = data[kOverlayTextRotation];
  if (raw is num) return raw.toDouble();
  return 0;
}
