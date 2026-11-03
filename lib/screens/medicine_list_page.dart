import '../widgets/profile_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_search_page.dart';
import 'setting_page.dart';
import 'user_profile.dart';
import 'prescription_capture_page.dart';
import 'notify_page.dart';
import '../services/api_service.dart';
import 'dart:async';
import '../services/medication_widget_service.dart';

class MedicineListPage extends StatefulWidget {
  final String timeLabel;
  final bool morningChecked;
  final bool lunchChecked;
  final bool dinnerChecked;
  final List<Map<String, dynamic>> medicines;
  final Map<String, List<Map<String, dynamic>>> allMedicineData;
  final UserProfile profile;

  const MedicineListPage({
    super.key,
    required this.timeLabel,
    required this.morningChecked,
    required this.lunchChecked,
    required this.dinnerChecked,
    required this.medicines,
    required this.allMedicineData,
    required this.profile,
  });

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  late bool morningChecked;
  late bool lunchChecked;
  late bool dinnerChecked;
  late List<Map<String, dynamic>> medicines;
  final Set<int> expandedIndexes = {};
  final Set<int> _savingIndexes = {};
  bool _savingGroup = false;

  Timer? _countdownTimer;

  String _morningTime = '08:30';
  String _lunchTime = '13:30';
  String _dinnerTime = '19:30';

  String _todayString() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
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

    if (schedule['active'] == false) {
      return false;
    }

    return true;
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

  bool _logBelongsToMeal(dynamic log, String meal) {
    if (log is! Map) {
      return false;
    }

    // 앞으로 meal 값이 저장되면 우선 사용
    final savedMeal = (log['meal'] ?? '').toString().trim();

    if (savedMeal.isNotEmpty) {
      return savedMeal == meal;
    }

    // 기존 로그 호환
    final time = (log['time'] ?? '').toString().trim();

    final parts = time.split(':');

    if (parts.length != 2) {
      return false;
    }

    final hour = int.tryParse(parts[0]);

    if (hour == null) {
      return false;
    }

    if (meal == '아침') {
      return hour < 11;
    }

    if (meal == '점심') {
      return hour >= 11 && hour < 17;
    }

    if (meal == '저녁') {
      return hour >= 17;
    }

    return false;
  }

  Future<void> _loadMedicationTimes() async {
    try {
      final result = await ApiService.getMedicationTimes(widget.profile.userId);

      _morningTime = result['morning'] ?? '08:30';

      _lunchTime = result['lunch'] ?? '13:30';

      _dinnerTime = result['dinner'] ?? '19:30';
    } catch (e) {
      debugPrint('복약 시간 조회 실패: $e');
    }
  }

  Future<void> _initializePage() async {
    await _loadMedicationTimes();

    await _loadSchedulesFromServer();
  }

