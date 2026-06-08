import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_search_page.dart';
import 'medicine_list_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool checkboxValue1 = false;
  bool checkboxValue2 = false;
  bool checkboxValue3 = false;

  String get _todayLabel {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[now.weekday - 1];
    return '${formatter.format(now)} $weekday';
  }

  int get _checkedCount {
    int count = 0;
    if (checkboxValue1) count++;
    if (checkboxValue2) count++;
    if (checkboxValue3) count++;
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

              // ── 로고 + 날짜 ────────────────────────
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

                          // 체크박스 행
                          _medicineCheckRow('아침', checkboxValue1, (v) {
                            setState(() => checkboxValue1 = v!);
                          }, () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MedicineListPage(timeLabel: '아침'),
                              ),
                            );
                            if (result == true) {
                              setState(() => checkboxValue1 = true);
                            }
                          }),

                          const SizedBox(height: 6),

                          _medicineCheckRow('점심', checkboxValue2, (v) {
                            setState(() => checkboxValue2 = v!);
                          }, () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MedicineListPage(timeLabel: '점심'),
                              ),
                            );
                            if (result == true) {
                              setState(() => checkboxValue2 = true);
                            }
                          }),

                          const SizedBox(height: 6),

                          _medicineCheckRow('저녁', checkboxValue3, (v) {
                            setState(() => checkboxValue3 = v!);
                          }, () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MedicineListPage(timeLabel: '저녁'),
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

                    // 반투명 영역
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: const BoxDecoration(
                        color: Color(0x4CD9D9D9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Stack(
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
                                  // 캘린더 화면 이동
                                },
                              ),
                            ),
                          ),

                          // 보호자 계정 추가 버튼
                          Positioned(
                            left: 15,
                            right: 15,
                            bottom: 20,
                            child: SizedBox(
                              height: 47,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD9D9D9),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: Colors.black),
                                  ),
                                ),
                                child: const Text(
                                  '보호자 계정 추가',
                                  style: TextStyle(fontSize: 17),
                                ),
                              ),
                            ),
                          ),
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

  // ✅ _HomeScreenState 안에 있어야 해요!
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
} // ← _HomeScreenState 닫는 괄호

// ✅ 클래스 밖에 있어야 해요!
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