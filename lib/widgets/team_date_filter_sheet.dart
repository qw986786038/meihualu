import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showTeamDateFilterSheet(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => TeamDateFilterSheet(initialDate: initialDate),
  );
}

String formatTeamDateFilterLabel(DateTime date) {
  final now = DateTime.now();
  final isToday = _isSameDay(date, now);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return isToday ? '$month月$day日(今)' : '$month月$day日';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class TeamDateFilterSheet extends StatefulWidget {
  const TeamDateFilterSheet({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<TeamDateFilterSheet> createState() => _TeamDateFilterSheetState();
}

class _TeamDateFilterSheetState extends State<TeamDateFilterSheet> {
  static const _primaryBlue = Color(0xFF1677FF);
  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];
  static final DateTime _minPickerDate = DateTime(2020, 1);

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  DateTime get _currentMonth =>
      DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth =>
      _visibleMonth.year == _currentMonth.year &&
      _visibleMonth.month == _currentMonth.month;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _goPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _goNextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      if (next.year > _currentMonth.year ||
          (next.year == _currentMonth.year &&
              next.month > _currentMonth.month)) {
        _visibleMonth = _currentMonth;
      } else {
        _visibleMonth = next;
      }
    });
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

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
    Navigator.pop(context, _selectedDate);
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _goPreviousMonth,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF333333),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        label: const Text(
                          '前一月',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickYearMonth,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_visibleMonth.year}年${_visibleMonth.month}月',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                          Icon(Icons.expand_more, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _isCurrentMonth
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: _goNextMonth,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF333333),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '后一月',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                    ),
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
              child: _buildCalendarGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(7, (column) {
              final index = row * 7 + column;
              final day = index - leadingEmpty + 1;
              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              return Expanded(child: _buildDayCell(day));
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(int day) {
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isSelected = _isSameDay(date, _selectedDate);

    return GestureDetector(
      onTap: () => _selectDate(date),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 40,
        child: Center(
          child: isToday
              ? Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '今',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : isSelected
                  ? Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      '$day',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
        ),
      ),
    );
  }
}
