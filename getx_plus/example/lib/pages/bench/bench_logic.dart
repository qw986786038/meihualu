import 'dart:async';
import 'dart:math';

import 'package:getx_plus/getx_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 100 reactive variables of different types, grouped by kind.
//
// ints  [0..29]   – 30 variables
// doubles [30..49] – 20 variables
// strings [50..69] – 20 variables
// booleans [70..84] – 15 variables
// lists [85..94]  – 10 variables
// maps  [95..99]  – 5 variables
// ─────────────────────────────────────────────────────────────────────────────

class BenchLogic extends GetxController {
  // ── int ──
  final i00 = 0.obs;
  final i01 = 0.obs;
  final i02 = 0.obs;
  final i03 = 0.obs;
  final i04 = 0.obs;
  final i05 = 0.obs;
  final i06 = 0.obs;
  final i07 = 0.obs;
  final i08 = 0.obs;
  final i09 = 0.obs;
  final i10 = 0.obs;
  final i11 = 0.obs;
  final i12 = 0.obs;
  final i13 = 0.obs;
  final i14 = 0.obs;
  final i15 = 0.obs;
  final i16 = 0.obs;
  final i17 = 0.obs;
  final i18 = 0.obs;
  final i19 = 0.obs;
  final i20 = 0.obs;
  final i21 = 0.obs;
  final i22 = 0.obs;
  final i23 = 0.obs;
  final i24 = 0.obs;
  final i25 = 0.obs;
  final i26 = 0.obs;
  final i27 = 0.obs;
  final i28 = 0.obs;
  final i29 = 0.obs;

  // ── double ──
  final d00 = 0.0.obs;
  final d01 = 0.0.obs;
  final d02 = 0.0.obs;
  final d03 = 0.0.obs;
  final d04 = 0.0.obs;
  final d05 = 0.0.obs;
  final d06 = 0.0.obs;
  final d07 = 0.0.obs;
  final d08 = 0.0.obs;
  final d09 = 0.0.obs;
  final d10 = 0.0.obs;
  final d11 = 0.0.obs;
  final d12 = 0.0.obs;
  final d13 = 0.0.obs;
  final d14 = 0.0.obs;
  final d15 = 0.0.obs;
  final d16 = 0.0.obs;
  final d17 = 0.0.obs;
  final d18 = 0.0.obs;
  final d19 = 0.0.obs;

  // ── String ──
  final s00 = ''.obs;
  final s01 = ''.obs;
  final s02 = ''.obs;
  final s03 = ''.obs;
  final s04 = ''.obs;
  final s05 = ''.obs;
  final s06 = ''.obs;
  final s07 = ''.obs;
  final s08 = ''.obs;
  final s09 = ''.obs;
  final s10 = ''.obs;
  final s11 = ''.obs;
  final s12 = ''.obs;
  final s13 = ''.obs;
  final s14 = ''.obs;
  final s15 = ''.obs;
  final s16 = ''.obs;
  final s17 = ''.obs;
  final s18 = ''.obs;
  final s19 = ''.obs;

  // ── bool ──
  final b00 = false.obs;
  final b01 = false.obs;
  final b02 = false.obs;
  final b03 = false.obs;
  final b04 = false.obs;
  final b05 = false.obs;
  final b06 = false.obs;
  final b07 = false.obs;
  final b08 = false.obs;
  final b09 = false.obs;
  final b10 = false.obs;
  final b11 = false.obs;
  final b12 = false.obs;
  final b13 = false.obs;
  final b14 = false.obs;

  // ── List<int> ──
  final l00 = <int>[].obs;
  final l01 = <int>[].obs;
  final l02 = <int>[].obs;
  final l03 = <int>[].obs;
  final l04 = <int>[].obs;
  final l05 = <int>[].obs;
  final l06 = <int>[].obs;
  final l07 = <int>[].obs;
  final l08 = <int>[].obs;
  final l09 = <int>[].obs;

