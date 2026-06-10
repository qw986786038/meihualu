import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/pages/camera/camera_map_controller.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/widgets/camera_map_image.dart';

class CameraMapOverlay extends StatelessWidget {
  const CameraMapOverlay({
    super.key,
    required this.previewSize,
    required this.onTap,
  });

  final Size previewSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<CameraMapController>();

    return Obx(() {
      if (!mapController.mapEnabled.value) {
        return const SizedBox.shrink();
      }

      final mapSize = mapController.mapSizeForPreview(previewSize.shortestSide);

      return Positioned(
        top: 8,
        right: 8,
        child: GestureDetector(
          onTap: onTap,
          child: _MapFrame(
            width: mapSize.width,
            height: mapSize.height,
            child: const _MapContentLayer(),
          ),
        ),
      );
    });
  }
}

class _MapFrame extends StatelessWidget {
  const _MapFrame({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: child,
      ),
    );
  }
}

/// 与展示大小解耦，拖动大小时不重载瓦片
class _MapContentLayer extends StatelessWidget {
  const _MapContentLayer();

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<CameraMapController>();
    final locationService = Get.find<AMapLocationService>();

    return Obx(() {
      final location = locationService.latestLocation.value;
      final lat = location?.latitude ?? 22.540503;
      final lng = location?.longitude ?? 113.934528;
      final mapType = mapController.mapType.value;
      final zoom = mapController.mapZoom;
      final track = mapController.showRealTimeTrack.value
          ? mapController.trackPoints.toList()
          : null;
      final heading = mapController.headingDegrees.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final pinSize = constraints.maxHeight * 0.38;
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraMapImage(
                latitude: lat,
                longitude: lng,
                zoom: zoom,
                mapType: mapType,
                trackPoints: track,
              ),
              if (mapController.showShootingDirection.value && heading != null)
                Center(
                  child: Transform.rotate(
                    angle: (heading - 45) * math.pi / 180,
                    child: Icon(
                      Icons.navigation,
                      color: Colors.blue.shade700,
                      size: constraints.maxHeight * 0.28,
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              Center(child: MapLocationPin(size: pinSize)),
            ],
          );
        },
      );
    });
  }
}
