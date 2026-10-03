import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'medicine_search_page.dart';
import 'setting_page.dart';
import 'user_profile.dart';
import 'notify_page.dart';
import '../services/api_service.dart'; // ✅ ApiService import
import 'home_page.dart';
import 'dart:async';

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
  String _morningTime = '08:30';
  String _lunchTime = '13:30';
  String _dinnerTime = '19:30';

  Timer? _countdownTimer;

  @override
void initState() {
  super.initState();

  _focusedDay = widget.initialDate;
  _selectedDay = widget.initialDate;
  selectedDate = widget.initialDate;

  _loadMedicationLogs();

  _countdownTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) {
      if (mounted) {
        setState(() {});
      }
    },
  );
}

@override
void dispose() {
  _countdownTimer?.cancel();

  super.dispose();
}

  Future<void> _loadMedicationLogs() async {
    try {
      setState(() {
        _isLoadingMedicationLogs = true;
      });

      // 사용자 복약 시간
      final medicationTimes = await ApiService.getMedicationTimes(
        widget.profile.userId,
      );

      final scheduleResult = await ApiService.getSchedules(
        widget.profile.userId,
      );

      final logResult = await ApiService.getLogs(widget.profile.userId);

      debugPrint('복약 일정: $scheduleResult');

      debugPrint('복용 기록: $logResult');

      final List<dynamic> schedules = scheduleResult['schedules'] ?? [];

      final List<dynamic> logs = logResult['logs'] ?? [];

      if (!mounted) {
        return;
      }

      setState(() {
        _morningTime = medicationTimes['morning'] ?? '08:30';

        _lunchTime = medicationTimes['lunch'] ?? '13:30';

        _dinnerTime = medicationTimes['dinner'] ?? '19:30';

        _schedules = schedules;
        _logs = logs;

        _isLoadingMedicationLogs = false;
      });
    } catch (e) {
      debugPrint('복약 기록 불러오기 실패: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMedicationLogs = false;
      });
    }
  }

  Future<void> _openSettings() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          SettingScreen(
        profile: widget.profile,
      ),
    ),
  );

  if (!mounted) {
    return;
  }

  await _loadMedicationLogs();
}

  String _dateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _isScheduleForDate(Map<String, dynamic> schedule, String date) {
    final startDate = (schedule['startDate'] ?? '').toString().trim();

    final endDate = (schedule['endDate'] ?? '').toString().trim();

    if (startDate.isNotEmpty && date.compareTo(startDate) < 0) {
      return false;
    }

    if (endDate.isNotEmpty && date.compareTo(endDate) > 0) {
      return false;
    }

    return true;
  }

  List<Map<String, dynamic>> _schedulesForDay(DateTime day) {
    final date = _dateString(day);

    return _schedules
        .whereType<Map<String, dynamic>>()
        .where((schedule) => _isScheduleForDate(schedule, date))
        .toList();
  }

  List<dynamic> _logsForDay(DateTime day) {
    final date = _dateString(day);

    return _logs.where((log) {
      return log['date'] == date;
    }).toList();
  }

  bool _isMealCompletedForDay(DateTime day, String meal) {
    final schedulesForDay = _schedulesForDay(day);

    final medicinesForMeal = schedulesForDay.where((schedule) {
      return _scheduleBelongsToMeal(schedule, meal);
    }).toList();

    if (medicinesForMeal.isEmpty) {
      return false;
    }

    final dayLogs = _logsForDay(day);

    final mealLogs = dayLogs.where((log) {
      return _logBelongsToMeal(log, meal);
    }).toList();

    final takenScheduleIds = mealLogs.map((log) {
      return log['scheduleId']?.toString();
    }).toSet();

    return medicinesForMeal.every((schedule) {
      final scheduleId = (schedule['scheduleId'] ?? '').toString();

      return takenScheduleIds.contains(scheduleId);
    });
  }

  String _targetTimeForLabel(String label) {
    if (label == '아침') {
      return _morningTime;
    }

    if (label == '점심') {
      return _lunchTime;
    }

    if (label == '저녁') {
      return _dinnerTime;
    }

    return _morningTime;
  }

  bool _scheduleBelongsToMeal(Map<String, dynamic> schedule, String meal) {
    final rawCount = schedule['dailyCount'];

    int dailyCount = 0;

    if (rawCount is num) {
      dailyCount = rawCount.toInt();
    } else {
      dailyCount = int.tryParse(rawCount?.toString() ?? '') ?? 0;
    }

    // 1일 1회 → 아침
    if (dailyCount == 1) {
      return meal == '아침';
    }

    // 1일 2회 → 아침, 저녁
    if (dailyCount == 2) {
      return meal == '아침' || meal == '저녁';
    }

    // 1일 3회 → 아침, 점심, 저녁
    if (dailyCount == 3) {
      return meal == '아침' || meal == '점심' || meal == '저녁';
    }

    // 기타는 times로 확인
    final times = schedule['times'];

    if (times is List) {
      return times.contains(_targetTimeForLabel(meal));
    }

    return false;
  }

  bool _logBelongsToMeal(dynamic log, String meal) {
    if (log is! Map) {
      return false;
    }

    // 앞으로 meal 필드를 저장하게 되면
    // 그 값을 우선 사용
    final savedMeal = (log['meal'] ?? '').toString().trim();

    if (savedMeal.isNotEmpty) {
      return savedMeal == meal;
    }

    final time = (log['time'] ?? '').toString().trim();

    // 현재 설정 시간
    if (time == _morningTime) {
      return meal == '아침';
    }

    if (time == _lunchTime) {
      return meal == '점심';
    }

    if (time == _dinnerTime) {
      return meal == '저녁';
    }

    // 기존 기본시간 기록도 유지
    if (time == '08:30') {
      return meal == '아침';
    }

    if (time == '13:30') {
      return meal == '점심';
    }

    if (time == '19:30') {
      return meal == '저녁';
    }

    // 예전 사용자 지정시간을 위한 fallback
    final parts = time.split(':');

    if (parts.length != 2) {
      return false;
    }

    final hour = int.tryParse(parts[0]);

    if (hour == null) {
      return false;
    }

    if (hour < 11) {
      return meal == '아침';
    }

    if (hour < 17) {
      return meal == '점심';
    }

    return meal == '저녁';
  }

  int _remainingMealCount(DateTime day) {
    int remaining = 0;

    final schedulesForDay = _schedulesForDay(day);

    for (final meal in ['아침', '점심', '저녁']) {
      final hasMedication = schedulesForDay.any((schedule) {
        return _scheduleBelongsToMeal(schedule, meal);
      });

      if (!hasMedication) {
        continue;
      }

      if (!_isMealCompletedForDay(day, meal)) {
        remaining++;
      }
    }

    return remaining;
  }