  // ── Map<String, int> ──
  final m00 = <String, int>{}.obs;
  final m01 = <String, int>{}.obs;
  final m02 = <String, int>{}.obs;
  final m03 = <String, int>{}.obs;
  final m04 = <String, int>{}.obs;

  // ─────────────────────────────────────────────────────────────────────────
  // Benchmark state
  // ─────────────────────────────────────────────────────────────────────────

  /// How many scenario updates have fired this run.
  final updateCount = 0.obs;

  /// Elapsed time of last run (ms).
  final elapsedMs = 0.obs;

  /// Whether a benchmark is currently running.
  final running = false.obs;

  /// Currently selected scenario index.
  final scenarioIndex = 0.obs;

  // ── Dynamic ListView benchmark state ──
  final dynamicRows = <Map<String, dynamic>>[].obs;
  final listTargetSize = 500.obs;
  final listMutationBatch = 20.obs;
  int _listTick = 0;

  // Internal
  Timer? _timer;
  final _rng = Random();
  static const _tickMs = 16; // ~60 fps

  // ─────────────────────────────────────────────────────────────────────────
  // Scenarios
  // ─────────────────────────────────────────────────────────────────────────

  static const scenarios = [
    'Scenario 1 – 单变量高频 (int)',
    'Scenario 2 – 多 int 并发 (30×)',
    'Scenario 3 – 多类型混合 (int+double+string)',
    'Scenario 4 – bool 批量翻转 (15×)',
    'Scenario 5 – List/Map 批量更新',
    'Scenario 6 – 全量100变量同步更新',
    'Scenario 7 – 动态 ListView (随机增删改)',
  ];

  void selectScenario(int idx) => scenarioIndex.value = idx;

