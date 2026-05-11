import 'package:flutter/material.dart';

class GalleryPreviewButton extends StatelessWidget {
  const GalleryPreviewButton({
    super.key,
    required this.onTap,
    this.previewImage,
    this.width = 60,
    this.height = 60,
  });

  final GestureTapCallback? onTap;
  final ImageProvider? previewImage;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: previewImage == null
              ? Container(
                  color: Colors.grey.shade600,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.photo,
                    size: 24,
                    color: Colors.white70,
                  ),
                )
              : Ink.image(
                  image: previewImage!,
                  fit: BoxFit.cover,
                  child: const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}
