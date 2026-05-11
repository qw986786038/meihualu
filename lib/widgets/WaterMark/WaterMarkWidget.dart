import 'dart:async';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

class WaterMarkWidget extends StatefulWidget {
  const WaterMarkWidget({
    super.key,
    required this.data,
    required this.updateData,
  });

  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> updateData;

  @override
  State<WaterMarkWidget> createState() => _WaterMarkWidgetState();
}

class _WaterMarkWidgetState extends State<WaterMarkWidget> {
  final Rx<DateTime> _now = DateTime.now().obs;
  Timer? _timer;
  static const _timeStyle = TextStyle(
    color: Colors.white,
    fontSize: 30,
    fontWeight: FontWeight.w700,
  );
  static const _metaStyle = TextStyle(color: Colors.white);
  static const _addressStyle = TextStyle(color: Colors.white);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitNowData(_now.value);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      _emitNowData(now);
      _now.value = now;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatHms(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatYmd(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _weekdayLabel(DateTime dt) {
    const labels = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return labels[dt.weekday - 1];
  }

  void _emitNowData(DateTime dt) {
    final next = Map<String, dynamic>.from(widget.data);
    next['time'] = _formatHms(dt);
    next['date'] = _formatYmd(dt);
    next['weekday'] = _weekdayLabel(dt);
    widget.updateData(next);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final now = _now.value;
      final address = (widget.data['address'] ?? '这里是地址').toString();
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatHms(now), style: _timeStyle),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 3,
                height: 30,
                color: Colors.amber,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatYmd(now), style: _metaStyle),
                  Text(_weekdayLabel(now), style: _metaStyle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(address, style: _addressStyle),
        ],
      );
    });
  }
}
