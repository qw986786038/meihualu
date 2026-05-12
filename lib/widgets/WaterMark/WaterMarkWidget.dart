import 'dart:async';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
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
      final now = DateTime.now();
      _emitNowData(now);
      _now.value = now;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? _formatCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    return '经纬度 ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  String? _trimToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<void> _openSettingsSheet(String templateId) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return WatermarkSettingsSheet(
          templateId: templateId,
          templateTitle: watermarkTemplateTitle(templateId),
          initialNow: _now.value,
          address: _locationService.watermarkAddress.value.isEmpty
              ? (widget.data['address'] ?? '定位中...').toString()
              : _locationService.watermarkAddress.value,
          coordinateText: _formatCoordinate(
            _locationService.latestLocation.value?.latitude,
            _locationService.latestLocation.value?.longitude,
          ),
          districtText: _trimToNull(
            _locationService.latestLocation.value?.district,
          ),
          poiText: _trimToNull(_locationService.latestLocation.value?.poiName),
          initialShowAddress:
              (widget.data[kWatermarkDataShowAddress] as bool?) ?? true,
          initialShowCoordinate:
              (widget.data[kWatermarkDataShowCoordinate] as bool?) ?? true,
          initialShowWeekday:
              (widget.data[kWatermarkDataShowWeekday] as bool?) ?? true,
          onShowAddressChanged: (value) {
            final next = Map<String, dynamic>.from(widget.data);
            next[kWatermarkDataShowAddress] = value;
            widget.updateData(next);
          },
          onShowCoordinateChanged: (value) {
            final next = Map<String, dynamic>.from(widget.data);
            next[kWatermarkDataShowCoordinate] = value;
            widget.updateData(next);
          },
          onShowWeekdayChanged: (value) {
            final next = Map<String, dynamic>.from(widget.data);
            next[kWatermarkDataShowWeekday] = value;
            widget.updateData(next);
          },
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
      final address = _locationService.watermarkAddress.value.isEmpty
          ? (widget.data['address'] ?? '定位中...').toString()
          : _locationService.watermarkAddress.value;
      final coordinateText = _formatCoordinate(
        location?.latitude,
        location?.longitude,
      );
      final templateId =
          (widget.data[kWatermarkDataTemplateId] ?? kDefaultWatermarkTemplateId)
              .toString();
      final showAddress =
          (widget.data[kWatermarkDataShowAddress] as bool?) ?? true;
      final showCoordinate =
          (widget.data[kWatermarkDataShowCoordinate] as bool?) ?? true;
      final showWeekday =
          (widget.data[kWatermarkDataShowWeekday] as bool?) ?? true;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSettingsSheet(templateId),
        child: WatermarkTemplateView(
          templateId: templateId,
          now: now,
          address: address,
          coordinateText: coordinateText,
          districtText: _trimToNull(location?.district),
          poiText: _trimToNull(location?.poiName),
          showAddress: showAddress,
          showCoordinate: showCoordinate,
          showWeekday: showWeekday,
        ),
      );
    });
  }
}
