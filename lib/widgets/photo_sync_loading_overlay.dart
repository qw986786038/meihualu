import 'package:flutter/material.dart';

class PhotoSyncLoadingOverlay extends StatelessWidget {
  const PhotoSyncLoadingOverlay({
    super.key,
    required this.visible,
    required this.message,
  });

  final bool visible;
  final String message;

  static const _primaryBlue = Color(0xFF1677FF);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: visible
            ? Container(
                color: Colors.black.withValues(alpha: 0.42),
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 52),
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: _primaryBlue.withValues(alpha: 0.25),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: _primaryBlue,
                              ),
                            ),
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 26,
                              color: _primaryBlue.withValues(alpha: 0.95),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '正在同步',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