DateTime _dateTimeForMedication(
  DateTime day,
  String time,
) {
  final parts = time.split(':');

  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}


bool _hasMedicationForMeal(
  DateTime day,
  String meal,
) {
  final schedules =
      _schedulesForDay(day);

  final targetTime =
      _targetTimeForLabel(meal);

  return schedules.any(
    (schedule) {
      final times =
          schedule['times'];

      if (times is! List) {
        return false;
      }

      return times.contains(
        targetTime,
      );
    },
  );
}


String get _nextMedicationCountdown {
  if (_isLoadingMedicationLogs) {
    return '--:--';
  }

  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final slots =
      <Map<String, String>>[
    {
      'label': '아침',
      'time': _morningTime,
    },
    {
      'label': '점심',
      'time': _lunchTime,
    },
    {
      'label': '저녁',
      'time': _dinnerTime,
    },
  ];

  DateTime? target;

  // ==========================
  // 오늘 남아 있는 복약 확인
  // ==========================
  for (final slot in slots) {
    final label =
        slot['label']!;

    final time =
        slot['time']!;

    // 오늘 이 시간대에 먹을 약이 없으면 제외
    if (!_hasMedicationForMeal(
      today,
      label,
    )) {
      continue;
    }

    // 이미 복용 완료했으면 제외
    if (_isMealCompletedForDay(
      today,
      label,
    )) {
      continue;
    }

    final dateTime =
        _dateTimeForMedication(
      today,
      time,
    );

    if (dateTime.isAfter(now)) {
      target = dateTime;
      break;
    }
  }

  // ==========================
  // 오늘 일정이 끝났으면
  // 내일 첫 복약 확인
  // ==========================
  if (target == null) {
    final tomorrow =
        today.add(
      const Duration(days: 1),
    );

    for (final slot in slots) {
      final label =
          slot['label']!;

      final time =
          slot['time']!;

      if (!_hasMedicationForMeal(
        tomorrow,
        label,
      )) {
        continue;
      }

      target =
          _dateTimeForMedication(
        tomorrow,
        time,
      );

      break;
    }
  }

  if (target == null) {
    return '--:--';
  }

  final seconds =
      target
          .difference(now)
          .inSeconds;

  if (seconds <= 0) {
    return '00:00';
  }

  final totalMinutes =
      (seconds / 60).ceil();

  final hours =
      totalMinutes ~/ 60;

  final minutes =
      totalMinutes % 60;

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(profile: widget.profile),
                        ),
                        (route) => false,
                      );
                    },
                    child: Image.asset(
                      'assets/images/medicare_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
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
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotifyPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.black,
                    ),
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
  mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      '다음 복약까지\n남은 시간',
      style: TextStyle(
        fontSize: 12,
        fontWeight:
            FontWeight.w500,
      ),
    ),

    Text(
      _nextMedicationCountdown,
      style:
          const TextStyle(
        fontSize: 32,
        fontWeight:
            FontWeight.w500,
      ),
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
                      builder: (context) =>
                          MedicineSearchPage(userProfile: widget.profile),
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
                          ? const Center(child: CircularProgressIndicator())
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 25),
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
          child: Align(alignment: Alignment.topRight, child: _topRightIcons()),
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
                final now = DateTime.now();

                final today = DateTime(now.year, now.month, now.day);

                final targetDay = DateTime(day.year, day.month, day.day);

                if (targetDay.isAfter(today)) {
                  return [];
                }
                return _schedulesForDay(day);
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
                  final text = [
                    '일',
                    '월',
                    '화',
                    '수',
                    '목',
                    '금',
                    '토',
                  ][day.weekday % 7];
                  Color color = Colors.black;
                  if (day.weekday == DateTime.sunday) {
                    color = Colors.red;
                  } else if (day.weekday == DateTime.saturday) {
                    color = Colors.blue;
                  }
                  return Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  Color textColor = Colors.black;
                  if (day.weekday == DateTime.sunday) {
                    textColor = Colors.red;
                  } else if (day.weekday == DateTime.saturday) {
                    textColor = Colors.blue;
                  }
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: textColor),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final hasSelectedOtherDay =
                      _selectedDay != null && !isSameDay(_selectedDay, today);
                  return Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: hasSelectedOtherDay
                          ? Colors.grey.shade600
                          : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _mealSection(String meal, bool expanded, VoidCallback onTap) {
    final schedulesForDay = _schedulesForDay(selectedDate);

    final medicines = schedulesForDay.where((schedule) {
      return _scheduleBelongsToMeal(schedule, meal);
    }).toList();

    // 선택 날짜의 실제 로그
    final selectedLogs = _logsForDay(selectedDate);

    // 해당 아침/점심/저녁 로그
    final logsForMeal = selectedLogs.where((log) {
      return _logBelongsToMeal(log, meal);
    }).toList();

    final takenScheduleIds = logsForMeal.map((log) {
      return log['scheduleId'];
    }).toSet();

    final checkedCount = medicines.where((medicine) {
      return takenScheduleIds.contains(medicine['scheduleId']);
    }).length;

    final isCompleted =
        medicines.isNotEmpty && checkedCount == medicines.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            ),
            title: Text('$meal      $checkedCount/${medicines.length} 복용'),
            trailing: IconButton(
              icon: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
              onPressed: onTap,
            ),
          ),

          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
              child: medicines.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '등록된 약이 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: medicines.map((medicine) {
                        final scheduleId = medicine['scheduleId'];

                        final isTaken = takenScheduleIds.contains(scheduleId);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isTaken
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: isTaken ? Colors.green : Colors.black,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  medicine['medicineName']?.toString() ??
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
