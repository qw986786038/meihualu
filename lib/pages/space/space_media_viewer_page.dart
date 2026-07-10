import 'dart:io';

import 'package:flutter/material.dart';
import 'package:watermark_camera/models/space_media_viewer_item.dart';
import 'package:watermark_camera/utils/space_media_downloader.dart';
import 'package:watermark_camera/utils/space_media_image.dart';

class SpaceMediaViewerPage extends StatefulWidget {
  const SpaceMediaViewerPage({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  final List<SpaceMediaViewerItem> items;
  final int initialIndex;

  @override
  State<SpaceMediaViewerPage> createState() => _SpaceMediaViewerPageState();
}

class _SpaceMediaViewerPageState extends State<SpaceMediaViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  SpaceMediaViewerItem get _currentItem => widget.items[_currentIndex];

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature功能开发中，敬请期待')));
  }

  Future<void> _saveCurrentToGallery() async {
    if (_isSaving) return;

    final item = _currentItem;
    final url = item.originalUrl.trim();
    if (url.isEmpty) {
      _showComingSoon('下载');
      return;
    }

    setState(() => _isSaving = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('正在保存到相册...')));

    final success = await SpaceMediaDownloader.downloadToGallery(
      ossUrl: url,
      isVideo: item.isVideo,
      fileName: item.fileName,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(success ? '已保存到相册' : '保存失败，请稍后重试')),
      );
  }

  void _openNavigation() {
    final item = _currentItem;
    if (item.latitude != null && item.longitude != null) {
      _showComingSoon('导航');
      return;
    }
    if (item.location != null && item.location!.trim().isNotEmpty) {
      _showComingSoon('导航');
      return;
    }
    _showComingSoon('导航');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildPageView()),
            _buildThumbnailStrip(),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const Spacer(),
          Text(
            '${_currentIndex + 1}/${widget.items.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.items.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return _MediaPage(item: item);
      },
    );
  }

  Widget _buildThumbnailStrip() {
    if (widget.items.length <= 1) {
      return const SizedBox(height: 12);
    }

    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final selected = index == _currentIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SpaceMediaImage(
                  url: item.previewUrl.isNotEmpty
                      ? item.previewUrl
                      : item.originalUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.wechat,
            iconColor: const Color(0xFF07C160),
            label: '分享',
            onTap: () => _showComingSoon('分享'),
          ),
          _ActionButton(
            icon: Icons.branding_watermark_outlined,
            label: '水印',
            showBadge: true,
            onTap: () => _showComingSoon('水印'),
          ),
          _ActionButton(
            icon: Icons.download_outlined,
            label: '下载',
            onTap: _isSaving ? null : _saveCurrentToGallery,
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: '评论',
            onTap: () => _showComingSoon('评论'),
          ),
          _ActionButton(
            icon: Icons.build_outlined,
            label: '提整改',
            onTap: () => _showComingSoon('提整改'),
          ),
          _ActionButton(
            icon: Icons.location_on_outlined,
            label: '导航',
            onTap: _openNavigation,
          ),
        ],
      ),
    );
  }
}

class _MediaPage extends StatelessWidget {
  const _MediaPage({required this.item});

  final SpaceMediaViewerItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return _VideoPlaceholder(item: item);
    }

    final url = item.originalUrl.trim();
    if (url.isEmpty) {
      return const Center(
        child: Text('无法加载图片', style: TextStyle(color: Colors.white70)),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return SpaceMediaImage(
                url: item.previewUrl,
                fit: BoxFit.contain,
              );
            },
          ),
        ),
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: Image.file(file, fit: BoxFit.contain),
        ),
      );
    }

    return Center(
      child: SpaceMediaImage(url: item.previewUrl, fit: BoxFit.contain),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.item});

  final SpaceMediaViewerItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SpaceMediaImage(
                    url: item.previewUrl.isNotEmpty
                        ? item.previewUrl
                        : item.originalUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '视频预览开发中，可先保存到相册',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  if (showBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE64545),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
