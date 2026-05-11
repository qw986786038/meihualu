import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

class DynamicListViewBenchPage extends StatefulWidget {
  const DynamicListViewBenchPage({super.key});

  @override
  State<DynamicListViewBenchPage> createState() =>
      _DynamicListViewBenchPageState();
}

class _DynamicListViewBenchPageState extends State<DynamicListViewBenchPage> {
  bool _showOverlay = true;
  late final _DynamicListViewBenchController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      _DynamicListViewBenchController(),
      tag: 'dynamic-page',
    );
  }

  @override
  void dispose() {
    Get.delete<_DynamicListViewBenchController>(tag: 'dynamic-page');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Obx(() {
      final rows = controller.rows;
      final updates = controller.updateCount.value;
      final elapsed = controller.elapsedMs.value;
      final fps = elapsed > 0
          ? (updates * 1000 / elapsed).toStringAsFixed(1)
          : '-';
      final running = controller.running.value;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricItem(label: '更新次数', value: '$updates'),
                    _MetricItem(label: '耗时', value: '${elapsed}ms'),
                    _MetricItem(label: 'update/s', value: fps),
                    _MetricItem(label: '行数', value: '${rows.length}'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '参数控制',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('列表规模'),
                    Wrap(
                      spacing: 6,
                      children: const [
                        200,
                        500,
                        1000,
                        2000,
                      ].map((size) => _SizeChip(size: size)).toList(),
                    ),
                    const SizedBox(height: 8),
                    const Text('每帧变更条数'),
                    Wrap(
                      spacing: 6,
                      children: const [
                        5,
                        20,
                        50,
                        100,
                      ].map((batch) => _BatchChip(batch: batch)).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: running ? null : controller.start,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('开始'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: running ? controller.stop : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, index) {
                final row = rows[index];
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  title: Text(row['title'].toString()),
                  subtitle: Text('value=${row['value']}'),
                  trailing: Text('#$index'),
                );
              },
            ),
          ),
        ],
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('动态 ListView 压测'),
        actions: [
          IconButton(
            tooltip: _showOverlay ? '关闭性能叠加层' : '开启性能叠加层',
            onPressed: () => setState(() => _showOverlay = !_showOverlay),
            icon: Icon(
              _showOverlay ? Icons.bar_chart : Icons.bar_chart_outlined,
            ),
          ),
        ],
      ),
      body: _showOverlay
          ? Stack(
              children: [
                body,
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: PerformanceOverlay.allEnabled(),
                  ),
                ),
              ],
            )
          : body,
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.size});
  final int size;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<_DynamicListViewBenchController>(tag: 'dynamic-page');
    return Obx(() {
      return ChoiceChip(
        label: Text('$size'),
        selected: c.targetSize.value == size,
        onSelected: (_) => c.setTargetSize(size),
      );
    });
  }
}

class _BatchChip extends StatelessWidget {
  const _BatchChip({required this.batch});
  final int batch;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<_DynamicListViewBenchController>(tag: 'dynamic-page');
    return Obx(() {
      return ChoiceChip(
        label: Text('$batch'),
        selected: c.mutationBatch.value == batch,
        onSelected: (_) => c.setMutationBatch(batch),
      );
    });
  }
}

class _DynamicListViewBenchController extends GetxController {
  final rows = <Map<String, dynamic>>[].obs;
  final targetSize = 500.obs;
  final mutationBatch = 20.obs;
  final updateCount = 0.obs;
  final elapsedMs = 0.obs;
  final running = false.obs;

  final _rng = Random();
  Timer? _timer;
  int _tick = 0;

  void start() {
    if (running.value) return;
    running.value = true;
    updateCount.value = 0;
    _seedRows(force: true);
    final sw = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _mutateRows();
      updateCount.value++;
      elapsedMs.value = sw.elapsedMilliseconds;
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    running.value = false;
  }

  void setTargetSize(int value) {
    if (targetSize.value == value) return;
    targetSize.value = value;
    if (!running.value) _seedRows(force: true);
  }

  void setMutationBatch(int value) {
    if (mutationBatch.value == value) return;
    mutationBatch.value = value;
  }

  void _seedRows({bool force = false}) {
    if (!force && rows.isNotEmpty) return;
    _tick = 0;
    rows.value = List.generate(
      targetSize.value,
      (index) => {
        'id': index,
        'title': 'Item $index',
        'value': _rng.nextInt(100000),
      },
    );
  }

  void _mutateRows() {
    if (rows.isEmpty) {
      _seedRows(force: true);
      return;
    }

    final batch = mutationBatch.value;
    for (var i = 0; i < batch; i++) {
      final idx = _rng.nextInt(rows.length);
      final old = rows[idx];
      rows[idx] = {
        'id': old['id'],
        'title': old['title'],
        'value': _rng.nextInt(100000),
      };
    }

    _tick++;
    if (_tick % 4 == 0 && rows.length < targetSize.value + 200) {
      final id = DateTime.now().microsecondsSinceEpoch;
      final insertAt = _rng.nextInt(rows.length);
      rows.insert(insertAt, {
        'id': id,
        'title': 'Item $id',
        'value': _rng.nextInt(100000),
      });
    }
    if (_tick % 6 == 0 && rows.length > (targetSize.value ~/ 2)) {
      rows.removeAt(_rng.nextInt(rows.length));
    }
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
