import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/utils/watermark_coordinate_formatter.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

class WatermarkSettingsSheet extends StatefulWidget {
  const WatermarkSettingsSheet({
    super.key,
    required this.data,
    required this.updateData,
    required this.templateId,
    required this.locationService,
    required this.initialNow,
  });

  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> updateData;
  final String templateId;
  final AMapLocationService locationService;
  final DateTime initialNow;

  @override
  State<WatermarkSettingsSheet> createState() => _WatermarkSettingsSheetState();
}

class _WatermarkSettingsSheetState extends State<WatermarkSettingsSheet> {
  late Map<String, dynamic> _data = Map<String, dynamic>.from(widget.data);
  late DateTime _now = widget.initialNow;
  Timer? _timer;
  int _activeDialogs = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _activeDialogs > 0) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _patch(Map<String, dynamic> patch) {
    _data = {..._data, ...patch};
    widget.updateData(_data);
    setState(() {});
  }

  String get _displayAddress {
    final selected = watermarkString(_data, kWatermarkDataSelectedAddress);
    if (selected.isNotEmpty) return selected;
    return widget.locationService.watermarkAddress.value;
  }

  String? get _coordinatePreview {
    final location = widget.locationService.latestLocation.value;
    return WatermarkCoordinateFormatter.format(
      location?.latitude,
      location?.longitude,
      watermarkString(
        _data,
        kWatermarkDataCoordinateFormat,
        fallback: kCoordinateFormatDecimal,
      ),
    );
  }

  String get _altitudePreview {
    return WatermarkCoordinateFormatter.formatAltitude(
      widget.locationService.latestLocation.value?.altitude,
    );
  }

  Future<void> _pickLogo() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要相册权限才能添加品牌图')),
      );
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return;

    final assets = await albums.first.getAssetListPaged(page: 0, size: 60);
    if (!mounted || assets.isEmpty) return;

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
    if (picked == null) return;

    final file = await picked.file;
    if (file == null) return;
    _patch({
      kWatermarkDataShowLogo: true,
      kWatermarkDataLogoPath: file.path,
    });
  }

  Future<void> _pickNearbyAddress() async {
    final options = widget.locationService.nearbyRecommendations.toList();
    if (options.isEmpty) {
      final location = widget.locationService.latestLocation.value;
      if (location != null) {
        options.add(widget.locationService.formatBriefAddress(location));
      }
    }
    if (!mounted || options.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('选择附近地点'),
                subtitle: Text('推荐当前位置周边的地点'),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option),
                  trailing: option == _displayAddress
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    _patch({kWatermarkDataSelectedAddress: selected});
  }

  Future<void> _pickCoordinateFormat() async {
    final current = watermarkString(
      _data,
      kWatermarkDataCoordinateFormat,
      fallback: kCoordinateFormatDecimal,
    );
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('经纬度格式')),
              for (final entry in kCoordinateFormatLabels.entries)
                ListTile(
                  title: Text(entry.value),
                  trailing: entry.key == current
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(entry.key),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    _patch({kWatermarkDataCoordinateFormat: selected});
  }

  Future<T?> _withDialogPaused<T>(Future<T?> action) async {
    _activeDialogs++;
    try {
      return await action;
    } finally {
      _activeDialogs--;
    }
  }

  Future<String?> _showTextInputDialog({
    required String title,
    required String hint,
    required int maxLength,
    required String initialText,
  }) {
    return _withDialogPaused(
      showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => _TextInputDialog(
          title: title,
          hint: hint,
          maxLength: maxLength,
          initialText: initialText,
        ),
      ),
    );
  }

  Future<void> _editQuickLabelText() async {
    final result = await _showTextInputDialog(
      title: '快速标注文字',
      hint: '请输入标注文字',
      maxLength: 12,
      initialText: watermarkString(
        _data,
        kWatermarkDataQuickLabelText,
        fallback: '现场拍摄',
      ),
    );
    if (!mounted || result == null) return;
    _patch({kWatermarkDataQuickLabelText: result});
  }

  Future<void> _editCustomTitle({bool revertOnCancel = false}) async {
    final result = await _showTextInputDialog(
      title: '自定义文字标题',
      hint: '请输入标题文字',
      maxLength: 20,
      initialText: watermarkString(_data, kWatermarkDataCustomTitle),
    );
    if (!mounted) return;
    if (result == null) {
      if (revertOnCancel) {
        _patch({kWatermarkDataShowCustomTitle: false});
      }
      return;
    }
    _patch({
      kWatermarkDataCustomTitle: result,
      kWatermarkDataShowCustomTitle: result.isNotEmpty,
    });
  }

  Future<void> _pickQuickLabelColor() async {
    const colors = <Color>[
      Color(0xFFFFC107),
      Color(0xFFFF5722),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFE91E63),
      Colors.white,
    ];
    final current = Color(
      watermarkColorInt(
        _data,
        kWatermarkDataQuickLabelBorderColor,
        fallback: 0xFFFFC107,
      ),
    );

    final selected = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('外框颜色'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in colors)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == current
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black26,
                        width: color == current ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    _patch({kWatermarkDataQuickLabelBorderColor: selected.toARGB32()});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final showLogo = watermarkBool(_data, kWatermarkDataShowLogo, fallback: false);
    final showQuickLabel = watermarkBool(
      _data,
      kWatermarkDataShowQuickLabel,
      fallback: false,
    );
    final showCoordinate = watermarkBool(
      _data,
      kWatermarkDataShowCoordinate,
      fallback: true,
    );
    final showAltitude = watermarkBool(
      _data,
      kWatermarkDataShowAltitude,
      fallback: false,
    );
    final showCustomTitle = watermarkBool(
      _data,
      kWatermarkDataShowCustomTitle,
      fallback: false,
    );
    final logoPath = watermarkString(_data, kWatermarkDataLogoPath);
    final coordinateFormat = watermarkString(
      _data,
      kWatermarkDataCoordinateFormat,
      fallback: kCoordinateFormatDecimal,
    );

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '水印设置',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SettingsPreviewCard(
                child: Obx(() {
                  return WatermarkTemplateView(
                    templateId: widget.templateId,
                    now: _now,
                    address: _displayAddress,
                    weatherText: widget.locationService.watermarkWeather.value,
                    temperatureText:
                        widget.locationService.watermarkTemperature.value,
                    coordinateText: _coordinatePreview,
                    altitudeText: showAltitude ? _altitudePreview : null,
                    showAddress: true,
                    showCoordinate: showCoordinate,
                    showWeekday: watermarkBool(
                      _data,
                      kWatermarkDataShowWeekday,
                      fallback: true,
                    ),
                    showLogo: showLogo,
                    logoPath: logoPath,
                    showQuickLabel: showQuickLabel,
                    quickLabelText: watermarkString(
                      _data,
                      kWatermarkDataQuickLabelText,
                      fallback: '现场拍摄',
                    ),
                    quickLabelBorderColor: Color(
                      watermarkColorInt(
                        _data,
                        kWatermarkDataQuickLabelBorderColor,
                        fallback: 0xFFFFC107,
                      ),
                    ),
                    showCustomTitle: showCustomTitle,
                    customTitle: watermarkString(
                      _data,
                      kWatermarkDataCustomTitle,
                    ),
                    showAltitude: showAltitude,
                  );
                }),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
                children: [
                  _SettingHeaderRow(
                    title: '品牌图(Logo)',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch.adaptive(
                          value: showLogo,
                          onChanged: (value) {
                            _patch({kWatermarkDataShowLogo: value});
                          },
                        ),
                        TextButton(
                          onPressed: _pickLogo,
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                  ),
                  if (showLogo && logoPath.isNotEmpty && !kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: File(logoPath).existsSync()
                                ? Image.file(
                                    File(logoPath),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ColoredBox(color: Colors.black12),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _pickLogo,
                            child: const Text('更换图片'),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  _SettingHeaderRow(
                    title: '快速标注',
                    trailing: Switch.adaptive(
                      value: showQuickLabel,
                      onChanged: (value) {
                        _patch({kWatermarkDataShowQuickLabel: value});
                      },
                    ),
                  ),
                  if (showQuickLabel) ...[
                    _ActionTile(
                      label: '标注文字',
                      value: watermarkString(
                        _data,
                        kWatermarkDataQuickLabelText,
                        fallback: '现场拍摄',
                      ),
                      onTap: _editQuickLabelText,
                    ),
                    _ActionTile(
                      label: '外框颜色',
                      value: '#${watermarkColorInt(
                        _data,
                        kWatermarkDataQuickLabelBorderColor,
                        fallback: 0xFFFFC107,
                      ).toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                      leading: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Color(
                            watermarkColorInt(
                              _data,
                              kWatermarkDataQuickLabelBorderColor,
                              fallback: 0xFFFFC107,
                            ),
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                      onTap: _pickQuickLabelColor,
                    ),
                  ],
                  const Divider(),
                  _InfoTile(
                    title: '真实时间',
                    subtitle:
                        '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')} '
                        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                    trailingText: '仅显示',
                  ),
                  const Divider(),
                  _ActionTile(
                    label: '地点',
                    value: _displayAddress,
                    onTap: _pickNearbyAddress,
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const Divider(),
                  _SettingHeaderRow(
                    title: '经纬度',
                    trailing: Switch.adaptive(
                      value: showCoordinate,
                      onChanged: (value) {
                        _patch({kWatermarkDataShowCoordinate: value});
                      },
                    ),
                  ),
                  if (showCoordinate)
                    _ActionTile(
                      label: '显示格式',
                      value: kCoordinateFormatLabels[coordinateFormat] ??
                          kCoordinateFormatLabels[kCoordinateFormatDecimal]!,
                      onTap: _pickCoordinateFormat,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  const Divider(),
                  _SettingHeaderRow(
                    title: '海拔',
                    trailing: Switch.adaptive(
                      value: showAltitude,
                      onChanged: (value) {
                        _patch({kWatermarkDataShowAltitude: value});
                      },
                    ),
                  ),
                  if (showAltitude)
                    _InfoTile(
                      title: '显示内容',
                      subtitle: _altitudePreview,
                    ),
                  const Divider(),
                  _SettingHeaderRow(
                    title: '自定义文字标题',
                    trailing: Switch.adaptive(
                      value: showCustomTitle,
                      onChanged: (value) async {
                        if (!value) {
                          _patch({kWatermarkDataShowCustomTitle: false});
                          return;
                        }
                        final title = watermarkString(
                          _data,
                          kWatermarkDataCustomTitle,
                        );
                        if (title.isEmpty) {
                          _patch({kWatermarkDataShowCustomTitle: true});
                          await _editCustomTitle(revertOnCancel: true);
                          return;
                        }
                        _patch({kWatermarkDataShowCustomTitle: true});
                      },
                    ),
                  ),
                  if (showCustomTitle)
                    _ActionTile(
                      label: '标题内容',
                      value: watermarkString(
                        _data,
                        kWatermarkDataCustomTitle,
                        fallback: '点击设置',
                      ),
                      onTap: _editCustomTitle,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPreviewCard extends StatelessWidget {
  const _SettingsPreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: FittedBox(
          alignment: Alignment.bottomLeft,
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SettingHeaderRow extends StatelessWidget {
  const _SettingHeaderRow({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.leading,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(label),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(Icons.edit_outlined, size: 20),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.subtitle,
    this.trailingText,
  });

  final String title;
  final String subtitle;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailingText == null
          ? null
          : Text(
              trailingText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

String watermarkTemplateTitle(String? templateId) {
  return watermarkTemplateById(templateId).title;
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.maxLength,
    required this.initialText,
  });

  final String title;
  final String hint;
  final int maxLength;
  final String initialText;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
