import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:watermark_camera/pages/camera/camera_map_controller.dart';
import 'package:watermark_camera/services/amap_location_service.dart';

class AMapTileHelper {
  const AMapTileHelper._();

  static const int tileSize = 256;

  static double lonToTileXExact(double lon, int zoom) {
    return (lon + 180) / 360 * (1 << zoom);
  }

  static double latToTileYExact(double lat, int zoom) {
    final latRad = lat * math.pi / 180;
    return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        (1 << zoom);
  }

  /// 标准地图
  static String standardTileUrl({
    required int x,
    required int y,
    required int zoom,
  }) {
    final subdomain = ((x + y) % 4) + 1;
    return 'https://webrd0$subdomain.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x=$x&y=$y&z=$zoom';
  }

  /// 卫星影像
  static String satelliteTileUrl({
    required int x,
    required int y,
    required int zoom,
  }) {
    final subdomain = ((x + y) % 4) + 1;
    return 'https://webst0$subdomain.is.autonavi.com/appmaptile?style=6&x=$x&y=$y&z=$zoom';
  }

  /// 卫星标注层（与卫星影像同域，style=8 为透明路网标注）
  static String satelliteLabelTileUrl({
    required int x,
    required int y,
    required int zoom,
  }) {
    final subdomain = ((x + y) % 4) + 1;
    return 'https://webst0$subdomain.is.autonavi.com/appmaptile?style=8&x=$x&y=$y&z=$zoom';
  }

  static Offset latLngToPixel({
    required double latitude,
    required double longitude,
    required int zoom,
    required double centerLatitude,
    required double centerLongitude,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final centerX = lonToTileXExact(centerLongitude, zoom);
    final centerY = latToTileYExact(centerLatitude, zoom);
    final pointX = lonToTileXExact(longitude, zoom);
    final pointY = latToTileYExact(latitude, zoom);
    return Offset(
      canvasWidth / 2 + (pointX - centerX) * tileSize,
      canvasHeight / 2 + (pointY - centerY) * tileSize,
    );
  }
}

/// 填满父容器，内部固定分辨率渲染，拖动展示大小时只缩放不重载
class CameraMapImage extends StatefulWidget {
  const CameraMapImage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.mapType,
    this.trackPoints,
  });

  final double latitude;
  final double longitude;
  final int zoom;
  final CameraMapType mapType;
  final List<MapTrackPoint>? trackPoints;

  static const Size baseRenderSize = Size.square(512);

  /// zoom 偏低时通过内容放大保证建筑文字可读
  static const double contentMagnification = 2.8;

  @override
  State<CameraMapImage> createState() => _CameraMapImageState();
}

