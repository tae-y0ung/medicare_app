import 'dart:io';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'user_profile.dart';
import 'medicine_search_page.dart';

class OcrEditPage extends StatefulWidget {
  final List<String> medicineNames;
  final String? imagePath;
  final File? prescriptionImage;

  const OcrEditPage({
    super.key,
    this.medicineNames = const [],
    this.imagePath,
    this.prescriptionImage,
  });

  @override
  State<OcrEditPage> createState() => _OcrEditPageState();
}

class _OcrEditPageState extends State<OcrEditPage> {
  late List<Map<String, dynamic>> medicines;
  int? selectedMedicineIndex;
  late List<Map<String, dynamic>> dosageData;

  // ✅ prescriptionImage(File)와 imagePath(String) 중 있는 것을 우선 사용
  // 추후 OCR 연동 시 이 값을 API에 전달
  String? get resolvedImagePath =>
      widget.prescriptionImage?.path ?? widget.imagePath;

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

  Future<Map<String, dynamic>?> _fetchDosageInfo(String medicineName) async {
    // TODO: 팀원 DB 연동 시 아래 주석 해제 후 연결
    // final result = await ApiService.getDosageInfo(medicineName);
    // return result;
    return null;
  }

  void _addMedicinesWithNames(List<String> names) async {
    final dosageInfoList = await Future.wait(
      names.map((name) => _fetchDosageInfo(name)),
    );

    setState(() {
      for (int i = 0; i < names.length; i++) {
        final name = names[i];
        final dosageInfo = dosageInfoList[i];

        medicines.add({
          'name': name,
          'controller': TextEditingController(text: name),
          'editing': false,
        });
        dosageData.add({
          'times': dosageInfo?['times'] as int?,
          'daysController': TextEditingController(
            text: dosageInfo?['days']?.toString() ?? '',
          ),
          'minutesController': TextEditingController(
            text: dosageInfo?['minutes']?.toString() ?? '',
          ),
          'registered': false,
        });
      }
      selectedMedicineIndex = medicines.length - 1;
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      (medicines[index]['controller'] as TextEditingController).dispose();
      (dosageData[index]['daysController'] as TextEditingController).dispose();
      (dosageData[index]['minutesController'] as TextEditingController).dispose();

      medicines.removeAt(index);
      dosageData.removeAt(index);

      if (selectedMedicineIndex == index) {
        selectedMedicineIndex = null;
      } else if (selectedMedicineIndex != null && selectedMedicineIndex! > index) {
        selectedMedicineIndex = selectedMedicineIndex! - 1;
      }
    });
  }

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

  // ✅ 미등록 약이 있을 때 경고 다이얼로그
  void _onRegisterPressed() {
    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록할 약이 없습니다.')),
      );
      return;
    }

    final unregisteredNames = <String>[];
    for (int i = 0; i < medicines.length; i++) {
      if (!(dosageData[i]['registered'] as bool)) {
        unregisteredNames.add(medicines[i]['name'] as String);
      }
    }

    if (unregisteredNames.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('복약 정보 미입력'),
          content: Text(
            '아직 복약 정보가 입력되지 않은 약이 있어요.\n\n'
            '${unregisteredNames.map((n) => '• $n').join('\n')}\n\n'
            '그래도 등록하시겠어요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('돌아가기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateHome();
              },
              child: const Text('그래도 등록', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    } else {
      _navigateHome();
    }
  }

  void _navigateHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(profile: UserProfile.empty())),
      (route) => false,
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
                            onPressed: _navigateHome,
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
                                    onPressed: () async {
                                      final List<String>? selectedNames =
                                          await Navigator.push<List<String>>(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const MedicineSearchPage()),
                                      );
                                      if (selectedNames != null && selectedNames.isNotEmpty) {
                                        _addMedicinesWithNames(selectedNames);
                                      }
                                    },
                                    tooltip: '약 추가',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        medicines.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '+ 버튼으로 약을 추가해주세요.',
                                  style: TextStyle(fontSize: 13, color: Colors.black45),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: medicines.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final medicine = medicines[index];
                                  final controller =
                                      medicine['controller'] as TextEditingController;
                                  final isEditing = medicine['editing'] as bool;
                                  final isSelected = selectedMedicineIndex == index;
                                  final isRegistered =
                                      dosageData[index]['registered'] as bool;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [

                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isEditing) {
                                                medicines[index]['editing'] = false;
                                                medicines[index]['name'] = controller.text;
                                                selectedMedicineIndex = null;
                                              } else {
                                                medicines[index]['editing'] = true;
                                                selectedMedicineIndex = index;
                                                for (int i = 0; i < medicines.length; i++) {
                                                  if (i != index) medicines[i]['editing'] = false;
                                                }
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
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

                                        Expanded(
                                          child: isEditing
                                              ? TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 8),
                                                  ),
                                                  style: const TextStyle(fontSize: 16),
                                                  autofocus: true,
                                                )
                                              : Text(
                                                  controller.text,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isSelected
                                                        ? Colors.green
                                                        : Colors.black,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                        ),

                                        if (isRegistered && !isEditing)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(Icons.check_circle,
                                                color: Colors.green, size: 18),
                                          ),

                                        GestureDetector(
                                          onTap: () => _removeMedicine(index),
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(Icons.close,
                                                size: 18, color: Colors.black38),
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

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [

                                  const Text('1일', style: TextStyle(fontSize: 22)),

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

                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 40,
                                        child: TextField(
                                          controller: selectedMedicineIndex != null
                                              ? dosageData[selectedMedicineIndex!]
                                                  ['daysController']
                                              : TextEditingController(),
                                          enabled: selectedMedicineIndex != null,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(vertical: 8),
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
                                              ? dosageData[selectedMedicineIndex!]
                                                  ['minutesController']
                                              : TextEditingController(),
                                          enabled: selectedMedicineIndex != null &&
                                              !(dosageData[selectedMedicineIndex!]
                                                      ['registered'] as bool),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      const Text('분', style: TextStyle(fontSize: 20)),
                                    ],
                                  ),

                                  GestureDetector(
                                    onTap: selectedMedicineIndex != null
                                        ? () {
                                            setState(() {
                                              final idx = selectedMedicineIndex!;
                                              final isRegistered =
                                                  dosageData[idx]['registered'] as bool;
                                              if (isRegistered) {
                                                dosageData[idx]['registered'] = false;
                                              } else {
                                                dosageData[idx]['registered'] = true;
                                                medicines[idx]['editing'] = false;
                                                medicines[idx]['name'] =
                                                    (medicines[idx]['controller']
                                                            as TextEditingController)
                                                        .text;
                                                selectedMedicineIndex = null;
                                              }
                                            });
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: selectedMedicineIndex != null &&
                                                dosageData[selectedMedicineIndex!]
                                                    ['registered'] as bool
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
                                                dosageData[selectedMedicineIndex!]
                                                    ['registered'] as bool
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
                    // ✅ 미등록 약 확인 후 이동
                    onPressed: _onRegisterPressed,
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