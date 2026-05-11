import 'package:flutter/material.dart';

class WaterMarkSelectPage extends StatelessWidget {
  const WaterMarkSelectPage({super.key});

  static const List<String> _titles = ['水印 1', '水印 2', '水印 3', '水印 4', '水印 5', '水印 6'];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: 16 / 10),
        itemCount: _titles.length,
        itemBuilder: (context, index) {
          return _WaterMarkGridTile(title: _titles[index]);
        },
      ),
    );
  }
}

class _WaterMarkGridTile extends StatelessWidget {
  const _WaterMarkGridTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Icon(Icons.image_outlined, size: 40, color: Colors.white.withValues(alpha: 0.35)),
              ),
            ),
            Container(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
