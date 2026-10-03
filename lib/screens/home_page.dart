import 'user_profile.dart';   // ← 반드시 UserProfile 정의된 파일 import
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'medicine_search_page.dart';
import 'medicine_list_page.dart';
import 'medication_log_page.dart';
import 'prescription_capture_page.dart';
import 'setting_page.dart';      // ← 설정 화면 import
import 'notify_page.dart';        // ← 알림 화면 import
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  /// 회원가입 완료 후 HomeScreen 생성 시 프로필을 넘겨줍니다.
  final UserProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  bool checkboxValue1 = false;
  bool checkboxValue2 = false;
  bool checkboxValue3 = false;

  bool isLoadingMedicationStatus = false;

  DateTime selectedDate = DateTime.now();

  // ── 아침/점심/저녁 약 목록 ────────────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> medicineData = {
    '아침': <Map<String, dynamic>>[],
    '점심': <Map<String, dynamic>>[],
    '저녁': <Map<String, dynamic>>[],
  };

  List<Map<String, dynamic>> stockMedicines = [];

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addObserver(this,);

  initializeDateFormatting('ko_KR');

  _loadTodayMedicationStatus();
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this,);

  super.dispose();
  }

@override
void didChangeAppLifecycleState(
  AppLifecycleState state,) {
  if (state == AppLifecycleState.resumed) {_loadTodayMedicationStatus();}
}

  bool isMealCompleted(String meal) {
    if (meal == '아침') return checkboxValue1;
    if (meal == '점심') return checkboxValue2;
    if (meal == '저녁') return checkboxValue3;
    return false;
  }

  String _todayString() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  bool _isScheduleForDate(
  Map<String, dynamic> schedule,
  String date,
) {
  final startDate =
      (schedule['startDate'] ?? '')
          .toString()
          .trim();

  final endDate =
      (schedule['endDate'] ?? '')
          .toString()
          .trim();

  // 오늘보다 나중에 시작하는 일정
  if (startDate.isNotEmpty &&
      date.compareTo(startDate) < 0) {
    return false;
  }

  // 이미 종료된 일정
  if (endDate.isNotEmpty &&
      date.compareTo(endDate) > 0) {
    return false;
  }

  // 현재 비활성화된 일정
  if (schedule['active'] == false) {
    return false;
  }

  return true;
}

  String _targetTimeForLabel(String label) {
    if (label == '아침') return '08:30';
    if (label == '점심') return '13:30';
    if (label == '저녁') return '19:30';
    return '08:30';
  }

