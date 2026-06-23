import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_search_page.dart';

class MedicineListPage extends StatefulWidget {
  final String timeLabel;
  final bool morningChecked;
  final bool lunchChecked;
  final bool dinnerChecked;
  final List<Map<String, dynamic>> medicines;
  final Map<String, List<Map<String, dynamic>>> allMedicineData; // ✅ 추가

  const MedicineListPage({
    super.key,
    required this.timeLabel,
    required this.morningChecked,
    required this.lunchChecked,
    required this.dinnerChecked,
    required this.medicines,
    required this.allMedicineData, // ✅ 추가
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

  // ✅ 시간대별 약 목록 가져오기
  List<Map<String, dynamic>> _getMedicinesForLabel(String label) {
    return widget.allMedicineData[label] ?? [];
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
  final isExpanded = expandedIndexes.contains(index);
  final precaution = (medicine['precaution'] as String?) ??
      '복용 전 의사 또는 약사와 상담하세요. 정해진 용량과 복용 시간을 지켜 주세요.';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // ✅ 1번 - 체크박스만 남기고 동그라미 제거
          // ✅ 2번 - 체크박스로만 체크 가능하게 (onChanged 복구)
          Checkbox(
            value: medicine['checked'],
            onChanged: (v) {
              setState(() {
                medicines[index]['checked'] = v!;
                medicines[index]['checkedDate'] =
                    v ? _todayString() : '';
              });
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
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    expandedIndexes.remove(index);
                  } else {
                    expandedIndexes.add(index);
                  }
                });
              },
              child: Text(
                medicine['name'],
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
          // 주의사항 펼치기 화살표
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedIndexes.remove(index);
                } else {
                  expandedIndexes.add(index);
                }
              });
            },
            child: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.black,
              size: 20,
            ),
          ),
        ],
      ),

      // 펼쳐지는 주의사항
      if (isExpanded)
        Padding(
          padding: const EdgeInsets.only(
            left: 44,
            right: 8,
            top: 4,
            bottom: 8,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              precaution,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
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
                  child: const Text('+ 약 등록', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 3번 - 화살표 위치 통일 + 1번 - 다른 시간대 누르면 바로 이동
  Widget _timeCheckRow(String label, bool checked) {
    final bool isCurrent = label == widget.timeLabel;

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
              color: isCurrent ? Colors.green : Colors.black,
            ),
          ),
          const Spacer(),
          // ✅ 화살표 누르면 해당 시간대 리스트로 이동
          GestureDetector(
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
                        ),
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.keyboard_arrow_right_rounded,
                color: isCurrent ? Colors.grey : Colors.black,
                size: 18,
              ),
            ),
          ),
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