import 'package:flutter/material.dart';

class MedicineListPage extends StatefulWidget {
  final String timeLabel; // '아침', '점심', '저녁'

  const MedicineListPage({super.key, required this.timeLabel});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  // 약 목록 (이름, 체크 여부)
  List<Map<String, dynamic>> medicines = [
    {'name': '약 이름 1', 'checked': false},
    {'name': '약 이름 2', 'checked': false},
    {'name': '약 이름 3', 'checked': false},
  ];

  // ✅ 모든 약을 먹었는지 확인
  bool get allChecked => medicines.every((m) => m['checked'] == true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.timeLabel} 복약 List'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black, height: 1),
        ),
      ),
      body: Column(
        children: [

          // ── 약 목록 ────────────────────────────
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
                    // 체크박스
                    Checkbox(
                      value: medicine['checked'],
                      onChanged: (v) {
                        setState(() {
                          medicines[index]['checked'] = v!;
                        });

                        // ✅ 모두 체크되면 이전 화면에 완료 신호 전달
                        if (allChecked) {
                          Navigator.pop(context, true);
                        }
                      },
                      activeColor: Colors.green,
                      visualDensity: VisualDensity.compact,
                    ),

                    const SizedBox(width: 10),

                    // 약 이름
                    Expanded(
                      child: Text(
                        medicine['name'],
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),

                    // 화살표
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

          // ── 약 추가 버튼 ───────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _showAddMedicineDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ 약 추가',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 약 추가 팝업 ────────────────────────────
  void _showAddMedicineDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('약 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '약 이름 입력',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  medicines.add({
                    'name': controller.text,
                    'checked': false,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}