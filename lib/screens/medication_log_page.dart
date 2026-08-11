import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'medicine_search_page.dart';
import 'setting_page.dart';
import 'user_profile.dart';
import 'notify_page.dart';
import '../services/api_service.dart'; // ✅ ApiService import

class MedicationLogPage extends StatefulWidget {
  final DateTime initialDate;

  /// 홈 화면에서 관리하는 약 데이터를 그대로 전달
  final Map<String, List<Map<String, dynamic>>> medicineData;

  /// 홈 화면의 아침/점심/저녁 체크박스 상태 (복약 카드 표시용)
  final bool morningChecked;
  final bool lunchChecked;
  final bool dinnerChecked;
  final UserProfile profile;

  const MedicationLogPage({
    super.key,
    required this.initialDate,
    required this.medicineData,
    required this.morningChecked,
    required this.lunchChecked,
    required this.dinnerChecked,
    required this.profile,
  });

  @override
  State<MedicationLogPage> createState() => _MedicationLogPageState();
}

class _MedicationLogPageState extends State<MedicationLogPage> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  late DateTime selectedDate;

  bool showCalendar = true;

  bool breakfastExpanded = false;
  bool lunchExpanded = false;
  bool dinnerExpanded = false;

  List<dynamic> _schedules = [];
  List<dynamic> _logs = [];

  bool _isLoadingMedicationLogs = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
    selectedDate = widget.initialDate;

    _loadMedicationLogs();
  }

  Future<void> _loadMedicationLogs() async {
  try {
    setState(() {
      _isLoadingMedicationLogs = true;
    });

    final scheduleResult =
    await ApiService.getSchedules(widget.profile.userId);
    final logResult = await ApiService.getLogs(widget.profile.userId);

    debugPrint('복약 일정: $scheduleResult');
    debugPrint('복용 기록: $logResult');

    final List<dynamic> schedules =
        scheduleResult['schedules'] ?? [];

    final List<dynamic> logs =
        logResult['logs'] ?? [];

    if (!mounted) return;

    setState(() {
      _schedules = schedules;
      _logs = logs;
      _isLoadingMedicationLogs = false;
    });
  } catch (e) {
    debugPrint('복약 기록 불러오기 실패: $e');

    if (!mounted) return;

    setState(() {
      _isLoadingMedicationLogs = false;
      });
    }
  }
    void _openSettings() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingScreen(profile: widget.profile),
          ),
      );
    }

