import 'package:flutter/material.dart';
import 'package:watermark_camera/models/space_media_viewer_item.dart';
import 'package:watermark_camera/pages/space/space_media_viewer_page.dart';

Future<void> openSpaceMediaViewer(
  BuildContext context, {
  required List<SpaceMediaViewerItem> items,
  required int initialIndex,
}) async {
  if (items.isEmpty) return;

  final safeIndex = initialIndex.clamp(0, items.length - 1);
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => SpaceMediaViewerPage(
        items: items,
        initialIndex: safeIndex,
      ),
    ),
  );
}
