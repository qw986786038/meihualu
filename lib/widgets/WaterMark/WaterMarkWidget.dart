import 'dart:async';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/utils/watermark_coordinate_formatter.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_settings_sheet.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

class WaterMarkWidget extends StatefulWidget {
  const WaterMarkWidget({
    super.key,
    required this.data,
    required this.updateData,
  });

  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> updateData;

  @override
  State<WaterMarkWidget> createState() => _WaterMarkWidgetState();
}

class _WaterMarkWidgetState extends State<WaterMarkWidget> {
  final Rx<DateTime> _now = DateTime.now().obs;
  final AMapLocationService _locationService = Get.find<AMapLocationService>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitNowData(_now.value);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _resolveAddress() {
    final selected = watermarkString(widget.data, kWatermarkDataSelectedAddress);
    if (selected.isNotEmpty) return selected;
    if (_locationService.watermarkAddress.value.isNotEmpty) {
      return _locationService.watermarkAddress.value;
    }
    return (widget.data['address'] ?? '定位中...').toString();
  }

  String? _formatCoordinate(double? latitude, double? longitude) {
    if (!watermarkBool(widget.data, kWatermarkDataShowCoordinate, fallback: true)) {
      return null;
    }
    return WatermarkCoordinateFormatter.format(
      latitude,
      longitude,
      watermarkString(
        widget.data,
        kWatermarkDataCoordinateFormat,
        fallback: kCoordinateFormatDecimal,
      ),
    );
  }

  String? _formatAltitude(double? altitude) {
    if (!watermarkBool(widget.data, kWatermarkDataShowAltitude, fallback: false)) {
      return null;
    }
    return WatermarkCoordinateFormatter.formatAltitude(altitude);
  }

  Future<void> _openSettingsSheet(String templateId) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return WatermarkSettingsSheet(
          data: widget.data,
          updateData: widget.updateData,
          templateId: templateId,
          locationService: _locationService,
          initialNow: _now.value,
        );
      },
    );
  }

  void _emitNowData(DateTime dt) {
    final next = Map<String, dynamic>.from(widget.data);
    next['time'] =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    next['date'] =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    next['weekday'] = const [
      '星期一',
      '星期二',
      '星期三',
      '星期四',
      '星期五',
      '星期六',
      '星期日',
    ][dt.weekday - 1];
    widget.updateData(next);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final now = _now.value;
      final location = _locationService.latestLocation.value;
      final address = _resolveAddress();
      final coordinateText = _formatCoordinate(
        location?.latitude,
        location?.longitude,
      );
      final altitudeText = _formatAltitude(location?.altitude);
      final templateId = watermarkString(
        widget.data,
        kWatermarkDataTemplateId,
        fallback: kDefaultWatermarkTemplateId,
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSettingsSheet(templateId),
        child: WatermarkTemplateView(
          key: ValueKey(
            '${watermarkString(widget.data, kWatermarkDataCustomTitle)}|'
            '${watermarkBool(widget.data, kWatermarkDataShowCustomTitle, fallback: false)}|'
            '${watermarkString(widget.data, kWatermarkDataQuickLabelText, fallback: '现场拍摄')}|'
            '${watermarkBool(widget.data, kWatermarkDataShowQuickLabel, fallback: false)}',
          ),
          templateId: templateId,
          now: now,
          address: address,
          weatherText: _trimToNull(_locationService.watermarkWeather.value),
          temperatureText:
              _trimToNull(_locationService.watermarkTemperature.value),
          coordinateText: coordinateText,
          altitudeText: altitudeText,
          showAddress: true,
          showCoordinate: watermarkBool(
            widget.data,
            kWatermarkDataShowCoordinate,
            fallback: true,
          ),
          showWeekday: watermarkBool(
            widget.data,
            kWatermarkDataShowWeekday,
            fallback: true,
          ),
          showLogo: watermarkBool(widget.data, kWatermarkDataShowLogo, fallback: false),
          logoPath: watermarkString(widget.data, kWatermarkDataLogoPath),
          showQuickLabel: watermarkBool(
            widget.data,
            kWatermarkDataShowQuickLabel,
            fallback: false,
          ),
          quickLabelText: watermarkString(
            widget.data,
            kWatermarkDataQuickLabelText,
            fallback: '现场拍摄',
          ),
          quickLabelBorderColor: Color(
            watermarkColorInt(
              widget.data,
              kWatermarkDataQuickLabelBorderColor,
              fallback: 0xFFFFC107,
            ),
          ),
          showCustomTitle: watermarkBool(
            widget.data,
            kWatermarkDataShowCustomTitle,
            fallback: false,
          ),
          customTitle: watermarkString(widget.data, kWatermarkDataCustomTitle),
          showAltitude: watermarkBool(
            widget.data,
            kWatermarkDataShowAltitude,
            fallback: false,
          ),
        ),
      );
    });
  }

  String? _trimToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
