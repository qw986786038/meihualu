import 'package:flutter/material.dart';

Future<String?> showOverlayTextInputDialog(
  BuildContext context, {
  required String initialText,
  String title = '输入文字',
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => OverlayTextInputDialog(
      title: title,
      initialText: initialText,
    ),
  );
}

class OverlayTextInputDialog extends StatefulWidget {
  const OverlayTextInputDialog({
    super.key,
    required this.title,
    required this.initialText,
  });

  final String title;
  final String initialText;

  @override
  State<OverlayTextInputDialog> createState() => _OverlayTextInputDialogState();
}

class _OverlayTextInputDialogState extends State<OverlayTextInputDialog> {
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

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 2,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '请输入文字',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
