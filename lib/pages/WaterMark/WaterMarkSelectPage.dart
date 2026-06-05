import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/pages/camera/WaterMarkController.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

class WaterMarkSelectPage extends StatelessWidget {
  const WaterMarkSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final controller = Get.find<WaterMarkController>();
    final sampleNow = DateTime(2026, 5, 12, 10, 40);
    const sampleAddress = '深圳市南山区 · 科技园';
    const sampleWeather = '晴';
    const sampleTemperature = '26';
    const sampleCoordinate = '经纬度 22.540503, 113.934528';

    return SafeArea(
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 16 / 10,
        ),
        itemCount: kWatermarkTemplatePresets.length,
        itemBuilder: (context, index) {
          final preset = kWatermarkTemplatePresets[index];
          return _WaterMarkGridTile(
            preset: preset,
            selected: controller.selectedTemplateId.value == preset.id,
            onTap: () {
              controller.selectTemplate(preset.id);
              Navigator.of(context).pop();
            },
            child: WatermarkTemplateView(
              templateId: preset.id,
              now: sampleNow,
              address: sampleAddress,
              weatherText: sampleWeather,
              temperatureText: sampleTemperature,
              coordinateText: sampleCoordinate,
              showCoordinate: true,
              compact: true,
            ),
          );
        },
      ),
    );
  }
}

class _WaterMarkGridTile extends StatelessWidget {
  const _WaterMarkGridTile({
    required this.preset,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final WatermarkTemplatePreset preset;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.45,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(8),
                    child: FittedBox(
                      alignment: Alignment.bottomLeft,
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: child,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  preset.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
