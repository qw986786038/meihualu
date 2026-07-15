import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/models/team_brand.dart';

class TeamBrandPickerPage extends StatefulWidget {
  const TeamBrandPickerPage({super.key});

  @override
  State<TeamBrandPickerPage> createState() => _TeamBrandPickerPageState();
}

class _TeamBrandPickerPageState extends State<TeamBrandPickerPage> {
  final _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  String get _selectedCategory => kTeamBrandCategories[_selectedCategoryIndex];

  List<TeamBrandPreset> get _visiblePresets {
    final keyword = _searchController.text.trim();
    Iterable<TeamBrandPreset> items = kTeamBrandPresets.where(
      (item) => item.category == _selectedCategory,
    );

    if (keyword.isNotEmpty) {
      items = kTeamBrandPresets.where(
        (item) =>
            item.name.contains(keyword) ||
            item.shortLabel.toLowerCase().contains(keyword.toLowerCase()),
      );
    }

    return items.toList();
  }

  void _selectPreset(TeamBrandPreset preset) {
    context.pop(
      TeamBrandSelection(
        displayName: preset.name,
        source: TeamBrandSource.preset,
        presetId: preset.id,
      ),
    );
  }

  Future<void> _pickFromAlbum() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (!mounted) return;
      _showMessage('需要相册权限才能选择品牌图');
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (!mounted || albums.isEmpty) return;

    final assets = await albums.first.getAssetListPaged(page: 0, size: 60);
    if (!mounted || assets.isEmpty) {
      _showMessage('相册中没有可用图片');
      return;
    }

    final picked = await showModalBottomSheet<AssetEntity>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(asset),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(
                      const ThumbnailSize.square(200),
                    ),
                    builder: (context, snapshot) {
                      final bytes = snapshot.data;
                      if (bytes == null) {
                        return const ColoredBox(color: Colors.black12);
                      }
                      return Image.memory(bytes, fit: BoxFit.cover);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (picked == null || !mounted) return;

    final file = await picked.file;
    if (file == null || !mounted) return;

    context.pop(
      TeamBrandSelection(
        displayName: '相册品牌图',
        source: TeamBrandSource.album,
        imagePath: file.path,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presets = _visiblePresets;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '搜索品牌图',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '输入品牌名/公司名',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ActionTile(
              icon: Icons.image_outlined,
              label: '从相册选',
              onTap: _pickFromAlbum,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kTeamBrandCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final selected = index == _selectedCategoryIndex;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                      _searchController.clear();
                    });
                  },
                  child: SizedBox(
                    height: 48,
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              kTeamBrandCategories[index],
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.0,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected
                                    ? const Color(0xFF1677FF)
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 24 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1677FF),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: presets.isEmpty
                ? Center(
                    child: Text(
                      '暂无匹配品牌',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 92,
                    ),
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      return _BrandCard(
                        preset: preset,
                        onTap: () => _selectPreset(preset),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF4FF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: const Color(0xFF1677FF)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.0,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.preset,
    required this.onTap,
  });

  final TeamBrandPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(preset.backgroundColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            preset.shortLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.0,
                              fontWeight: FontWeight.w700,
                              color: Color(preset.textColor),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.0,
                              color: Color(preset.textColor)
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
