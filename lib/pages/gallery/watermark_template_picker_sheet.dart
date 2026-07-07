import 'package:flutter/material.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

Future<String?> showWatermarkTemplatePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => const WatermarkTemplatePickerSheet(),
  );
}

class WatermarkTemplatePickerSheet extends StatelessWidget {
  const WatermarkTemplatePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.55;
    final sampleNow = DateTime.now();
    const sampleAddress = '定位中...';

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '选择水印模板',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 16 / 10,
                ),
                itemCount: kWatermarkTemplatePresets.length,
                itemBuilder: (context, index) {
                  final preset = kWatermarkTemplatePresets[index];
                  return _TemplateTile(
                    preset: preset,
                    onTap: () => Navigator.of(context).pop(preset.id),
                    child: WatermarkTemplateView(
                      templateId: preset.id,
                      now: sampleNow,
                      address: sampleAddress,
                      showCoordinate: true,
                      compact: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.preset,
    required this.onTap,
    required this.child,
  });

  final WatermarkTemplatePreset preset;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
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
                const SizedBox(height: 4),
                Text(
                  preset.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
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
