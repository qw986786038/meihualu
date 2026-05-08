import 'package:flutter/material.dart';
import 'package:watermark_camera/widgets/stack_board.dart';

class StackBoardPage extends StatefulWidget {
  const StackBoardPage({super.key});

  @override
  State<StackBoardPage> createState() => _StackBoardPageState();
}

class _StackBoardPageState extends State<StackBoardPage> {
  final _textTemplate = StackBoardTemplate(
    templateId: 'text',
    label: 'Text',
    builder: (context, selected, data, updateData) => Container(color: Colors.white, alignment: Alignment.center, child: const Text('Text')),
    defaultAllowOverlap: false,
  );

  final _buttonTemplate = StackBoardTemplate(
    templateId: 'button',
    label: 'Button',
    defaultData: const {'data': '0'},
    builder: (context, selected, data, updateData) => ElevatedButton(
      onPressed: () {
        int a = int.parse((data["data"] ?? "0").toString());
        a++;
        updateData({...data, 'data': '$a'});
      },
      child: Text('Button${data["data"]}'),
    ),
    defaultDraggable: true,
  );

  final _boxTemplate = StackBoardTemplate(
    templateId: 'box',
    label: 'Box',
    defaultSize: const Size(140, 72),
    builder: (context, selected, data, updateData) => Container(color: const Color(0xFF90CAF9), alignment: Alignment.center, child: const Text('任意 Widget')),
  );

  final StackBoardController _controller = StackBoardController();
  final TextEditingController _jsonInputController = TextEditingController();

  Map<String, StackBoardTemplate> get _templatesById => {
    _textTemplate.templateId: _textTemplate,
    _buttonTemplate.templateId: _buttonTemplate,
    _boxTemplate.templateId: _boxTemplate,
  };

  @override
  void dispose() {
    _jsonInputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _addFromTemplate(
    StackBoardTemplate template, {
    StackBoardPlacement placement = StackBoardPlacement.topLeft,
    Offset? initialPosition,
    EdgeInsets placementMargin = const EdgeInsets.all(12),
    bool? allowOverlap,
    bool? draggable,
  }) {
    _controller.addFromTemplate(
      template,
      placement: placement,
      initialPosition: initialPosition,
      placementMargin: placementMargin,
      allowOverlap: allowOverlap,
      draggable: draggable,
    );
  }

  Future<void> _showExportJsonDialog() async {
    final json = _controller.toJsonString();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出 JSON'),
        content: SizedBox(width: 520, child: SelectableText(json)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭'))],
      ),
    );
  }

  Future<void> _showImportJsonDialog() async {
    _jsonInputController.text = '';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从 JSON 恢复'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: _jsonInputController,
            maxLines: 12,
            decoration: const InputDecoration(hintText: '粘贴导出的 JSON', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              try {
                _controller.restoreFromJsonString(_jsonInputController.text, templatesById: _templatesById);
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
              }
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stack Board')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _addFromTemplate(_textTemplate, placement: StackBoardPlacement.topLeft, allowOverlap: false, draggable: true),
                  child: const Text('左上 Text'),
                ),
                FilledButton(
                  onPressed: () => _addFromTemplate(_buttonTemplate, placement: StackBoardPlacement.bottomRight, allowOverlap: true, draggable: true),
                  child: const Text('右下 Button'),
                ),
                FilledButton(
                  onPressed: () => _addFromTemplate(_boxTemplate, placement: StackBoardPlacement.center, allowOverlap: false, draggable: false),
                  child: const Text('中间 Box(固定)'),
                ),
                OutlinedButton(onPressed: _showExportJsonDialog, child: const Text('导出 JSON')),
                OutlinedButton(onPressed: _showImportJsonDialog, child: const Text('从 JSON 恢复')),
              ],
            ),
          ),
          Expanded(child: StackBoard(controller: _controller)),
        ],
      ),
    );
  }
}