  Future<void> _loadSchedulesFromServer() async {
    try {
      final scheduleResult = await ApiService.getSchedules(
        widget.profile.userId,
      );

      final logResult = await ApiService.getLogs(widget.profile.userId);

      debugPrint('서버 약 목록 조회 결과: $scheduleResult');

      debugPrint('복용 기록 조회 결과: $logResult');

      final List<dynamic> rawSchedules = scheduleResult['schedules'] ?? [];

      final List<dynamic> logs = logResult['logs'] ?? [];

      final today = _todayString();

      final targetTime = _targetTimeForLabel(widget.timeLabel);

      // -----------------------------
      // 1. 오늘 날짜에 해당하는 일정만 남김
      // -----------------------------

      final List<Map<String, dynamic>> schedules = rawSchedules
          .whereType<Map<String, dynamic>>()
          .where((schedule) => _isScheduleForDate(schedule, today))
          .toList();

      // -----------------------------
      // 2. 오늘 실제 복용 기록만 추출
      // -----------------------------

      final todayLogs = logs.where((log) {
        if (log is! Map) {
          return false;
        }

        return log['date'] == today && log['taken'] != false;
      }).toList();

      Set<String> takenScheduleIdsForMeal(String meal) {
        return todayLogs
            .where((log) => _logBelongsToMeal(log, meal))
            .map((log) => (log['scheduleId'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();
      }

      final takenScheduleIds = takenScheduleIdsForMeal(widget.timeLabel);

      // -----------------------------
      // 3. 현재 시간대에 먹는 약만 생성
      // -----------------------------

      final loadedMedicines = schedules
          .where((schedule) {
            final times = schedule['times'];

            // times가 없는 일정은
            // 이 시간대 약으로 포함하지 않음
            if (times is! List) {
              return false;
            }

            return times.contains(targetTime);
          })
          .map<Map<String, dynamic>>((schedule) {
            final scheduleId = (schedule['scheduleId'] ?? '').toString();

            final isTaken = takenScheduleIds.contains(scheduleId);

            return {
              'scheduleId': scheduleId,
              'prescriptionGroupId': schedule['prescriptionGroupId'],
              'prescriptionCategory': schedule['prescriptionCategory'],

              'startDate': schedule['startDate'],

              'name': schedule['medicineName'] ?? '약 이름 없음',

              'medicineName': schedule['medicineName'] ?? '약 이름 없음',

              'checked': isTaken,

              'checkedDate': isTaken ? today : '',

              'time': targetTime,

              'dailyCount': schedule['dailyCount'],

              'dosage': schedule['dosage'],

              'timing': schedule['timing'],

              'period': schedule['period'],

              'remainingCount': schedule['remainingCount'],

              'precaution':
                  schedule['allergyWarning'] ??
                  '복용 전 의사 또는 약사와 상담하세요. '
                      '정해진 용량과 복용 시간을 지켜 주세요.',
            };
          })
          .toList();

      // -----------------------------
      // 4. 아침/점심/저녁 완료 여부 계산
      // -----------------------------

      bool isTimeCompleted(String label) {
        final time = _targetTimeForLabel(label);

        final medicinesForTime = schedules.where((schedule) {
          final times = schedule['times'];

          if (times is! List) {
            return false;
          }

          return times.contains(time);
        }).toList();

        if (medicinesForTime.isEmpty) {
          return false;
        }

        final takenIds = takenScheduleIdsForMeal(label);

        return medicinesForTime.every((schedule) {
          final scheduleId = (schedule['scheduleId'] ?? '').toString();

          return takenIds.contains(scheduleId);
        });
      }

      if (!mounted) {
        return;
      }

      setState(() {
        medicines = loadedMedicines;

        morningChecked = isTimeCompleted('아침');

        lunchChecked = isTimeCompleted('점심');

        dinnerChecked = isTimeCompleted('저녁');
      });
    } catch (e) {
      debugPrint('서버 약 목록/복용 기록 조회 중 에러: $e');
    }
  }

  Future<void> _handleMedicineChecked(int index, bool? value) async {
    if (_savingGroup || _savingIndexes.contains(index)) {
      return;
    }

    final medicine = medicines[index];

    // 체크가 아닌 경우 API 호출 안 함
    if (value != true) {
      return;
    }

    final scheduleId = (medicine['scheduleId'] ?? '').toString().trim();

    final medicineName = (medicine['medicineName'] ?? medicine['name'] ?? '')
        .toString()
        .trim();

    final time = (medicine['time'] ?? '').toString().trim();

    if (scheduleId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '복약 일정 ID가 없어 '
              '복용 기록을 저장할 수 없습니다.',
            ),
          ),
        );
      }

      return;
    }

