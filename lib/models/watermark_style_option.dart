enum WatermarkStyleType {
  timeLocationWeather,
  custom,
  engineering,
  attendance,
  stopwatch,
  patrol,
  property,
  licensePlate,
  brand,
  epidemic,
  diary,
  onsite,
}

class WatermarkStyleOption {
  const WatermarkStyleOption({
    required this.id,
    required this.title,
    required this.type,
  });

  final String id;
  final String title;
  final WatermarkStyleType type;
}

const kWatermarkStyleOptions = [
  WatermarkStyleOption(
    id: 'time_location_weather',
    title: '时间地点天气',
    type: WatermarkStyleType.timeLocationWeather,
  ),
  WatermarkStyleOption(
    id: 'custom',
    title: '自定义水印',
    type: WatermarkStyleType.custom,
  ),
  WatermarkStyleOption(
    id: 'engineering',
    title: '工程水印',
    type: WatermarkStyleType.engineering,
  ),
  WatermarkStyleOption(
    id: 'attendance',
    title: '考勤打卡',
    type: WatermarkStyleType.attendance,
  ),
  WatermarkStyleOption(
    id: 'stopwatch',
    title: '秒表水印',
    type: WatermarkStyleType.stopwatch,
  ),
  WatermarkStyleOption(
    id: 'patrol',
    title: '执勤巡逻',
    type: WatermarkStyleType.patrol,
  ),
  WatermarkStyleOption(
    id: 'property',
    title: '物业水印',
    type: WatermarkStyleType.property,
  ),
  WatermarkStyleOption(
    id: 'license_plate',
    title: '自动识别车牌号',
    type: WatermarkStyleType.licensePlate,
  ),
  WatermarkStyleOption(
    id: 'brand',
    title: '品牌水印',
    type: WatermarkStyleType.brand,
  ),
  WatermarkStyleOption(
    id: 'epidemic',
    title: '疫情防控水印',
    type: WatermarkStyleType.epidemic,
  ),
  WatermarkStyleOption(
    id: 'diary',
    title: '民情日记',
    type: WatermarkStyleType.diary,
  ),
  WatermarkStyleOption(
    id: 'onsite',
    title: '现场拍照',
    type: WatermarkStyleType.onsite,
  ),
];
