import 'package:flutter/material.dart';
import 'package:watermark_camera/pages/gallery/add_text_presets.dart';
import 'package:watermark_camera/pages/gallery/overlay_text_item.dart';

const Color _kSheetBg = Color(0xFF2A2A2A);

Future<AddTextPreset?> showAddTextPickerSheet(BuildContext context) {
  return showModalBottomSheet<AddTextPreset>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _kSheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) => const AddTextPickerSheet(),
  );
}

class AddTextPickerSheet extends StatelessWidget {
  const AddTextPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.62;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight + bottomInset,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '加字',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                ),
                itemCount: kAddTextPresets.length,
                itemBuilder: (context, index) {
                  final preset = kAddTextPresets[index];
                  return _PresetTile(
                    preset: preset,
                    onTap: () => Navigator.of(context).pop(preset),
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

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset, required this.onTap});

  final AddTextPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3A3A3A),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
              child: AddTextPresetPreview(preset: preset),
            ),
            if (preset.limitedFree)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: const Text(
                    '限免',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