    if (medicineName.isEmpty || time.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('복약 정보가 올바르지 않습니다.')));
      }

      return;
    }

    setState(() {
      _savingIndexes.add(index);
    });

    try {
      final result = await ApiService.markAsTaken(
        userId: widget.profile.userId,

        scheduleId: scheduleId,

        medicineName: medicineName,

        date: _todayString(),

        time: time,
      );

      debugPrint('복용 완료 결과: $result');

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        setState(() {
          medicines[index]['checked'] = true;

          medicines[index]['checkedDate'] = _todayString();

          if (result['remainingCount'] != null) {
            medicines[index]['remainingCount'] = result['remainingCount'];
          }

          _updateCurrentTimeCheckStatus();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$medicineName 복용 완료'),
            duration: const Duration(seconds: 1),
          ),
        );

        // 서버 데이터 기준으로 다시 동기화
        await _loadSchedulesFromServer();
      } else {
        final message =
            (result['message'] ?? result['detail'] ?? '복용 기록 저장에 실패했습니다.')
                .toString();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        // 실패하면 서버 상태로 복구
        await _loadSchedulesFromServer();
      }
    } catch (e) {
      debugPrint('복용 완료 중 에러: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '복용 기록 저장 실패: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );

      await _loadSchedulesFromServer();
    } finally {
      if (mounted) {
        setState(() {
          _savingIndexes.remove(index);
        });
      }
    }
  }

  // 처방전 등록 시 부여된 groupId 기준으로 묶습니다.
  // 그룹 ID가 없는 오래된 일정은 각각 별도 항목으로 유지합니다.
  Map<String, List<int>> _groupedMedicineIndexes() {
    final groups = <String, List<int>>{};
    for (var i = 0; i < medicines.length; i++) {
      final medicine = medicines[i];
      final groupId = (medicine['prescriptionGroupId'] ?? '').toString().trim();
      final scheduleId = (medicine['scheduleId'] ?? '').toString().trim();
      final key = groupId.isNotEmpty
          ? 'group:$groupId'
          : 'legacy:$scheduleId:$i';
      groups.putIfAbsent(key, () => <int>[]).add(i);
    }
    return groups;
  }

  Future<void> _checkPrescriptionGroup(List<int> indexes) async {
    if (_savingGroup || _savingIndexes.isNotEmpty) return;
    final pending = indexes
        .where((i) => medicines[i]['checked'] != true)
        .toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 모두 복용 완료된 처방전입니다.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('처방전 복용 완료'),
        content: Text(
          '아직 복용하지 않은 약 ${pending.length}개를 모두 복용하셨나요?\n복용 완료를 선택하면 복용 기록과 남은 약 수량이 변경됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('복용 완료'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _savingGroup = true);
    var successCount = 0;
    final failures = <String>[];
    try {
      for (final index in pending) {
        final medicine = medicines[index];
        final scheduleId = (medicine['scheduleId'] ?? '').toString().trim();
        final medicineName =
            (medicine['medicineName'] ?? medicine['name'] ?? '')
                .toString()
                .trim();
        final time = (medicine['time'] ?? '').toString().trim();
        if (scheduleId.isEmpty || medicineName.isEmpty || time.isEmpty) {
          failures.add(medicineName.isEmpty ? '약 정보 없음' : medicineName);
          continue;
        }
        try {
          final result = await ApiService.markAsTaken(
            userId: widget.profile.userId,
            scheduleId: scheduleId,
            medicineName: medicineName,
            date: _todayString(),
            time: time,
          );
          if (result['success'] == true) {
            successCount++;
            if (mounted) {
              setState(() {
                medicines[index]['checked'] = true;
                medicines[index]['checkedDate'] = _todayString();
                if (result['remainingCount'] != null) {
                  medicines[index]['remainingCount'] = result['remainingCount'];
                }
                _updateCurrentTimeCheckStatus();
              });
            }
          } else {
            failures.add(medicineName);
          }
        } catch (e) {
          failures.add(medicineName);
          debugPrint('처방전 일괄 복용 중 오류 ($medicineName): $e');
        }
      }
    } finally {
      // 실제 서버 기록을 기준으로 동기화합니다. 일부 요청만 성공해도 유지합니다.
      if (mounted) {
        await _loadSchedulesFromServer();
        await _syncMedicationWidget();

        if (mounted) {
          setState(() => _savingGroup = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failures.isEmpty
                    ? '$successCount개 약 복용 완료'
                    : '$successCount개 완료, ${failures.length}개 실패: ${failures.join(', ')}',
              ),
            ),
          );
        }
      }
    }
  }

  void _updateCurrentTimeCheckStatus() {
    final bool currentTimeAllChecked =
        medicines.isNotEmpty && medicines.every((m) => m['checked'] == true);

    if (widget.timeLabel == '아침') {
      morningChecked = currentTimeAllChecked;
    } else if (widget.timeLabel == '점심') {
      lunchChecked = currentTimeAllChecked;
    } else if (widget.timeLabel == '저녁') {
      dinnerChecked = currentTimeAllChecked;
    }
  }

  bool _isMealChecked(String label) {
    if (label == '아침') {
      return morningChecked;
    }

    if (label == '점심') {
      return lunchChecked;
    }

    if (label == '저녁') {
      return dinnerChecked;
    }

    return false;
  }

  bool _hasMedicineForMeal(String label) {
    return _getMedicinesForLabel(label).isNotEmpty;
  }

  DateTime _dateTimeForTime(String value, {int addDays = 0}) {
    final parts = value.split(':');

    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day + addDays,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String get _nextMedicationCountdown {
    final now = DateTime.now();

    final slots = <Map<String, String>>[
      {'label': '아침', 'time': _morningTime},
      {'label': '점심', 'time': _lunchTime},
      {'label': '저녁', 'time': _dinnerTime},
    ];

    DateTime? target;

    // =========================
    // 오늘 남아 있는 복약 찾기
    // =========================

    for (final slot in slots) {
      final label = slot['label']!;

      final time = slot['time']!;

      // 해당 시간대에 약이 없으면 제외
      if (!_hasMedicineForMeal(label)) {
        continue;
      }

      // 이미 복용 완료했으면 제외
      if (_isMealChecked(label)) {
        continue;
      }

      final dateTime = _dateTimeForTime(time);

      if (dateTime.isAfter(now)) {
        target = dateTime;
        break;
      }
    }

    // =========================
    // 오늘 복약이 끝났으면
    // 다음날 첫 복약
    // =========================

    if (target == null) {
      for (final slot in slots) {
        final label = slot['label']!;

        final time = slot['time']!;

        if (!_hasMedicineForMeal(label)) {
          continue;
        }

        target = _dateTimeForTime(time, addDays: 1);

        break;
      }
    }

    if (target == null) {
      return '--:--';
    }

    final seconds = target.difference(now).inSeconds;

    if (seconds <= 0) {
      return '00:00';
    }

    final totalMinutes = (seconds / 60).ceil();

    final hours = totalMinutes ~/ 60;

    final minutes = totalMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _syncMedicationWidget() async {
  final now = DateTime.now();

  final slots = <Map<String, String>>[
    {'label': '아침', 'time': _morningTime},
    {'label': '점심', 'time': _lunchTime},
    {'label': '저녁', 'time': _dinnerTime},
  ];

  DateTime? target;

  // 오늘 남아 있는 다음 복약 시간 찾기
  for (final slot in slots) {
    final label = slot['label']!;
    final time = slot['time']!;

    if (!_hasMedicineForMeal(label) || _isMealChecked(label)) {
      continue;
    }

    final dateTime = _dateTimeForTime(time);
    if (dateTime.isAfter(now)) {
      target = dateTime;
      break;
    }
  }

  // 오늘 남은 복약이 없으면 다음 날 첫 복약 시간
  if (target == null) {
    for (final slot in slots) {
      final label = slot['label']!;
      final time = slot['time']!;

      if (!_hasMedicineForMeal(label)) continue;

      target = _dateTimeForTime(time, addDays: 1);
      break;
    }
  }

  final nextDoseTime = target == null
      ? '--:--'
      : '${target.hour.toString().padLeft(2, '0')}:'
          '${target.minute.toString().padLeft(2, '0')}';

  await updateMedicationWidget(
    nextDoseTime: nextDoseTime,
    morningDone: _isMealChecked('아침'),
    lunchDone: _isMealChecked('점심'),
    dinnerDone: _isMealChecked('저녁'),
  );
}

  String get _todayLabel {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[now.weekday - 1];
    return '${formatter.format(now)} $weekday';
  }

  bool get allChecked => medicines.every((m) => m['checked'] == true);

  int get _checkedCount {
    int count = 0;
    if (morningChecked) count++;
    if (lunchChecked) count++;
    if (dinnerChecked) count++;
    return count;
  }

  List<Map<String, dynamic>> _getMedicinesForLabel(String label) {
    return widget.allMedicineData[label] ?? <Map<String, dynamic>>[];
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingScreen(profile: widget.profile)),
    );
  }

  @override
  void initState() {
    super.initState();
    morningChecked = widget.morningChecked;
    lunchChecked = widget.lunchChecked;
    dinnerChecked = widget.dinnerChecked;
    medicines = widget.medicines;

    final today = _todayString();
    for (var m in medicines) {
      if (m['checkedDate'] != today) {
        m['checked'] = false;
        m['checkedDate'] = '';
      }
    }

    _initializePage();

    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 영역 ──────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Column(
                children: [
                  // 로고 + 날짜 + 아이콘
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          child: Image.asset(
                            'assets/images/medicare_logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
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
                            MaterialPageRoute(
                              builder: (_) =>
                                  NotifyPage(
                                    userId: widget.profile.userId, 
                                    profile: widget.profile,
                                    ),
                            ),
                          );
                        },
                      ),
                      ProfilePopupMenu(
                        profile: widget.profile,
                        onReturn: _loadSchedulesFromServer,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 복약 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD9DCE8)),
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
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  Text(
                                    _nextMedicationCountdown,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _timeCheckRow('아침', morningChecked),
                              const SizedBox(height: 6),
                              _timeCheckRow('점심', lunchChecked),
                              const SizedBox(height: 6),
                              _timeCheckRow('저녁', dinnerChecked),
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

                  // 약 검색 바
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
                ],
              ),
            ),
            // ── 복약 List 영역 ─────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    // 타이틀 + X 버튼
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black)),
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          Text(
                            '${widget.timeLabel} 복약 List',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 처방전 별칭별 목록 (그룹 체크 / 개별 체크)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        children: _groupedMedicineIndexes().entries.map((
                          entry,
                        ) {
                          final indexes = entry.value;
                          final first = medicines[indexes.first];
                          final category = indexes
                              .map(
                                (i) =>
                                    (medicines[i]['prescriptionCategory'] ?? '')
                                        .toString()
                                        .trim(),
                              )
                              .firstWhere(
                                (name) => name.isNotEmpty && name != '미분류 처방전',
                                orElse: () => '',
                              );

                          // 같은 처방전의 약들 중 가장 빠른 시작일
                          final startDates =
                              indexes
                                  .map((i) {
                                    final raw =
                                        (medicines[i]['startDate'] ?? '')
                                            .toString()
                                            .trim();

                                    return DateTime.tryParse(raw);
                                  })
                                  .whereType<DateTime>()
                                  .toList()
                                ..sort();

                          // 별칭이 없으면 날짜로 처방전 이름 생성
                          final dateTitle = startDates.isNotEmpty
                              ? '${DateFormat('yyyy.MM.dd').format(startDates.first)} 처방전'
                              : '날짜 미상 처방전';

                          final title = category.isEmpty ? dateTitle : category;

                          final completed = indexes
                              .where((i) => medicines[i]['checked'] == true)
                              .length;
                          final allChecked = completed == indexes.length;
                          final partiallyChecked = completed > 0 && !allChecked;

                          return Card(
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Color(0xFFDADADA)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ExpansionTile(
                              key: PageStorageKey('prescription_${entry.key}'),
                              initiallyExpanded: false,

                              // 펼쳤을 때와 접었을 때 모두 흰색
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: Colors.white,

                              // ExpansionTile 기본 테두리 제거
                              shape: const Border(),
                              collapsedShape: const Border(),

                              // 처방전 제목 영역
                              tilePadding: const EdgeInsets.only(
                                left: 8,
                                right: 16,
                              ),
                              childrenPadding: EdgeInsets.zero,
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,

                              leading: Checkbox(
                                value: allChecked
                                    ? true
                                    : (partiallyChecked ? null : false),
                                tristate: true,
                                onChanged:
                                    _savingGroup ||
                                        _savingIndexes.isNotEmpty ||
                                        allChecked
                                    ? null
                                    : (_) => _checkPrescriptionGroup(indexes),
                                activeColor: Colors.green,
                              ),

                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              subtitle: Text(
                                '$completed/${indexes.length}개 복용 완료',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),

                              children: indexes.map((index) {
                                final medicine = medicines[index];

                                return Column(
                                  children: [
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFE8E8E8),
                                    ),
                                    Padding(
                                      // 처방전보다 안쪽으로 들여쓰기
                                      padding: const EdgeInsets.only(
                                        left: 48,
                                        right: 16,
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: Checkbox(
                                              value:
                                                  medicine['checked'] == true,
                                              onChanged:
                                                  _savingGroup ||
                                                      _savingIndexes.contains(
                                                        index,
                                                      )
                                                  ? null
                                                  : (value) =>
                                                        _handleMedicineChecked(
                                                          index,
                                                          value,
                                                        ),
                                              activeColor: Colors.green,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (medicine['name'] ??
                                                          '약 이름 없음')
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '하루 ${medicine['dailyCount'] ?? '-'}회 / '
                                                  '${medicine['period'] ?? '-'}일 / '
                                                  '남은 수량 ${medicine['remainingCount'] ?? '-'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PrescriptionCapturePage(profile: widget.profile),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3B3B3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text('+ 약 등록', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 칸 전체를 탭하면 해당 시간대 리스트로 이동
  Widget _timeCheckRow(String label, bool checked) {
    final bool isCurrent = label == widget.timeLabel;

    return GestureDetector(
      onTap: isCurrent
          ? null
          : () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineListPage(
                    timeLabel: label,
                    morningChecked: morningChecked,
                    lunchChecked: lunchChecked,
                    dinnerChecked: dinnerChecked,
                    medicines: _getMedicinesForLabel(label),
                    allMedicineData: widget.allMedicineData,
                    profile: widget.profile,
                  ),
                ),
              );
            },
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: null,
              activeColor: Colors.green,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCurrent ? Colors.green : Colors.black,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.keyboard_arrow_right_rounded,
                color: isCurrent ? Colors.grey : Colors.black,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 약병 위젯 ──────────────────────────────────
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
                        ? const Color.fromARGB(255, 163, 145, 215)
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
