import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 是否启用内嵌调试面板。
///
/// 默认全模式开启（含 release）；关闭：`--dart-define=NO_VCONSOLE=true`
bool get kEnableAppVConsole => !const bool.fromEnvironment('NO_VCONSOLE');

/// 简易 vConsole：收集 print / debugPrint，右下角浮钮查看。
abstract final class AppVConsole {
  static const int _maxLines = 800;
  static final ValueNotifier<List<String>> lines =
      ValueNotifier<List<String>>(<String>[]);
  static final Queue<String> _buffer = Queue<String>();
  static DebugPrintCallback? _previousDebugPrint;
  static bool _installed = false;

  static void install() {
    if (_installed || !kEnableAppVConsole) return;
    _installed = true;
    _previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      add(message ?? '');
      (_previousDebugPrint ?? debugPrintThrottled)(message, wrapWidth: wrapWidth);
    };
  }

  static void add(String message) {
    if (!kEnableAppVConsole) return;
    final text = message.trimRight();
    if (text.isEmpty) return;
    final stamp = DateTime.now();
    final hh = stamp.hour.toString().padLeft(2, '0');
    final mm = stamp.minute.toString().padLeft(2, '0');
    final ss = stamp.second.toString().padLeft(2, '0');
    final line = '[$hh:$mm:$ss] $text';
    _buffer.addLast(line);
    while (_buffer.length > _maxLines) {
      _buffer.removeFirst();
    }
    lines.value = List<String>.unmodifiable(_buffer);
  }

  static void clear() {
    _buffer.clear();
    lines.value = const <String>[];
  }

  /// 拦截 Zone 内的 print，与 debugPrint 一并写入面板。
  static ZoneSpecification get zoneSpecification => ZoneSpecification(
        print: (self, parent, zone, line) {
          add(line);
          parent.print(zone, line);
        },
      );
}

/// 包裹根组件，叠加可拖动浮钮与日志面板。
class AppVConsoleScope extends StatelessWidget {
  const AppVConsoleScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kEnableAppVConsole) return child;
    return _VConsoleHost(child: child);
  }
}

class _VConsoleHost extends StatefulWidget {
  const _VConsoleHost({required this.child});

  final Widget child;

  @override
  State<_VConsoleHost> createState() => _VConsoleHostState();
}

class _VConsoleHostState extends State<_VConsoleHost> {
  Offset _fabOffset = const Offset(16, 120);
  bool _panelOpen = false;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_panelOpen) _buildPanel(context),
        _buildFab(),
      ],
    );
  }

  Widget _buildFab() {
    return Positioned(
      right: _fabOffset.dx,
      bottom: _fabOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _fabOffset = Offset(
              (_fabOffset.dx - details.delta.dx).clamp(8.0, 280.0),
              (_fabOffset.dy - details.delta.dy).clamp(8.0, 560.0),
            );
          });
        },
        child: FloatingActionButton.small(
          heroTag: 'app_vconsole_fab',
          backgroundColor: Colors.black87,
          onPressed: () => setState(() => _panelOpen = !_panelOpen),
          child: Icon(
            _panelOpen ? Icons.close : Icons.bug_report,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 12,
        color: const Color(0xF0121212),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                  child: Row(
                    children: [
                      const Text(
                        'vConsole',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: AppVConsole.clear,
                        child: const Text(
                          '清空',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _panelOpen = false),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '过滤，如 capture',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => setState(() => _filter = value.trim()),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: AppVConsole.lines,
                    builder: (context, all, _) {
                      final q = _filter.toLowerCase();
                      final shown = q.isEmpty
                          ? all
                          : all
                              .where((e) => e.toLowerCase().contains(q))
                              .toList(growable: false);
                      if (shown.isEmpty) {
                        return const Center(
                          child: Text(
                            '暂无日志',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final line = shown[shown.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              line,
                              style: const TextStyle(
                                color: Color(0xFFB2FF59),
                                fontSize: 11,
                                height: 1.35,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      );
                    },
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