class _CameraMapImageState extends State<CameraMapImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            child: Transform.scale(
              scale: CameraMapImage.contentMagnification,
              child: SizedBox(
                width: CameraMapImage.baseRenderSize.width,
                height: CameraMapImage.baseRenderSize.height,
                child: _TileMap(
                  width: CameraMapImage.baseRenderSize.width,
                  height: CameraMapImage.baseRenderSize.height,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  zoom: widget.zoom,
                  mapType: widget.mapType,
                  trackPoints: widget.trackPoints,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TileMap extends StatelessWidget {
  const _TileMap({
    required this.width,
    required this.height,
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.mapType,
    this.trackPoints,
  });

  final double width;
  final double height;
  final double latitude;
  final double longitude;
  final int zoom;
  final CameraMapType mapType;
  final List<MapTrackPoint>? trackPoints;

  @override
  Widget build(BuildContext context) {
    final z = zoom.clamp(3, 20);
    final centerX = AMapTileHelper.lonToTileXExact(longitude, z);
    final centerY = AMapTileHelper.latToTileYExact(latitude, z);
    final centerTileX = centerX.floor();
    final centerTileY = centerY.floor();
    final pixelX = (centerX - centerTileX) * AMapTileHelper.tileSize;
    final pixelY = (centerY - centerTileY) * AMapTileHelper.tileSize;
    final offsetX = width / 2 - pixelX;
    final offsetY = height / 2 - pixelY;
    final tileRadius = math.max(
      (width / AMapTileHelper.tileSize / 2).ceil() + 1,
      (height / AMapTileHelper.tileSize / 2).ceil() + 1,
    );
    final satellite = mapType == CameraMapType.satellite;

    return ColoredBox(
      color: const Color(0xFFE8EEF5),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (var dx = -tileRadius; dx <= tileRadius; dx++)
            for (var dy = -tileRadius; dy <= tileRadius; dy++)
              Positioned(
                left: offsetX + dx * AMapTileHelper.tileSize,
                top: offsetY + dy * AMapTileHelper.tileSize,
                child: _MapTileImage(
                  url: satellite
                      ? AMapTileHelper.satelliteTileUrl(
                          x: centerTileX + dx,
                          y: centerTileY + dy,
                          zoom: z,
                        )
                      : AMapTileHelper.standardTileUrl(
                          x: centerTileX + dx,
                          y: centerTileY + dy,
                          zoom: z,
                        ),
                  cacheKey:
                      '${satellite ? 'sat' : 'std'}-$z-${centerTileX + dx}-${centerTileY + dy}',
                ),
              ),
          if (satellite)
            for (var dx = -tileRadius; dx <= tileRadius; dx++)
              for (var dy = -tileRadius; dy <= tileRadius; dy++)
                Positioned(
                  left: offsetX + dx * AMapTileHelper.tileSize,
                  top: offsetY + dy * AMapTileHelper.tileSize,
                  child: _MapTileImage(
                    url: AMapTileHelper.satelliteLabelTileUrl(
                      x: centerTileX + dx,
                      y: centerTileY + dy,
                      zoom: z,
                    ),
                    cacheKey:
                        'sat-label-$z-${centerTileX + dx}-${centerTileY + dy}',
                    ignoreError: true,
                  ),
                ),
          if (trackPoints != null && trackPoints!.length >= 2)
            CustomPaint(
              size: Size(width, height),
              painter: _TrackPainter(
                points: trackPoints!,
                centerLatitude: latitude,
                centerLongitude: longitude,
                zoom: z,
                canvasWidth: width,
                canvasHeight: height,
              ),
            ),
        ],
      ),
    );
  }
}

class _MapTileImage extends StatelessWidget {
  const _MapTileImage({
    required this.url,
    required this.cacheKey,
    this.ignoreError = false,
  });

  final String url;
  final String cacheKey;
  final bool ignoreError;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      key: ValueKey<String>(cacheKey),
      width: AMapTileHelper.tileSize.toDouble(),
      height: AMapTileHelper.tileSize.toDouble(),
      fit: BoxFit.fill,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) {
        if (ignoreError) {
          return SizedBox(
            width: AMapTileHelper.tileSize.toDouble(),
            height: AMapTileHelper.tileSize.toDouble(),
          );
        }
        return ColoredBox(
          color: const Color(0xFFE8EEF5),
          child: SizedBox(
            width: AMapTileHelper.tileSize.toDouble(),
            height: AMapTileHelper.tileSize.toDouble(),
            child: Icon(Icons.map_outlined, color: Colors.grey.shade400, size: 24),
          ),
        );
      },
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.points,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.zoom,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  final List<MapTrackPoint> points;
  final double centerLatitude;
  final double centerLongitude;
  final int zoom;
  final double canvasWidth;
  final double canvasHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final offset = AMapTileHelper.latLngToPixel(
        latitude: point.latitude,
        longitude: point.longitude,
        zoom: zoom,
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
      );
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0088FF)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.centerLatitude != centerLatitude ||
        oldDelegate.centerLongitude != centerLongitude ||
        oldDelegate.zoom != zoom;
  }
}

class MapLocationPin extends StatelessWidget {
  const MapLocationPin({super.key, required this.size});

  final double size;

  static const Color pinColor = Color(0xFF2F7CF6);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -size * 0.42),
      child: Icon(
        Icons.location_on,
        color: pinColor,
        size: size,
        shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
      ),
    );
  }
}

/// 设置弹窗中的地图类型示意缩略图
class MapTypePlaceholder extends StatelessWidget {
  const MapTypePlaceholder({super.key, required this.satellite});

  final bool satellite;

  @override
  Widget build(BuildContext context) {
    if (satellite) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3D6B35),
              Color(0xFF6B5B45),
              Color(0xFF2A4A6B),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.satellite_alt_outlined,
            size: 40,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFE8EDF3),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StandardMapLinesPainter()),
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 40,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardMapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB0C4DE)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.45),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.45, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.6, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
