import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/pages/camera/camera_map_controller.dart';
import 'package:watermark_camera/widgets/camera_map_image.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

Future<void> showCameraMapSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black26,
    builder: (_) => const CameraMapSettingsSheet(),
  );
}

class CameraMapSettingsSheet extends StatelessWidget {
  const CameraMapSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<CameraMapController>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, mapController),
            const SizedBox(height: 12),
            _buildMapTypeSection(mapController),
            const SizedBox(height: 8),
            _buildSwitchRow(
              title: '拍照方向',
              valueListenable: mapController.showShootingDirection,
              onChanged: mapController.setShootingDirectionEnabled,
            ),
            _buildSwitchRow(
              title: '实时轨迹',
              valueListenable: mapController.showRealTimeTrack,
              onChanged: (value) {
                if (value) {
                  mapController.setRealTimeTrackEnabled(true);
                } else {
                  mapController.setRealTimeTrackEnabled(false);
                  mapController.clearTrack();
                }
              },
            ),
            _buildSliderRow(
              title: '比例尺',
              valueListenable: mapController.scaleLevel,
              divisions: 6,
              onChanged: mapController.setScaleLevel,
              labelBuilder: (_) => 'Z${mapController.mapZoom}',
            ),
            _buildSliderRow(
              title: '展示大小',
              valueListenable: mapController.displaySize,
              onChanged: (value) => mapController.displaySize.value = value,
              labelBuilder: (value) => '${(value * 100).round()}%',
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '使用反馈',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CameraMapController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          const Text(
            '地图设置',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Obx(
            () => Row(
              children: [
                const Text('地图', style: TextStyle(fontSize: 15)),
                Switch(
                  value: controller.mapEnabled.value,
                  activeTrackColor: const Color(0xFF4CAF50),
                  onChanged: (value) {
                    controller.mapEnabled.value = value;
                    if (!value) {
                      controller.setRealTimeTrackEnabled(false);
                      controller.setShootingDirectionEnabled(false);
                      controller.clearTrack();
                    }
                  },
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '完成',
              style: TextStyle(
                color: _kPrimaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeSection(CameraMapController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _MapTypeTile(
                label: '标准地图',
                selected: controller.mapType.value == CameraMapType.standard,
                satellite: false,
                onTap: () => controller.mapType.value = CameraMapType.standard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MapTypeTile(
                label: '卫星地图',
                selected: controller.mapType.value == CameraMapType.satellite,
                satellite: true,
                onTap: () => controller.mapType.value = CameraMapType.satellite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required RxBool valueListenable,
    required ValueChanged<bool> onChanged,
  }) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Switch(
              value: valueListenable.value,
              activeTrackColor: const Color(0xFF4CAF50),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String title,
    required RxDouble valueListenable,
    required ValueChanged<double> onChanged,
    String Function(double value)? labelBuilder,
    int? divisions,
  }) {
    return Obx(
      () {
        final value = valueListenable.value.clamp(0.0, 1.0);
        final trailing = labelBuilder?.call(value);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(title, style: const TextStyle(fontSize: 15)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: _kPrimaryBlue,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: _kPrimaryBlue,
                  ),
                  child: Slider(
                    value: value,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ),
              if (trailing != null)
                SizedBox(
                  width: 44,
                  child: Text(
                    trailing,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MapTypeTile extends StatelessWidget {
  const _MapTypeTile({
    required this.label,
    required this.selected,
    required this.satellite,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool satellite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? _kPrimaryBlue : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: MapTypePlaceholder(satellite: satellite),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? _kPrimaryBlue : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