  void startBenchmark() {
    if (running.value) return;
    running.value = true;
    updateCount.value = 0;
    if (scenarioIndex.value == 6) {
      _seedDynamicRows(force: true);
    }
    final sw = Stopwatch()..start();

    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      _runScenarioTick(scenarioIndex.value);
      updateCount.value++;
      elapsedMs.value = sw.elapsedMilliseconds;
    });
  }

  void stopBenchmark() {
    _timer?.cancel();
    _timer = null;
    running.value = false;
  }

  @override
  void onClose() {
    stopBenchmark();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scenario ticks — each tick simulates one animation frame of updates
  // ─────────────────────────────────────────────────────────────────────────

  void _runScenarioTick(int idx) {
    switch (idx) {
      case 0:
        _tickSingleInt();
      case 1:
        _tick30Ints();
      case 2:
        _tickMixedTypes();
      case 3:
        _tick15Bools();
      case 4:
        _tickListsAndMaps();
      case 5:
        _tickAll100();
      case 6:
        _tickDynamicListView();
    }
  }

  /// Scenario 1 – Only i00 changes every tick.
  void _tickSingleInt() {
    i00.value = _rng.nextInt(10000);
  }

  /// Scenario 2 – All 30 int variables change synchronously in one tick.
  void _tick30Ints() {
    i00.value = _rng.nextInt(10000);
    i01.value = _rng.nextInt(10000);
    i02.value = _rng.nextInt(10000);
    i03.value = _rng.nextInt(10000);
    i04.value = _rng.nextInt(10000);
    i05.value = _rng.nextInt(10000);
    i06.value = _rng.nextInt(10000);
    i07.value = _rng.nextInt(10000);
    i08.value = _rng.nextInt(10000);
    i09.value = _rng.nextInt(10000);
    i10.value = _rng.nextInt(10000);
    i11.value = _rng.nextInt(10000);
    i12.value = _rng.nextInt(10000);
    i13.value = _rng.nextInt(10000);
    i14.value = _rng.nextInt(10000);
    i15.value = _rng.nextInt(10000);
    i16.value = _rng.nextInt(10000);
    i17.value = _rng.nextInt(10000);
    i18.value = _rng.nextInt(10000);
    i19.value = _rng.nextInt(10000);
    i20.value = _rng.nextInt(10000);
    i21.value = _rng.nextInt(10000);
    i22.value = _rng.nextInt(10000);
    i23.value = _rng.nextInt(10000);
    i24.value = _rng.nextInt(10000);
    i25.value = _rng.nextInt(10000);
    i26.value = _rng.nextInt(10000);
    i27.value = _rng.nextInt(10000);
    i28.value = _rng.nextInt(10000);
    i29.value = _rng.nextInt(10000);
  }

  /// Scenario 3 – 10 ints + 10 doubles + 10 strings change every tick.
  void _tickMixedTypes() {
    for (var k = 0; k < 10; k++) {
      _setIntByIndex(k, _rng.nextInt(10000));
      _setDoubleByIndex(k, _rng.nextDouble() * 10000);
      _setStringByIndex(k, 'upd-${_rng.nextInt(10000)}');
    }
  }

  /// Scenario 4 – All 15 bool variables flip every tick.
  void _tick15Bools() {
    b00.value = !b00.value;
    b01.value = !b01.value;
    b02.value = !b02.value;
    b03.value = !b03.value;
    b04.value = !b04.value;
    b05.value = !b05.value;
    b06.value = !b06.value;
    b07.value = !b07.value;
    b08.value = !b08.value;
    b09.value = !b09.value;
    b10.value = !b10.value;
    b11.value = !b11.value;
    b12.value = !b12.value;
    b13.value = !b13.value;
    b14.value = !b14.value;
  }

  /// Scenario 5 – All 10 lists and 5 maps are rebuilt every tick.
  void _tickListsAndMaps() {
    final n = _rng.nextInt(5) + 1;
    l00.value = List.generate(n, (_) => _rng.nextInt(100));
    l01.value = List.generate(n, (_) => _rng.nextInt(100));
    l02.value = List.generate(n, (_) => _rng.nextInt(100));
    l03.value = List.generate(n, (_) => _rng.nextInt(100));
    l04.value = List.generate(n, (_) => _rng.nextInt(100));
    l05.value = List.generate(n, (_) => _rng.nextInt(100));
    l06.value = List.generate(n, (_) => _rng.nextInt(100));
    l07.value = List.generate(n, (_) => _rng.nextInt(100));
    l08.value = List.generate(n, (_) => _rng.nextInt(100));
    l09.value = List.generate(n, (_) => _rng.nextInt(100));
    m00.value = {for (var j = 0; j < n; j++) 'k$j': _rng.nextInt(100)};
    m01.value = {for (var j = 0; j < n; j++) 'k$j': _rng.nextInt(100)};
    m02.value = {for (var j = 0; j < n; j++) 'k$j': _rng.nextInt(100)};
    m03.value = {for (var j = 0; j < n; j++) 'k$j': _rng.nextInt(100)};
    m04.value = {for (var j = 0; j < n; j++) 'k$j': _rng.nextInt(100)};
  }

  /// Scenario 6 – Every single one of the 100 variables changes every tick.
  void _tickAll100() {
    _tick30Ints();
    for (var k = 0; k < 20; k++) {
      _setDoubleByIndex(k, _rng.nextDouble() * 10000);
    }
    for (var k = 0; k < 20; k++) {
      _setStringByIndex(k, 'upd-${_rng.nextInt(10000)}');
    }
    _tick15Bools();
    _tickListsAndMaps();
  }

  // Scenario 7 – Mutate a ListView data source dynamically.
  // On each tick:
  // - randomly update N rows
  // - occasionally insert/remove rows
  // This is useful to evaluate list diff/rebuild pressure.
  void _tickDynamicListView() {
    if (dynamicRows.isEmpty) {
      _seedDynamicRows(force: true);
      return;
    }

    final rows = dynamicRows;
    final batch = listMutationBatch.value;
    for (var i = 0; i < batch; i++) {
      final index = _rng.nextInt(rows.length);
      final old = rows[index];
      rows[index] = {
        'id': old['id'],
        'title': 'Item ${old['id']}',
        'value': _rng.nextInt(100000),
        'updatedAt': DateTime.now().microsecondsSinceEpoch,
      };
    }

    _listTick++;
    final target = listTargetSize.value;
    final shouldInsert = _listTick % 4 == 0 && rows.length < target + 200;
    final shouldRemove = _listTick % 6 == 0 && rows.length > (target ~/ 2);

    if (shouldInsert) {
      final insertAt = rows.isEmpty ? 0 : _rng.nextInt(rows.length);
      final id = DateTime.now().microsecondsSinceEpoch;
      rows.insert(insertAt, {
        'id': id,
        'title': 'Item $id',
        'value': _rng.nextInt(100000),
        'updatedAt': id,
      });
    }

    if (shouldRemove && rows.isNotEmpty) {
      final removeAt = _rng.nextInt(rows.length);
      rows.removeAt(removeAt);
    }
  }

  void setListTargetSize(int size) {
    if (size == listTargetSize.value) return;
    listTargetSize.value = size;
    if (!running.value && scenarioIndex.value == 6) {
      _seedDynamicRows(force: true);
    }
  }

  void setListMutationBatch(int batch) {
    if (batch == listMutationBatch.value) return;
    listMutationBatch.value = batch;
  }

  void _seedDynamicRows({bool force = false}) {
    if (!force && dynamicRows.isNotEmpty) return;
    _listTick = 0;
    final size = listTargetSize.value;
    dynamicRows.value = List.generate(
      size,
      (index) => {
        'id': index,
        'title': 'Item $index',
        'value': _rng.nextInt(100000),
        'updatedAt': DateTime.now().microsecondsSinceEpoch,
      },
    );
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  void _setIntByIndex(int k, int v) {
    switch (k) {
      case 0:
        i00.value = v;
      case 1:
        i01.value = v;
      case 2:
        i02.value = v;
      case 3:
        i03.value = v;
      case 4:
        i04.value = v;
      case 5:
        i05.value = v;
      case 6:
        i06.value = v;
      case 7:
        i07.value = v;
      case 8:
        i08.value = v;
      case 9:
        i09.value = v;
    }
  }

  void _setDoubleByIndex(int k, double v) {
    switch (k) {
      case 0:
        d00.value = v;
      case 1:
        d01.value = v;
      case 2:
        d02.value = v;
      case 3:
        d03.value = v;
      case 4:
        d04.value = v;
      case 5:
        d05.value = v;
      case 6:
        d06.value = v;
      case 7:
        d07.value = v;
      case 8:
        d08.value = v;
      case 9:
        d09.value = v;
      case 10:
        d10.value = v;
      case 11:
        d11.value = v;
      case 12:
        d12.value = v;
      case 13:
        d13.value = v;
      case 14:
        d14.value = v;
      case 15:
        d15.value = v;
      case 16:
        d16.value = v;
      case 17:
        d17.value = v;
      case 18:
        d18.value = v;
      case 19:
        d19.value = v;
    }
  }

  void _setStringByIndex(int k, String v) {
    switch (k) {
      case 0:
        s00.value = v;
      case 1:
        s01.value = v;
      case 2:
        s02.value = v;
      case 3:
        s03.value = v;
      case 4:
        s04.value = v;
      case 5:
        s05.value = v;
      case 6:
        s06.value = v;
      case 7:
        s07.value = v;
      case 8:
        s08.value = v;
      case 9:
        s09.value = v;
      case 10:
        s10.value = v;
      case 11:
        s11.value = v;
      case 12:
        s12.value = v;
      case 13:
        s13.value = v;
      case 14:
        s14.value = v;
      case 15:
        s15.value = v;
      case 16:
        s16.value = v;
      case 17:
        s17.value = v;
      case 18:
        s18.value = v;
      case 19:
        s19.value = v;
    }
  }
}
