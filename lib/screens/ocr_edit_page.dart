import 'package:flutter/material.dart';
import 'home_page.dart';
import 'user_profile.dart';

class OcrEditPage extends StatefulWidget {
  final List<String> medicineNames;
  final String? imagePath;

  const OcrEditPage({
    super.key,
    this.medicineNames = const ['약 이름 1', '약 이름 2', '약 이름 3'],
    this.imagePath,
  });

  @override
  State<OcrEditPage> createState() => _OcrEditPageState();
}

class _OcrEditPageState extends State<OcrEditPage> {
  late List<Map<String, dynamic>> medicines;

  // ✅ 현재 선택된 약 인덱스 (복약 횟수 섹션과 연동)
  int? selectedMedicineIndex;

  // 복약 횟수 정보 (약별로 저장)
  late List<Map<String, dynamic>> dosageData;

  @override
  void initState() {
    super.initState();
    medicines = widget.medicineNames.map((name) => {
      'name': name,
      'controller': TextEditingController(text: name),
      'editing': false,
    }).toList();

    dosageData = widget.medicineNames.map((_) => {
      'times': null as int?,
      'daysController': TextEditingController(),
      'minutesController': TextEditingController(),
      'registered': false,
    }).toList();
  }

  @override
  void dispose() {
    for (var m in medicines) {
      (m['controller'] as TextEditingController).dispose();
    }
    for (var d in dosageData) {
      (d['daysController'] as TextEditingController).dispose();
      (d['minutesController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // ✅ 약 추가
  void _addMedicine() {
    setState(() {
      medicines.add({
        'name': '약 이름',
        'controller': TextEditingController(text: '약 이름'),
        'editing': true, // 추가하자마자 바로 수정 가능한 상태로 시작
      });
      dosageData.add({
        'times': null as int?,
        'daysController': TextEditingController(),
        'minutesController': TextEditingController(),
        'registered': false,
      });

      // 새로 추가된 약을 편집 상태로 선택, 다른 약은 편집 종료
      final newIndex = medicines.length - 1;
      for (int i = 0; i < medicines.length; i++) {
        if (i != newIndex) {
          medicines[i]['editing'] = false;
        }
      }
      selectedMedicineIndex = newIndex;
    });
  }

  // ✅ 약 삭제
  void _removeMedicine(int index) {
    setState(() {
      (medicines[index]['controller'] as TextEditingController).dispose();
      (dosageData[index]['daysController'] as TextEditingController).dispose();
      (dosageData[index]['minutesController'] as TextEditingController).dispose();

      medicines.removeAt(index);
      dosageData.removeAt(index);

      // ✅ 선택된 인덱스 정리 (삭제된 약이 선택돼 있었거나, 인덱스가 밀린 경우)
      if (selectedMedicineIndex == index) {
        selectedMedicineIndex = null;
      } else if (selectedMedicineIndex != null && selectedMedicineIndex! > index) {
        selectedMedicineIndex = selectedMedicineIndex! - 1;
      }
    });
  }

  // 복약 횟수 선택 다이얼로그
  void _showTimesDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('1일 복약 횟수 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final count = i + 1;
            return RadioListTile<int>(
              title: Text('$count회'),
              value: count,
              groupValue: dosageData[index]['times'],
              onChanged: (v) {
                setState(() => dosageData[index]['times'] = v);
                Navigator.pop(context);
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [

                // ── 상단 바 ────────────────────────
                SizedBox(
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/medicare_logo.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        '약 이름 확인 및 수정',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(Icons.home_outlined, color: Colors.black, size: 28),
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => HomeScreen(profile: UserProfile.empty())),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── 약 LIST ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [

                        // 타이틀 + 약 추가 버튼
                        Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black)),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Text('약 LIST', style: TextStyle(fontSize: 15)),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, size: 20, color: Colors.black),
                                    onPressed: _addMedicine,
                                    tooltip: '약 추가',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 약 목록
                        medicines.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '등록된 약이 없습니다. + 버튼으로 추가해주세요.',
                                  style: TextStyle(fontSize: 13, color: Colors.black45),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: medicines.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final medicine = medicines[index];
                                  final controller = medicine['controller'] as TextEditingController;
                                  final isEditing = medicine['editing'] as bool;
                                  final isSelected = selectedMedicineIndex == index;
                                  final isRegistered = dosageData[index]['registered'] as bool;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [

                                        // ✅ 수정 / 완료 버튼
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isEditing) {
                                                // 완료 버튼 누름 → 수정 마무리
                                                medicines[index]['editing'] = false;
                                                medicines[index]['name'] = controller.text;
                                                selectedMedicineIndex = null;
                                              } else {
                                                // 수정 버튼 누름 → 편집 모드 + 복약 횟수 연동
                                                medicines[index]['editing'] = true;
                                                selectedMedicineIndex = index;
                                                // 다른 약 편집 중이면 닫기
                                                for (int i = 0; i < medicines.length; i++) {
                                                  if (i != index) {
                                                    medicines[i]['editing'] = false;
                                                  }
                                                }
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isEditing ? Colors.black : Colors.white,
                                              border: Border.all(color: Colors.black),
                                            ),
                                            child: Text(
                                              isEditing ? '완료' : '수정',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isEditing ? Colors.white : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // 약 이름 (수정 중이면 TextField)
                                        Expanded(
                                          child: isEditing
                                              ? TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                  ),
                                                  style: const TextStyle(fontSize: 16),
                                                  autofocus: true,
                                                )
                                              : Text(
                                                  controller.text,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    // ✅ 선택된 약은 초록색으로 강조
                                                    color: isSelected ? Colors.green : Colors.black,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                        ),

                                        // ✅ 등록 완료 표시
                                        if (isRegistered && !isEditing)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                                          ),

                                        // ✅ 삭제 버튼 (약이 1개만 남았을 때는 숨김 - 최소 1개는 유지)
                                        if (medicines.length > 1)
                                          GestureDetector(
                                            onTap: () => _removeMedicine(index),
                                            child: const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Icon(Icons.close, size: 18, color: Colors.black38),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── 복약 횟수 ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [

                        // ✅ 타이틀 - 선택된 약 이름 표시
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black)),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            selectedMedicineIndex != null
                                ? '(${medicines[selectedMedicineIndex!]['name']}) 복약 횟수'
                                : '복약 횟수',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [

                              // 1일 n회 n일분
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [

                                  const Text('1일', style: TextStyle(fontSize: 22)),

                                  // 횟수 선택 버튼
                                  GestureDetector(
                                    onTap: selectedMedicineIndex != null
                                        ? () => _showTimesDialog(selectedMedicineIndex!)
                                        : null,
                                    child: Container(
                                      width: 70,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: selectedMedicineIndex != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        color: selectedMedicineIndex != null
                                            ? Colors.white
                                            : Colors.grey[100],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        selectedMedicineIndex != null &&
                                            dosageData[selectedMedicineIndex!]['times'] != null
                                            ? '${dosageData[selectedMedicineIndex!]['times']}회'
                                            : '  회',
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),

                                  // 일분 직접 입력
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 40,
                                        child: TextField(
                                          controller: selectedMedicineIndex != null
                                              ? dosageData[selectedMedicineIndex!]['daysController']
                                              : TextEditingController(),
                                          enabled: selectedMedicineIndex != null,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      const Text('일분', style: TextStyle(fontSize: 22)),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // 식후 n분 + 등록/수정 버튼
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [

                                  const Text('식후', style: TextStyle(fontSize: 20)),

                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 40,
                                        child: TextField(
                                          controller: selectedMedicineIndex != null
                                              ? dosageData[selectedMedicineIndex!]['minutesController']
                                              : TextEditingController(),
                                          enabled: selectedMedicineIndex != null &&
                                              !(dosageData[selectedMedicineIndex!]['registered'] as bool),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      const Text('분', style: TextStyle(fontSize: 20)),
                                    ],
                                  ),

                                  // ✅ 등록 / 수정 버튼
                                  GestureDetector(
                                    onTap: selectedMedicineIndex != null
                                        ? () {
                                            setState(() {
                                              final idx = selectedMedicineIndex!;
                                              final isRegistered = dosageData[idx]['registered'] as bool;
                                              if (isRegistered) {
                                                // 수정 버튼 → 다시 편집 가능
                                                dosageData[idx]['registered'] = false;
                                              } else {
                                                // 등록 버튼 → 저장 + 완료 표시
                                                dosageData[idx]['registered'] = true;
                                                medicines[idx]['editing'] = false;
                                                medicines[idx]['name'] =
                                                    (medicines[idx]['controller'] as TextEditingController).text;
                                                selectedMedicineIndex = null;
                                              }
                                            });
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: selectedMedicineIndex != null &&
                                            dosageData[selectedMedicineIndex!]['registered'] as bool
                                            ? Colors.grey[200]
                                            : Colors.white,
                                        border: Border.all(
                                          color: selectedMedicineIndex != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                      child: Text(
                                        selectedMedicineIndex != null &&
                                            dosageData[selectedMedicineIndex!]['registered'] as bool
                                            ? '수정'
                                            : '등록',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedMedicineIndex != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── 등록하기 버튼 ──────────────────
                SizedBox(
                  width: 250,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen(profile: UserProfile.empty())),
                        (route) => false,
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
                    child: const Text('등록하기', style: TextStyle(fontSize: 20)),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}