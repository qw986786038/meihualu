const String kWatermarkDataTemplateId = 'templateId';
const String kWatermarkDataShowLogo = 'showLogo';
const String kWatermarkDataLogoPath = 'logoPath';
const String kWatermarkDataShowQuickLabel = 'showQuickLabel';
const String kWatermarkDataQuickLabelText = 'quickLabelText';
const String kWatermarkDataQuickLabelBorderColor = 'quickLabelBorderColor';
const String kWatermarkDataShowAddress = 'showAddress';
const String kWatermarkDataSelectedAddress = 'selectedAddress';
const String kWatermarkDataShowCoordinate = 'showCoordinate';
const String kWatermarkDataCoordinateFormat = 'coordinateFormat';
const String kWatermarkDataShowAltitude = 'showAltitude';
const String kWatermarkDataShowCustomTitle = 'showCustomTitle';
const String kWatermarkDataCustomTitle = 'customTitle';
const String kWatermarkDataShowWeekday = 'showWeekday';

const String kCoordinateFormatDecimal = 'decimal';
const String kCoordinateFormatDm = 'dm';
const String kCoordinateFormatDms = 'dms';

const Map<String, String> kCoordinateFormatLabels = {
  kCoordinateFormatDecimal: '小数度（22.540503, 113.934528）',
  kCoordinateFormatDm: '度分（22°32.43′N, 113°56.07′E）',
  kCoordinateFormatDms: '度分秒（22°32′25.87″N, 113°56′4.30″E）',
};

Map<String, dynamic> createDefaultWatermarkData() {
  return <String, dynamic>{
    kWatermarkDataTemplateId: 'classic',
    kWatermarkDataShowLogo: false,
    kWatermarkDataLogoPath: '',
    kWatermarkDataShowQuickLabel: false,
    kWatermarkDataQuickLabelText: '现场拍摄',
    kWatermarkDataQuickLabelBorderColor: 0xFFFFC107,
    kWatermarkDataShowAddress: true,
    kWatermarkDataSelectedAddress: '',
    kWatermarkDataShowCoordinate: true,
    kWatermarkDataCoordinateFormat: kCoordinateFormatDecimal,
    kWatermarkDataShowAltitude: false,
    kWatermarkDataShowCustomTitle: false,
    kWatermarkDataCustomTitle: '',
    kWatermarkDataShowWeekday: true,
  };
}

bool watermarkBool(
  Map<String, dynamic> data,
  String key, {
  required bool fallback,
}) {
  return (data[key] as bool?) ?? fallback;
}

String watermarkString(
  Map<String, dynamic> data,
  String key, {
  String fallback = '',
}) {
  return (data[key] ?? fallback).toString();
}

int watermarkColorInt(
  Map<String, dynamic> data,
  String key, {
  required int fallback,
}) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}
