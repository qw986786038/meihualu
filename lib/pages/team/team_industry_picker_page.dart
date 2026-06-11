import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team_industry.dart';

class TeamIndustryPickerPage extends StatefulWidget {
  const TeamIndustryPickerPage({
    super.key,
    this.initialSelection,
  });

  final String? initialSelection;

  @override
  State<TeamIndustryPickerPage> createState() => _TeamIndustryPickerPageState();
}

class _TeamIndustryPickerPageState extends State<TeamIndustryPickerPage> {
  late String? _selected;
  late final Set<String> _expandedCategories;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
    _expandedCategories = <String>{};
    final initialCategory = _selected == null
        ? null
        : findIndustryCategoryName(_selected!);
    if (initialCategory != null) {
      _expandedCategories.add(initialCategory);
    }
  }

  void _toggleExpanded(IndustryCategory category) {
    setState(() {
      if (_expandedCategories.contains(category.name)) {
        _expandedCategories.remove(category.name);
      } else {
        _expandedCategories.add(category.name);
      }
    });
  }

  void _select(String value) {
    setState(() => _selected = value);
    context.pop(value);
  }

  bool _isSelected(String value) => _selected == value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '行业类型',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: kTeamIndustryCategories.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final category = kTeamIndustryCategories[index];
          if (category.hasChildren) {
            return _ExpandableCategoryTile(
              category: category,
              expanded: _expandedCategories.contains(category.name),
              selected: _selected,
              onToggle: () => _toggleExpanded(category),
              onSelect: _select,
            );
          }

          return _CategoryTile(
            category: category,
            selected: _isSelected(category.name),
            onTap: () => _select(category.name),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IndustryCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            _IndustryIcon(icon: category.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check,
                color: Color(0xFF1677FF),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableCategoryTile extends StatelessWidget {
  const _ExpandableCategoryTile({
    required this.category,
    required this.expanded,
    required this.selected,
    required this.onToggle,
    required this.onSelect,
  });

  final IndustryCategory category;
  final bool expanded;
  final String? selected;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                _IndustryIcon(icon: category.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            color: const Color(0xFFF7F8FA),
            child: Column(
              children: [
                for (final child in category.children)
                  InkWell(
                    onTap: () => onSelect(child),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(68, 14, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              child,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          if (selected == child)
                            const Icon(
                              Icons.check,
                              color: Color(0xFF1677FF),
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IndustryIcon extends StatelessWidget {
  const _IndustryIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 24,
        color: const Color(0xFF1677FF),
      ),
    );
  }
}