String _dateString(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

List<dynamic> _logsForDay(DateTime day) {
  final date = _dateString(day);

  return _logs.where((log) {
    return log['date'] == date;
  }).toList();
}

// 특정 날짜에 해당 시간대 약을 전부 복용했는지 확인
bool _isMealCompletedForDay(DateTime day, String meal) {
  final targetTime = _targetTimeForLabel(meal);

  // 해당 시간대에 먹어야 하는 약 목록
  final medicinesForTime = _schedules.where((schedule) {
    final times = schedule['times'];

    if (times is List) {
      return times.contains(targetTime);
    }

    return false;
  }).toList();

  // 해당 시간대 약이 아예 없으면 완료로 보지 않음
  if (medicinesForTime.isEmpty) {
    return false;
  }

  // 선택 날짜의 실제 복용 기록
  final dayLogs = _logsForDay(day);

  // scheduleId + time 으로 복용 여부 확인
  final takenKeys = dayLogs.map((log) {
    return '${log['scheduleId']}_${log['time']}';
  }).toSet();

  // 이 시간대의 모든 약을 복용했는지 확인
  return medicinesForTime.every((schedule) {
    final key = '${schedule['scheduleId']}_$targetTime';
    return takenKeys.contains(key);
  });
}

String _targetTimeForLabel(String label) {
  if (label == '아침') return '08:30';
  if (label == '점심') return '13:30';
  if (label == '저녁') return '19:30';

  return '08:30';
}

// 해당 날짜에 남은 복약 시간대 개수
int _remainingMealCount(DateTime day) {
  int remaining = 3;

  if (_isMealCompletedForDay(day, '아침')) {
    remaining--;
  }

  if (_isMealCompletedForDay(day, '점심')) {
    remaining--;
  }

  if (_isMealCompletedForDay(day, '저녁')) {
    remaining--;
  }

  return remaining;
}

  String get _todayLabel {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[now.weekday - 1];
    return '${formatter.format(now)} $weekday';
  }

  bool isMealCompleted(String meal) {
    if (meal == '아침') return widget.morningChecked;
    if (meal == '점심') return widget.lunchChecked;
    if (meal == '저녁') return widget.dinnerChecked;
    return false;
  }

  int get _checkedCount {
    int count = 0;
    if (isMealCompleted('아침')) count++;
    if (isMealCompleted('점심')) count++;
    if (isMealCompleted('저녁')) count++;
    return count;
  }

  void _goHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [

              // ── 로고 + 날짜 + 아이콘 (홈 화면과 완전히 동일) ──────
              Row(
                children: [
                  Image.asset(
                    'assets/images/medicare_logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _todayLabel,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                    onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotifyPage()),
                    );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.black),
                    onPressed: _openSettings,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── 복약 카드 (홈 화면과 동일, 읽기 전용) ────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MedicineBottle(filledCount: _checkedCount),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '다음 복약까지\n남은 시간',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '00:00',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _staticMedicineRow('아침', widget.morningChecked),
                          const SizedBox(height: 6),
                          _staticMedicineRow('점심', widget.lunchChecked),
                          const SizedBox(height: 6),
                          _staticMedicineRow('저녁', widget.dinnerChecked),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$_checkedCount/3 복용 완료',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 약 검색 바 (홈 화면과 동일) ───────────────────
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicineSearchPage(
                        userProfile: widget.profile,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.black, size: 22),
                      SizedBox(width: 8),
                      Text('약 검색', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 하단 영역 (캘린더 ↔ 날짜별 복약기록) ────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 500,
                      decoration: const BoxDecoration(
                        color: Color(0x4CD9D9D9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: _isLoadingMedicationLogs
                      ? const Center(
                      child: CircularProgressIndicator(),
                      )
                      : showCalendar
                      ? _buildCalendar()
                      : _buildLog(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 복약 카드용 - 읽기 전용 행 (체크 변경 불가, 화살표 없음)
  Widget _staticMedicineRow(String label, bool value) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: null,
            activeColor: Colors.green,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _topRightIcons() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.black, size: 25),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                showCalendar = true;
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 25),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _goHome,
          ),
        ],
      ),
    );
  }

  Widget _buildLog() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                '${selectedDate.month}월 ${selectedDate.day}일 복약 기록',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Colors.black,
                      size: 25,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        showCalendar = true;
                      });
                    },
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 25,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _goHome,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _mealSection('아침', breakfastExpanded, () {
                setState(() {
                  breakfastExpanded = !breakfastExpanded;
                });
              }),

              _mealSection('점심', lunchExpanded, () {
                setState(() {
                  lunchExpanded = !lunchExpanded;
                });
              }),

              _mealSection('저녁', dinnerExpanded, () {
                setState(() {
                  dinnerExpanded = !dinnerExpanded;
                });
              }),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildCalendar() {
  final today = DateTime.now();
  return Column(
    children: [
      // ✅ 아이콘 위쪽 여백 줄임
      Padding(
        padding: const EdgeInsets.only(top: 4, right: 4),
        child: Align(
          alignment: Alignment.topRight,
          child: _topRightIcons(),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            locale: 'ko_KR',
            startingDayOfWeek: StartingDayOfWeek.sunday,
            eventLoader: (day) {
            return _logsForDay(day);
              },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                selectedDate = selectedDay;
                showCalendar = false;
              });
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: true,
              selectedTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = ['일', '월', '화', '수', '목', '금', '토'][day.weekday % 7];
                Color color = Colors.black;
                if (day.weekday == DateTime.sunday) {color = Colors.red;}
                else if (day.weekday == DateTime.saturday) {color = Colors.blue;}
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                Color textColor = Colors.black;
                if (day.weekday == DateTime.sunday) {textColor = Colors.red;}
                else if (day.weekday == DateTime.saturday) {textColor = Colors.blue;}
                return Center(
                  child: Text('${day.day}', style: TextStyle(color: textColor)),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final hasSelectedOtherDay =
                    _selectedDay != null && !isSameDay(_selectedDay, today);
                return Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasSelectedOtherDay ? Colors.grey.shade600 : Colors.black,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
  // 이 날짜에 복용 기록이 하나도 없으면 표시하지 않음
  if (events.isEmpty) {
    return const SizedBox.shrink();
  }

  final remaining = _remainingMealCount(day);

  return Positioned(
    bottom: 1,
    right: 4,
    child: Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF80CBC4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,

      // ✅ 모두 복용했으면 체크
      child: remaining == 0
          ? const Icon(
              Icons.check,
              size: 14,
              color: Colors.black,
            )

          // ✅ 아니면 남은 복약 시간대 표시
          : Text(
              '$remaining',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
},
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _mealSection(
  String meal,
  bool expanded,
  VoidCallback onTap,
) {
  final targetTime = _targetTimeForLabel(meal);

  // 해당 시간에 먹어야 하는 약
  final medicines = _schedules.where((schedule) {
    final times = schedule['times'];

    if (times is List) {
      return times.contains(targetTime);
    }

    return false;
  }).toList();

  // 선택한 날짜의 실제 복용 기록
  final selectedLogs = _logsForDay(selectedDate);

  // 선택 날짜 + 해당 시간에 복용한 기록
  final logsForMeal = selectedLogs.where((log) {
    return log['time'] == targetTime;
  }).toList();

  // 실제 먹은 scheduleId
  final takenScheduleIds = logsForMeal.map((log) {
    return log['scheduleId'];
  }).toSet();

  // 몇 개 먹었는지 계산
  final checkedCount = medicines.where((medicine) {
    return takenScheduleIds.contains(
      medicine['scheduleId'],
    );
  }).length;

  final isCompleted =
      medicines.isNotEmpty &&
      checkedCount == medicines.length;

  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black12),
    ),
    child: Column(
      children: [
        ListTile(
          leading: Icon(
            isCompleted
                ? Icons.check_box
                : Icons.check_box_outline_blank,
          ),
          title: Text(
            '$meal      $checkedCount/${medicines.length} 복용',
          ),
          trailing: IconButton(
            icon: Icon(
              expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
            onPressed: onTap,
          ),
        ),

        if (expanded)
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 12,
            ),
            child: medicines.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '등록된 약이 없습니다.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    children: medicines.map((medicine) {
                      final scheduleId =
                          medicine['scheduleId'];

                      final isTaken =
                          takenScheduleIds.contains(
                        scheduleId,
                      );

                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTaken
                                  ? Icons.check_box
                                  : Icons
                                      .check_box_outline_blank,
                              size: 20,
                              color: isTaken
                                  ? Colors.green
                                  : Colors.black,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                medicine[
                                        'medicineName']
                                    ?.toString() ??
                                    '약 이름 없음',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
      ],
    ),
  );
}
}

class _MedicineBottle extends StatelessWidget {
  final int filledCount;

  const _MedicineBottle({required this.filledCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/medicine_bottle.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final filled = i < filledCount;
                return Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 35,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0xFF80CBC4)
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                );
              }).reversed.toList(),
            ),
          ),
        ],
      ),
    );
  }
}