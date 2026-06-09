import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_search_page.dart';

class MedicineListPage extends StatefulWidget {
  final String timeLabel;
  final bool morningChecked;
  final bool lunchChecked;
  final bool dinnerChecked;
  final List<Map<String, dynamic>> medicines;

  const MedicineListPage({
    super.key,
    required this.timeLabel,
    required this.morningChecked,
    required this.lunchChecked,
    required this.dinnerChecked,
    required this.medicines,
  });

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  late bool morningChecked;
  late bool lunchChecked;
  late bool dinnerChecked;
  late List<Map<String, dynamic>> medicines;

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
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

  @override
  void initState() {
    super.initState();
    morningChecked = widget.morningChecked;
    lunchChecked = widget.lunchChecked;
    dinnerChecked = widget.dinnerChecked;
    medicines = widget.medicines;

    // ✅ 날짜가 바뀌면 체크 초기화
    final today = _todayString();
    for (var m in medicines) {
      if (m['checkedDate'] != today) {
        m['checked'] = false;
        m['checkedDate'] = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // ── 상단 영역 (홈과 동일) ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [

                  // 로고 + 날짜 + 아이콘
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

                  // 복약 카드
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black)),
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          Text(
                            '${widget.timeLabel} 복약 List',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          // ✅ X 버튼
                          GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: const Icon(Icons.close, size: 20, color: Colors.black),
                          ),
                        ],
                      ),
                    ),

                    // 약 목록
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: medicines.length,
                        separatorBuilder: (_, _) => const Divider(
                          thickness: 1,
                          color: Colors.black12,
                        ),
                        itemBuilder: (context, index) {
                          final medicine = medicines[index];
                          return Row(
                            children: [
                              Checkbox(
                                value: medicine['checked'],
                                onChanged: (v) {
                                  setState(() {
                                    medicines[index]['checked'] = v!;
                                    // ✅ 체크 날짜 저장
                                    medicines[index]['checkedDate'] =
                                        v ? _todayString() : '';
                                  });
                                  // ✅ 모두 체크되면 홈으로 돌아가며 완료 신호
                                  if (allChecked) {
                                    setState(() {
                                      if (widget.timeLabel == '아침') morningChecked = true;
                                      if (widget.timeLabel == '점심') lunchChecked = true;
                                      if (widget.timeLabel == '저녁') dinnerChecked = true;
                                    });
                                    Navigator.pop(context, true);
                                  }
                                },
                                activeColor: Colors.green,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  medicine['name'],
                                  style: const TextStyle(fontSize: 17),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_right_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 처방전 등록 버튼 ───────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCheckRow(String label, bool checked) {
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
            value: checked,
            onChanged: null,
            activeColor: Colors.green,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: label == widget.timeLabel ? Colors.green : Colors.black,
            ),
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.black, size: 18),
          const SizedBox(width: 4),
        ],
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