import 'user_profile.dart';   // ← 반드시 UserProfile 정의된 파일 import
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'medicine_search_page.dart';
import 'medicine_list_page.dart';
import 'medication_log_page.dart';
import 'prescription_capture_page.dart';  
import 'setting_page.dart';      // ← 설정 화면 import

class HomeScreen extends StatefulWidget {
  /// 회원가입 완료 후 HomeScreen 생성 시 프로필을 넘겨줍니다.
  final UserProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool checkboxValue1 = false;
  bool checkboxValue2 = false;
  bool checkboxValue3 = false;

  DateTime selectedDate = DateTime.now();

  // ── 아침/점심/저녁 약 목록 ────────────────────────────────────────────────
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

  // ── 상비약 재고 ────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> stockMedicines = [
    {'name': '타이레놀',   'remaining': 12},
    {'name': '이부프로펜', 'remaining': 8},
    {'name': '생리통약',   'remaining': 4},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
  }

  bool isMealCompleted(String meal) =>
      medicineData[meal]!.every((m) => m['checked'] == true);

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
        builder: (_) => MedicationLogPage(
          initialDate:    selectedDate,
          medicineData:   medicineData,
          morningChecked: checkboxValue1,
          lunchChecked:   checkboxValue2,
          dinnerChecked:  checkboxValue3,
        ),
      ),
    );
  }

  // ── 설정 화면 열기 (회원가입 데이터 전달) ──────────────────────────────────
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingScreen(profile: widget.profile),
      ),
    );
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
                    onPressed: () {},
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
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '아침',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['아침']!,
                                    allMedicineData: medicineData,
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() => checkboxValue1 = true);
                              }
                            },
                          ),
                          const SizedBox(height: 6),

                          // 점심
                          _medicineCheckRow(
                            '점심',
                            isMealCompleted('점심'),
                            (v) => setState(() => checkboxValue2 = v!),
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '점심',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['점심']!,
                                    allMedicineData: medicineData,
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() => checkboxValue2 = true);
                              }
                            },
                          ),
                          const SizedBox(height: 6),

                          // 저녁
                          _medicineCheckRow(
                            '저녁',
                            isMealCompleted('저녁'),
                            (v) => setState(() => checkboxValue3 = v!),
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicineListPage(
                                    timeLabel:      '저녁',
                                    morningChecked: checkboxValue1,
                                    lunchChecked:   checkboxValue2,
                                    dinnerChecked:  checkboxValue3,
                                    medicines:      medicineData['저녁']!,
                                    allMedicineData: medicineData,
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() => checkboxValue3 = true);
                              }
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MedicineSearchPage()),
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
                      height: 400,
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
                                    '내 상비약',
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
                          Expanded(
                            child: stockMedicines.isEmpty
                                ? const Center(
                                    child: Text(
                                      '등록된 상비약이 없습니다',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: stockMedicines
                                          .map(_stockMedicineRow)
                                          .toList(),
                                    ),
                                  ),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrescriptionCapturePage(),
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

  // ── 상비약 한 줄 ──────────────────────────────────────────────────────────
  Widget _stockMedicineRow(Map<String, dynamic> medicine) {
    final int  remaining = medicine['remaining'] as int? ?? 0;
    final bool isLow     = remaining <= 5;
    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_outlined, size: 22, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              medicine['name'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$remaining정 남음',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isLow ? Colors.redAccent : Colors.black87,
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