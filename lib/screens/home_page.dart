import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'medicine_search_page.dart';
import 'medicine_list_page.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool checkboxValue1 = false;
  bool checkboxValue2 = false;
  bool checkboxValue3 = false;
  bool showCalendar = false;
  bool breakfastExpanded = false;
  bool lunchExpanded = false;
  bool dinnerExpanded = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  DateTime selectedDate = DateTime.now();

  // ✅ 아침/점심/저녁 약 목록 각각 관리
  final Map<String, List<Map<String, dynamic>>> medicineData = {
    '아침': [
      {'name': '약 이름 1', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 2', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 3', 'checked': false, 'checkedDate': ''},
    ],
    '점심': [
      {'name': '약 이름 1', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 2', 'checked': false, 'checkedDate': ''},
    ],
    '저녁': [
      {'name': '약 이름 1', 'checked': false, 'checkedDate': ''},
      {'name': '약 이름 2', 'checked': false, 'checkedDate': ''},
    ],
  };

  @override
  void initState() {
    super.initState();
    // ✅ 'ko' 로케일 데이터 초기화 (DateFormat / TableCalendar에서 사용)
    initializeDateFormatting('ko_KR');
  }

  bool isMealCompleted(String meal) {
    final medicines = medicineData[meal]!;

    return medicines.every(
      (medicine) => medicine['checked'] == true,
    );
  }

  String get _todayLabel {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[now.weekday - 1];
    return '${formatter.format(now)} $weekday';
  }

  int get _checkedCount {
    int count = 0;
    if (isMealCompleted('아침')) count++;
    if (isMealCompleted('점심')) count++;
    if (isMealCompleted('저녁')) count++;
    return count;
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

              // ── 로고 + 날짜 + 아이콘 ──────────────
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
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── 복약 카드 ──────────────────────────
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
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '00:00',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // 아침
                          _medicineCheckRow('아침', isMealCompleted('아침'), (v) {
                            setState(() => checkboxValue1 = v!);
                          }, () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicineListPage(
                                  timeLabel: '아침',
                                  morningChecked: checkboxValue1,
                                  lunchChecked: checkboxValue2,
                                  dinnerChecked: checkboxValue3,
                                  medicines: medicineData['아침']!,
                                ),
                              ),
                            );
                            if (result == true) {
                              setState(() => checkboxValue1 = true);
                            }
                          }),

                          const SizedBox(height: 6),

                          // 점심
                          _medicineCheckRow('점심', isMealCompleted('점심'), (v) {
                            setState(() => checkboxValue2 = v!);
                          }, () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicineListPage(
                                  timeLabel: '점심',
                                  morningChecked: checkboxValue1,
                                  lunchChecked: checkboxValue2,
                                  dinnerChecked: checkboxValue3,
                                  medicines: medicineData['점심']!,
                                ),
                              ),
                            );
                            if (result == true) {
                              setState(() => checkboxValue2 = true);
                            }
                          }),

                          const SizedBox(height: 6),

                          // 저녁
                          _medicineCheckRow('저녁', isMealCompleted('저녁'), (v) {
                            setState(() => checkboxValue3 = v!);
                          }, () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicineListPage(
                                  timeLabel: '저녁',
                                  morningChecked: checkboxValue1,
                                  lunchChecked: checkboxValue2,
                                  dinnerChecked: checkboxValue3,
                                  medicines: medicineData['저녁']!,
                                ),
                              ),
                            );
                            if (result == true) {
                              setState(() => checkboxValue3 = true);
                            }
                          }),

                          const SizedBox(height: 6),

                          // 복용 완료 카운트
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

              // ── 약 검색 바 ─────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicineSearchPage(),
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

              // ── 하단 컨테이너 ──────────────────────
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
                      height: 450,
                      decoration: const BoxDecoration(
                        color: Color(0x4CD9D9D9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: showCalendar
                      ? _buildCalendar()
                      : Column(
                          children: [

                            // 캘린더 버튼
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: IconButton(
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
                              ),
                            ),

                            // 스크롤 가능한 콘텐츠 영역 (위쪽에 쌓임)
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Text(
                                      '${selectedDate.month}월 ${selectedDate.day}일 복약 기록',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    _mealSection(
                                      '아침',
                                      breakfastExpanded,
                                      () {
                                        setState(() {
                                          breakfastExpanded = !breakfastExpanded;
                                        });
                                      },
                                    ),

                                    _mealSection(
                                      '점심',
                                      lunchExpanded,
                                      () {
                                        setState(() {
                                          lunchExpanded = !lunchExpanded;
                                        });
                                      },
                                    ),

                                    _mealSection(
                                      '저녁',
                                      dinnerExpanded,
                                      () {
                                        setState(() {
                                          dinnerExpanded = !dinnerExpanded;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            const SizedBox(height: 14),
                          ],
                        ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 처방전 등록 버튼 ───────────────────
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3B3B3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text('+ 처방전 등록', style: TextStyle(fontSize: 20)),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildCalendar() {
  final today = DateTime.now();
  return Column(
    children: [
      Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
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
            onPressed: () {
              setState(() {
                showCalendar = false;
              });
            },
          ),
        ),
      ),
  Expanded(child: Padding(
    padding: const EdgeInsets.all(12),
    child: TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,

      locale: 'ko_KR',
      startingDayOfWeek: StartingDayOfWeek.sunday,

      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },

      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          selectedDate = selectedDay;

          showCalendar = false; // 날짜 선택 후 캘린더 닫기
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

        // 요일 표시
        dowBuilder: (context, day) {
          final text = ['일', '월', '화', '수', '목', '금', '토']
              [day.weekday % 7];

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

        // 기본 날짜 표시
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
              style: TextStyle(
                color: textColor,
              ),
            ),
          );
        },

        // 오늘 날짜
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

        // 선택된 날짜
        selectedBuilder: (context, day, focusedDay) {
          return Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
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
  final medicines = medicineData[meal]!;

  final checkedCount =
      medicines.where((m) => m['checked'] == true).length;

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
            checkedCount == medicines.length
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
            child: Column(
              children: medicines.map((medicine) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [

                      Icon(
                        (medicine['checked'] as bool? ?? false)
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      Text(medicine['name'] as String),
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
            onChanged: onChanged,
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
