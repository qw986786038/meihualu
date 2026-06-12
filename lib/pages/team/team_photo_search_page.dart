import 'package:flutter/material.dart';

class TeamPhotoSearchPage extends StatefulWidget {
  const TeamPhotoSearchPage({super.key, this.teamId});

  final String? teamId;

  @override
  State<TeamPhotoSearchPage> createState() => _TeamPhotoSearchPageState();
}

class _TeamPhotoSearchPageState extends State<TeamPhotoSearchPage> {
  static const _primaryBlue = Color(0xFF1677FF);
  static const _voiceGreen = Color(0xFF34C759);

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '查找照片',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showComingSoon('电脑端'),
            icon: const Icon(Icons.desktop_windows_outlined, size: 18),
            label: const Text(
              '电脑端',
              style: TextStyle(fontSize: 14),
            ),
            style: TextButton.styleFrom(foregroundColor: _primaryBlue),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '水印文字，人名，地点...一句话搜索',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: '12.14-06.12',
                  onTap: () => _showComingSoon('日期范围'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '拍摄人',
                  onTap: () => _showComingSoon('拍摄人筛选'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '地点',
                  onTap: () => _showComingSoon('地点筛选'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '水印',
                  onTap: () => _showComingSoon('水印筛选'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '猜你想搜',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon('联系客服'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(
                    Icons.support_agent,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                label: const Text('联系客服'),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showComingSoon('语音搜索'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _voiceGreen,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.mic, color: Colors.white),
                    label: const Text(
                      '按住说话',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showComingSoon('查找照片'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '查找照片',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              Icon(Icons.expand_more, size: 18, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