Future<void> _loadTodayMedicationStatus() async {
  try {
    setState(() {
      isLoadingMedicationStatus = true;
    });

    // --------------------------------
    // 1. 로그인 사용자 일정 / 로그 조회
    // --------------------------------

    final scheduleResult =
        await ApiService.getSchedules(
      widget.profile.userId,
    );

    final logResult =
        await ApiService.getLogs(
      widget.profile.userId,
    );

    debugPrint(
      '홈 복약 일정 조회 결과: '
      '$scheduleResult',
    );

    debugPrint(
      '홈 복용 기록 조회 결과: '
      '$logResult',
    );

    final List<dynamic> rawSchedules =
        scheduleResult['schedules'] ?? [];

    final List<dynamic> rawLogs =
        logResult['logs'] ?? [];

    final today = _todayString();

    // --------------------------------
    // 2. 오늘 실제 복용해야 하는 일정만 추출
    // --------------------------------

    final todaySchedules =
        rawSchedules
            .whereType<
                Map<String, dynamic>>()
            .where(
              (schedule) =>
                  _isScheduleForDate(
                schedule,
                today,
              ),
            ).toList();

// --------------------------------
// 현재 복용 중인 약 재고 생성
// schedule 1개당 재고 1개
// --------------------------------

final Map<String, Map<String, dynamic>>
    stockMap = {};

for (final schedule in todaySchedules) {
  final scheduleId =
      (schedule['scheduleId'] ?? '')
          .toString();

  if (scheduleId.isEmpty) {
    continue;
  }

  stockMap[scheduleId] = {
    'scheduleId': scheduleId,

    'medicineName':
        schedule['medicineName'] ??
            '약 이름 없음',

    'remainingCount':
        schedule['remainingCount'] ?? 0,

    'totalCount':
        schedule['totalCount'] ?? 0,

    'dailyCount':
        schedule['dailyCount'] ?? 0,

    'period':
        schedule['period'] ?? 0,

    'timing':
        schedule['timing'] ?? '',

    'startDate':
        schedule['startDate'] ?? '',

    'endDate':
        schedule['endDate'] ?? '',
  };
}

final serverStockMedicines =
    stockMap.values.toList();

    // --------------------------------
    // 3. 오늘 복용 완료 로그 추출
    // --------------------------------

    final todayLogs =
        rawLogs.where((log) {
      if (log is! Map) {
        return false;
      }

      final logDate =
          (log['date'] ?? '')
              .toString();

      final taken =
          log['taken'];

      return logDate == today &&
          taken != false;
    }).toList();

    // scheduleId + time
    final takenKeys =
        todayLogs.map((log) {
      return '${log['scheduleId']}_${log['time']}';
    }).toSet();

    // --------------------------------
    // 4. 아침/점심/저녁 실제 약 목록 생성
    // --------------------------------

    final Map<
        String,
        List<Map<String, dynamic>>>
        loadedMedicineData = {
      '아침':
          <Map<String, dynamic>>[],
      '점심':
          <Map<String, dynamic>>[],
      '저녁':
          <Map<String, dynamic>>[],
    };

    for (final schedule
        in todaySchedules) {
      final scheduleId =
          (schedule['scheduleId'] ?? '')
              .toString();

      final medicineName =
          (schedule['medicineName'] ??
                  '약 이름 없음')
              .toString();

      final rawTimes =
          schedule['times'];

      if (rawTimes is! List) {
        continue;
      }

      final times =
          rawTimes
              .map(
                (e) => e.toString(),
              )
              .toList();

      for (final label
          in [
        '아침',
        '점심',
        '저녁',
      ]) {
        final targetTime =
            _targetTimeForLabel(
          label,
        );

        if (!times.contains(
          targetTime,
        )) {
          continue;
        }

        final key =
            '${scheduleId}_$targetTime';

        final isTaken =
            takenKeys.contains(key);

        loadedMedicineData[
                label]!
            .add({
          'scheduleId':
              scheduleId,

          'name':
              medicineName,

          'medicineName':
              medicineName,

          'checked':
              isTaken,

          'checkedDate':
              isTaken
                  ? today
                  : '',

          'time':
              targetTime,

          'dailyCount':
              schedule[
                  'dailyCount'],

          'dosage':
              schedule[
                  'dosage'],

          'timing':
              schedule[
                  'timing'],

          'period':
              schedule[
                  'period'],

          'remainingCount':
              schedule[
                  'remainingCount'],

          'precaution':
              schedule[
                      'allergyWarning'] ??
                  '복용 전 의사 또는 약사와 상담하세요. '
                      '정해진 용량과 복용 시간을 지켜 주세요.',
        });
      }
    }

    // --------------------------------
    // 5. 시간대별 복용 완료 여부
    // --------------------------------

    bool isTimeCompleted(
      String label,
    ) {
      final medicines =
          loadedMedicineData[
                  label] ??
              [];

      if (medicines.isEmpty) {
        return false;
      }

      return medicines.every(
        (medicine) =>
            medicine[
                'checked'] ==
            true,
      );
    }

    if (!mounted) {
      return;
    }

    // --------------------------------
    // 6. 홈 화면 데이터 반영
    // --------------------------------

    setState(() {
      medicineData['아침'] =
          loadedMedicineData[
              '아침']!;

      medicineData['점심'] =
          loadedMedicineData[
              '점심']!;

      medicineData['저녁'] =
          loadedMedicineData[
              '저녁']!;

      stockMedicines = serverStockMedicines;

      checkboxValue1 =
          isTimeCompleted(
        '아침',
      );

      checkboxValue2 =
          isTimeCompleted(
        '점심',
      );

      checkboxValue3 =
          isTimeCompleted(
        '저녁',
      );

      isLoadingMedicationStatus =
          false;
    });

    debugPrint(
      '실제 홈 medicineData: '
      '$medicineData',
    );
  } catch (e) {
    debugPrint(
      '홈 복용 상태 조회 중 에러: '
      '$e',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isLoadingMedicationStatus =
          false;
    });
  }
}

  String get _todayLabel {
    final now       = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays  = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${formatter.format(now)} ${weekdays[now.weekday - 1]}';
  }

  int get _checkedCount {
    int count = 0;
    if (isMealCompleted('아침')) count++;
    if (isMealCompleted('점심')) count++;
    if (isMealCompleted('저녁')) count++;
    return count;
  }

  Future<void> _openMedicationLog() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          MedicationLogPage(
        initialDate:  selectedDate,
        medicineData:  medicineData,
        morningChecked:  checkboxValue1,
        lunchChecked:  checkboxValue2,
        dinnerChecked:  checkboxValue3,
        profile:  widget.profile,
      ),
    ),
  );

  if (!mounted) {return;}

  // 서버의 실제 logs 기준으로
  // 홈 상태 다시 복구
  await _loadTodayMedicationStatus();
}

  // ── 설정 화면 열기 (회원가입 데이터 전달) ──────────────────────────────────
  void _openSettings() async{
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingScreen(profile: widget.profile),
      ),
    );
    if (!mounted) {return;}
    await _loadTodayMedicationStatus();
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

              // ── 로고 + 날짜 + 알림/설정 아이콘 ──────────────────────────────
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
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotifyPage()),
                    );
                    },
                  ),
                  // ✅ 설정 아이콘 → SettingScreen 연결
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

              // ── 복약 카드 ──────────────────────────────────────────────────
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
                          // 타이머
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '다음 복약까지\n남은 시간',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '00:00',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 아침
                          _medicineCheckRow(
                            '아침',
                            isMealCompleted('아침'),
                            (v) => setState(() => checkboxValue1 = v!),
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '아침',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['아침']!,
                                    allMedicineData: medicineData,
                                    profile: widget.profile,  // ← UserProfile 전달
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              await _loadTodayMedicationStatus();
                            },
                          ),
                          const SizedBox(height: 6),

                          // 점심
                          _medicineCheckRow(
                            '점심',
                            isMealCompleted('점심'),
                            (v) => setState(() => checkboxValue2 = v!),
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '점심',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['점심']!,
                                    allMedicineData: medicineData,
                                    profile: widget.profile,  // ← UserProfile 전달
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              await _loadTodayMedicationStatus();
                            },
                          ),
                          const SizedBox(height: 6),

                          // 저녁
                          _medicineCheckRow(
                            '저녁',
                            isMealCompleted('저녁'),
                            (v) => setState(() => checkboxValue3 = v!),
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '저녁',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['저녁']!,
                                    allMedicineData: medicineData,
                                    profile: widget.profile,  // ← UserProfile 전달
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              await _loadTodayMedicationStatus();
                            },
                          ),
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

              // ── 약 검색 바 ────────────────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicineSearchPage(
                        userProfile: widget.profile,
                      ),
                    ),
                  );
                  if (!mounted) {return;}
                  await _loadTodayMedicationStatus();
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

              // ── 상비약 재고 ───────────────────────────────────────────────
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
                      // 알약판이 펼쳐지면 카드가 길어지므로 고정 높이 대신 최소 높이로 변경
                      constraints: const BoxConstraints(minHeight: 400),
                      decoration: const BoxDecoration(
                        color: Color(0x4CD9D9D9),
                        borderRadius: BorderRadius.only(
                          topLeft:  Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '내 약 재고',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
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
                                  onPressed: _openMedicationLog,
                                ),
                              ],
                            ),
                          ),
                          stockMedicines.isEmpty
                            ? const Padding(
                                padding:
                                    EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Center(
                                  child: Text(
                                    '현재 복용 중인 약이 없습니다.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: stockMedicines.map(_serverStockMedicineRow,).toList(),
                              ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 약 등록 버튼 ──────────────────────────────────────────────
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrescriptionCapturePage(
                          profile: widget.profile,
                        ),
                      ),
                    );
                    if (!mounted) {return;}
                    await _loadTodayMedicationStatus();
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
                  child: const Text(
                    '+ 약 등록',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

Widget _serverStockMedicineRow(
  Map<String, dynamic> medicine,
) {
  final name =
      (medicine['medicineName'] ??
              '약 이름 없음')
          .toString();

  final remaining =
      (medicine['remainingCount']
                  as num?)
              ?.toInt() ??
          0;

  final total =
      (medicine['totalCount']
                  as num?)
              ?.toInt() ??
          0;

  final dailyCount =
      (medicine['dailyCount']
                  as num?)
              ?.toInt() ??
          0;

  final period =
      (medicine['period']
                  as num?)
              ?.toInt() ??
          0;

  final timing =
      (medicine['timing'] ?? '')
          .toString();

  final bool isEmpty =
      remaining <= 0;

  final bool isLow =
      !isEmpty && remaining <= 5;

  final double progress =
      total > 0
          ? (remaining / total)
              .clamp(0.0, 1.0)
          : 0.0;

  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(8),
      border: Border.all(
        color: Colors.black12,
      ),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.medication_outlined,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Text(
              '$remaining정 남음',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                color:
                    isEmpty || isLow
                        ? Colors.redAccent
                        : Colors.black,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
        ),

        const SizedBox(height: 8),

        Text(
          '하루 $dailyCount회 · '
          '$period일 · '
          '$timing',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),

        if (isLow)
          const Padding(
            padding:
                EdgeInsets.only(top: 6),
            child: Text(
              '약이 얼마 남지 않았습니다.',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _medicineCheckRow(
    String label,
    bool value,
    void Function(bool?) onChanged,
    VoidCallback onArrowTap,
  ) {
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
          const Spacer(),
          GestureDetector(
            onTap: onArrowTap,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.keyboard_arrow_right_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 약병 위젯 ──────────────────────────────────────────────────────────────
class _MedicineBottle extends StatelessWidget {
  final int filledCount;
  const _MedicineBottle({required this.filledCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  120,
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
            left:   22,
            right:  22,
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