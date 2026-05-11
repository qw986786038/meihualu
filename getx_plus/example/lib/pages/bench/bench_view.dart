import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'bench_logic.dart';
import 'dynamic_listview_bench_page.dart';

/// Obx Performance Benchmark Page
///
/// All 100 reactive variables are read inside **one single** Obx widget.
/// Tap a scenario, then hit ▶ to start; the PerformanceOverlay in the top-right
/// corner shows the Flutter engine's raster and UI thread frame timings in real
/// time.
class BenchView extends StatefulWidget {
  const BenchView({super.key});

  @override
  State<BenchView> createState() => _BenchViewState();
}

class _BenchViewState extends State<BenchView> {
  static const _benchTag = 'bench-page';
  bool _showOverlay = true;
  late final BenchLogic _logic;

  void _toggleOverlay() => setState(() => _showOverlay = !_showOverlay);

  @override
  void initState() {
    super.initState();
    _logic = Get.put(BenchLogic(), tag: _benchTag);
  }

  @override
  void dispose() {
    _logic.stopBenchmark();
    Get.delete<BenchLogic>(tag: _benchTag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PerformanceOverlay is a Flutter-native widget that renders GPU/CPU frame
    // timing bars directly on the screen without DevTools.
    final Widget body = _BenchBody(logic: _logic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obx 性能测试'),
        actions: [
          IconButton(
            tooltip: '打开动态 ListView 压测页面',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DynamicListViewBenchPage(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
          ),
          Tooltip(
            message: _showOverlay ? '关闭性能叠加层' : '开启性能叠加层',
            child: IconButton(
              icon: Icon(
                _showOverlay ? Icons.bar_chart : Icons.bar_chart_outlined,
              ),
              onPressed: _toggleOverlay,
            ),
          ),
        ],
      ),
      body: _showOverlay
          ? Stack(
              children: [
                body,
                // PerformanceOverlay in the top-right corner, smaller so it
                // does not cover the content.
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

// ─────────────────────────────────────────────────────────────────────────────
// Main content — everything inside ONE Obx
// ─────────────────────────────────────────────────────────────────────────────

class _BenchBody extends StatelessWidget {
  const _BenchBody({required this.logic});

  final BenchLogic logic;

  @override
  Widget build(BuildContext context) {
    // ┌─────────────────────────────────────────────────────────────────────┐
    // │                  ONE SINGLE Obx reading 100 variables               │
    // └─────────────────────────────────────────────────────────────────────┘
    return Obx(() {
      // ── read all 100 variables inside a single Obx ──────────────────────
      // ints
      final rI = [
        logic.i00.value,
        logic.i01.value,
        logic.i02.value,
        logic.i03.value,
        logic.i04.value,
        logic.i05.value,
        logic.i06.value,
        logic.i07.value,
        logic.i08.value,
        logic.i09.value,
        logic.i10.value,
        logic.i11.value,
        logic.i12.value,
        logic.i13.value,
        logic.i14.value,
        logic.i15.value,
        logic.i16.value,
        logic.i17.value,
        logic.i18.value,
        logic.i19.value,
        logic.i20.value,
        logic.i21.value,
        logic.i22.value,
        logic.i23.value,
        logic.i24.value,
        logic.i25.value,
        logic.i26.value,
        logic.i27.value,
        logic.i28.value,
        logic.i29.value,
      ];
      // doubles
      final rD = [
        logic.d00.value,
        logic.d01.value,
        logic.d02.value,
        logic.d03.value,
        logic.d04.value,
        logic.d05.value,
        logic.d06.value,
        logic.d07.value,
        logic.d08.value,
        logic.d09.value,
        logic.d10.value,
        logic.d11.value,
        logic.d12.value,
        logic.d13.value,
        logic.d14.value,
        logic.d15.value,
        logic.d16.value,
        logic.d17.value,
        logic.d18.value,
        logic.d19.value,
      ];
      // strings
      final rS = [
        logic.s00.value,
        logic.s01.value,
        logic.s02.value,
        logic.s03.value,
        logic.s04.value,
        logic.s05.value,
        logic.s06.value,
        logic.s07.value,
        logic.s08.value,
        logic.s09.value,
        logic.s10.value,
        logic.s11.value,
        logic.s12.value,
        logic.s13.value,
        logic.s14.value,
        logic.s15.value,
        logic.s16.value,
        logic.s17.value,
        logic.s18.value,
        logic.s19.value,
      ];
      // bools
      final rB = [
        logic.b00.value,
        logic.b01.value,
        logic.b02.value,
        logic.b03.value,
        logic.b04.value,
        logic.b05.value,
        logic.b06.value,
        logic.b07.value,
        logic.b08.value,
        logic.b09.value,
        logic.b10.value,
        logic.b11.value,
        logic.b12.value,
        logic.b13.value,
        logic.b14.value,
      ];
      // lists + maps
      final rL = [
        logic.l00.value,
        logic.l01.value,
        logic.l02.value,
        logic.l03.value,
        logic.l04.value,
        logic.l05.value,
        logic.l06.value,
        logic.l07.value,
        logic.l08.value,
        logic.l09.value,
      ];
      final rM = [
        logic.m00.value,
        logic.m01.value,
        logic.m02.value,
        logic.m03.value,
        logic.m04.value,
      ];

      // ── benchmark stats ─────────────────────────────────────────────────
      final updates = logic.updateCount.value;
      final elapsed = logic.elapsedMs.value;
      final isRunning = logic.running.value;
      final scenario = logic.scenarioIndex.value;
      final fps = elapsed > 0
          ? (updates * 1000 / elapsed).toStringAsFixed(1)
          : '—';
      final isDynamicListScenario = scenario == 6;
      final dynamicRows = isDynamicListScenario
          ? logic.dynamicRows
          : const <Map<String, dynamic>>[];
      final listTargetSize = logic.listTargetSize.value;
      final listMutationBatch = logic.listMutationBatch.value;

      return CustomScrollView(
        slivers: [
          // ── stats header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 96, 12, 4),
              child: _StatsCard(
                updates: updates,
                elapsed: elapsed,
                fps: fps,
                isRunning: isRunning,
              ),
            ),
          ),

          // ── scenario selector ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _ScenarioSelector(logic: logic, selected: scenario),
            ),
          ),

          // ── start / stop button ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isRunning ? null : logic.startBenchmark,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始测试'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isRunning ? logic.stopBenchmark : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('停止'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isDynamicListScenario)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: _DynamicListControlCard(
                  selectedSize: listTargetSize,
                  selectedBatch: listMutationBatch,
                  rowCount: dynamicRows.length,
                  onSizeChanged: logic.setListTargetSize,
                  onBatchChanged: logic.setListMutationBatch,
                ),
              ),
            ),

          if (isDynamicListScenario)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: _DynamicListViewPanel(rows: dynamicRows),
              ),
            ),

          // ── ints (30) ───────────────────────────────────────────────────
          _sectionHeader('Int × 30'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 90,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 2.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, k) => _Chip('i$k', rI[k].toString(), Colors.blue),
                childCount: rI.length,
              ),
            ),
          ),

          // ── doubles (20) ────────────────────────────────────────────────
          _sectionHeader('Double × 20'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 2.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, k) => _Chip('d$k', rD[k].toStringAsFixed(1), Colors.teal),
                childCount: rD.length,
              ),
            ),
          ),

          // ── strings (20) ────────────────────────────────────────────────
          _sectionHeader('String × 20'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 2.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, k) =>
                    _Chip('s$k', rS[k].isEmpty ? '—' : rS[k], Colors.purple),
                childCount: rS.length,
              ),
            ),
          ),

          // ── bools (15) ──────────────────────────────────────────────────
          _sectionHeader('Bool × 15'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 80,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 2.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, k) => _Chip(
                  'b$k',
                  rB[k] ? 'T' : 'F',
                  rB[k] ? Colors.green : Colors.red,
                ),
                childCount: rB.length,
              ),
            ),
          ),

          // ── lists (10) ──────────────────────────────────────────────────
          _sectionHeader('List<int> × 10'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: rL.length,
              itemBuilder: (_, k) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _Chip(
                  'l$k',
                  rL[k].isEmpty ? '[]' : '[${rL[k].join(',')}]',
                  Colors.orange,
                ),
              ),
            ),
          ),

          // ── maps (5) ────────────────────────────────────────────────────
          _sectionHeader('Map × 5'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: rM.length,
              itemBuilder: (_, k) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _Chip(
                  'm$k',
                  rM[k].isEmpty
                      ? '{}'
                      : '{${rM[k].entries.map((e) => '${e.key}:${e.value}').join(',')}}',
                  Colors.brown,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    });
  }

  Widget _sectionHeader(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.updates,
    required this.elapsed,
    required this.fps,
    required this.isRunning,
  });

  final int updates;
  final int elapsed;
  final String fps;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      color: isRunning ? color.primaryContainer : color.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem('更新次数', '$updates', Icons.loop),
            _StatItem('耗时', '${elapsed}ms', Icons.timer_outlined),
            _StatItem('update/s', fps, Icons.speed),
            _StatItem(
              '状态',
              isRunning ? '运行中' : '已停止',
              isRunning ? Icons.play_circle : Icons.stop_circle_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _ScenarioSelector extends StatelessWidget {
  const _ScenarioSelector({required this.logic, required this.selected});
  final BenchLogic logic;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '测试场景',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: List.generate(BenchLogic.scenarios.length, (i) {
            final active = i == selected;
            return ChoiceChip(
              label: Text(
                BenchLogic.scenarios[i],
                style: const TextStyle(fontSize: 11),
              ),
              selected: active,
              onSelected: (_) {
                if (!logic.running.value) logic.selectScenario(i);
              },
            );
          }),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color.withAlpha(120)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 10,
              color: color.withAlpha(200),
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicListControlCard extends StatelessWidget {
  const _DynamicListControlCard({
    required this.selectedSize,
    required this.selectedBatch,
    required this.rowCount,
    required this.onSizeChanged,
    required this.onBatchChanged,
  });

  final int selectedSize;
  final int selectedBatch;
  final int rowCount;
  final void Function(int size) onSizeChanged;
  final void Function(int batch) onBatchChanged;

  @override
  Widget build(BuildContext context) {
    const sizes = [200, 500, 1000, 2000];
    const batches = [5, 20, 50, 100];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '动态 ListView 测试',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '当前行数: $rowCount',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              '列表规模',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sizes
                  .map(
                    (size) => ChoiceChip(
                      label: Text('$size'),
                      selected: selectedSize == size,
                      onSelected: (_) => onSizeChanged(size),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            const Text(
              '每帧变更条数',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: batches
                  .map(
                    (batch) => ChoiceChip(
                      label: Text('$batch'),
                      selected: selectedBatch == batch,
                      onSelected: (_) => onBatchChanged(batch),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicListViewPanel extends StatelessWidget {
  const _DynamicListViewPanel({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 320,
        child: ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, index) {
            final row = rows[index];
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              title: Text(
                row['title'].toString(),
                style: const TextStyle(fontSize: 12),
              ),
              subtitle: Text(
                'value=${row['value']}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                '#$index',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }
}
