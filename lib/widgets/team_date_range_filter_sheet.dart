import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TeamDateRangeFilterResult {
  const TeamDateRangeFilterResult({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

Future<TeamDateRangeFilterResult?> showTeamDateRangeFilterSheet(
  BuildContext context, {
  required DateTime initialStart,
  required DateTime initialEnd,
}) {
  return showModalBottomSheet<TeamDateRangeFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => TeamDateRangeFilterSheet(
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

class TeamDateRangeFilterSheet extends StatefulWidget {
  const TeamDateRangeFilterSheet({
    super.key,
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<TeamDateRangeFilterSheet> createState() =>
      _TeamDateRangeFilterSheetState();
}

class _TeamDateRangeFilterSheetState extends State<TeamDateRangeFilterSheet> {
  static const _primaryBlue = Color(0xFF1677FF);
  static const _rangeBlue = Color(0xFFEAF3FF);
  static const _weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];
  static final DateTime _minPickerDate = DateTime(2020, 1);

  late DateTime _visibleMonth;
  late DateTime? _rangeStart;
  late DateTime? _rangeEnd;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _currentMonth => DateTime(_today.year, _today.month);

  @override
  void initState() {
    super.initState();
    _rangeStart = _dateOnly(widget.initialStart);
    _rangeEnd = _dateOnly(widget.initialEnd);
    _visibleMonth = DateTime(_rangeEnd!.year, _rangeEnd!.month);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    final day = _dateOnly(date);
    return !day.isBefore(_rangeStart!) && !day.isAfter(_rangeEnd!);
  }

  void _onDateTap(DateTime date) {
    final day = _dateOnly(date);
    if (day.isAfter(_today)) return;

    setState(() {
      if (_rangeStart == null ||
          (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = day;
        _rangeEnd = null;
        return;
      }

      if (day.isBefore(_rangeStart!)) {
        _rangeStart = day;
        _rangeEnd = null;
        return;
      }

      _rangeEnd = day;
    });

    if (_rangeStart != null && _rangeEnd != null) {
      Navigator.pop(
        context,
        TeamDateRangeFilterResult(start: _rangeStart!, end: _rangeEnd!),
      );
    }
  }

  Future<void> _pickYearMonth() async {
    var picked = DateTime(_visibleMonth.year, _visibleMonth.month);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(
                          '取消',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _visibleMonth = DateTime(picked.year, picked.month);
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.monthYear,
                    initialDateTime: picked,
                    minimumDate: _minPickerDate,
                    maximumDate: _currentMonth,
                    onDateTimeChanged: (value) {
                      picked = DateTime(value.year, value.month);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '日期选择',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _buildMonthCalendar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCalendar() {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingEmpty = firstDay.weekday % 7;
    final prevMonthDays = DateTime(year, month, 0).day;
    final totalCells = leadingEmpty + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          top: 24,
          child: Text(
            '$month',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade100,
              height: 1,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickYearMonth,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$year年$month月',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
            Column(
              children: List.generate(rowCount, (row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: List.generate(7, (column) {
                      final index = row * 7 + column;
                      final day = index - leadingEmpty + 1;
                      if (day < 1) {
                        final prevDay = prevMonthDays + day;
                        return Expanded(
                          child: _buildOtherMonthCell(prevDay),
                        );
                      }
                      if (day > daysInMonth) {
                        return Expanded(
                          child: _buildOtherMonthCell(day - daysInMonth),
                        );
                      }
                      return Expanded(
                        child: _buildDayCell(DateTime(year, month, day)),
                      );
                    }),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherMonthCell(int day) {
    return SizedBox(
      height: 48,
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final day = date.day;
    final isFuture = date.isAfter(_today);
    final isStart =
        _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final inRange = _isInRange(date);
    final isSingle = isStart && isEnd;

    return GestureDetector(
      onTap: isFuture ? null : () => _onDateTap(date),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (inRange && !isSingle)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: isStart
                        ? 4
                        : isEnd
                            ? 4
                            : 0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _rangeBlue,
                      borderRadius: BorderRadius.horizontal(
                        left: isStart
                            ? const Radius.circular(4)
                            : Radius.zero,
                        right: isEnd
                            ? const Radius.circular(4)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              ),
            if (isStart || isEnd)
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      isStart ? '开始' : '结束',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              )
            else if (inRange)
              Text(
                '$day',
                style: const TextStyle(
                  color: _primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                '$day',
                style: TextStyle(
                  color: isFuture
                      ? Colors.grey.shade300
                      : Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}