import 'dart:io';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'medicine_search_page.dart';
import 'dosage_edit_page.dart';
import 'user_profile.dart';
import 'stock_repository.dart';

class OcrEditPage extends StatefulWidget {
  final List<String> medicineNames;
  final String? imagePath;
  final File? prescriptionImage;
  final UserProfile userProfile;

  const OcrEditPage({
    super.key,
    this.medicineNames = const [],
    this.imagePath,
    this.prescriptionImage,
    required this.userProfile,
  });

  @override
  State<OcrEditPage> createState() => _OcrEditPageState();
}

class _OcrEditPageState extends State<OcrEditPage> {
  late List<Map<String, dynamic>> medicines;
  late List<Map<String, dynamic>> dosageData;
  // ✅ 상비약 여부 + 한 판 개수(setSize)를 medicines/dosageData와 같은 인덱스로 관리
  late List<Map<String, dynamic>> stockData;

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
      'registered': false,
      'dosageInfo': null as DosageInfo?,
    }).toList();

    // ✅ 상비약 기본값: 체크 안 됨, 한 판 개수는 빈 입력칸으로 시작
    stockData = widget.medicineNames.map((_) => {
      'isStock': false,
      'setSizeController': TextEditingController(),
    }).toList();
  }

  @override
  void dispose() {
    for (var m in medicines) {
      (m['controller'] as TextEditingController).dispose();
    }
    for (var s in stockData) {
      (s['setSizeController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchDosageInfo(String medicineName) async {
    // TODO: DB 연동
    return null;
  }

  void _addMedicinesWithNames(List<String> names) async {
    await Future.wait(names.map((name) => _fetchDosageInfo(name)));

    setState(() {
      for (final name in names) {
        medicines.add({
          'name': name,
          'controller': TextEditingController(text: name),
          'editing': false,
        });
        dosageData.add({
          'registered': false,
          'dosageInfo': null as DosageInfo?,
        });
        // ✅ 새로 추가된 약에도 상비약 상태를 같은 인덱스로 추가
        stockData.add({
          'isStock': false,
          'setSizeController': TextEditingController(),
        });
      }
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      (medicines[index]['controller'] as TextEditingController).dispose();
      (stockData[index]['setSizeController'] as TextEditingController)
          .dispose();
      medicines.removeAt(index);
      dosageData.removeAt(index);
      stockData.removeAt(index);
    });
  }

  Future<void> _openDosageEditPage(int index) async {
    final medicineName = medicines[index]['name'] as String;
    final result = await Navigator.push<DosageInfo>(
      context,
      MaterialPageRoute(
        builder: (_) => DosageEditPage(
          medicineName: medicineName,
          initialDosage: dosageData[index]['dosageInfo'] as DosageInfo?,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        dosageData[index]['dosageInfo'] = result;
        dosageData[index]['registered'] = true;
      });
    }
  }

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

    // ✅ 상비약으로 체크했지만 한 판 개수를 안 적은 경우 확인
    final missingSetSizeNames = <String>[];
    for (int i = 0; i < medicines.length; i++) {
      final isStock = stockData[i]['isStock'] as bool;
      if (isStock) {
        final text =
            (stockData[i]['setSizeController'] as TextEditingController)
                .text
                .trim();
        if (text.isEmpty || int.tryParse(text) == null || int.parse(text) <= 0) {
          missingSetSizeNames.add(medicines[i]['name'] as String);
        }
      }
    }

    if (missingSetSizeNames.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '상비약으로 등록하려면 한 판 개수를 입력해주세요.\n'
            '(${missingSetSizeNames.join(', ')})',
          ),
        ),
      );
      return;
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
              child:
                  const Text('그래도 등록', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    } else {
      _navigateHome();
    }
  }

  void _navigateHome() {
    // ✅ 상비약으로 체크된 약들을 전역 저장소(StockRepository)에 반영
    // TODO: 나중에 DB/로컬 저장소 연동 시 이 부분을 실제 저장 로직으로 교체
    for (int i = 0; i < medicines.length; i++) {
      final isStock = stockData[i]['isStock'] as bool;
      if (!isStock) continue;

      final name = medicines[i]['name'] as String;
      final setSizeText =
          (stockData[i]['setSizeController'] as TextEditingController)
              .text
              .trim();
      final setSize = int.tryParse(setSizeText) ?? 0;
      if (setSize <= 0) continue; // _onRegisterPressed에서 이미 검증했지만 안전장치로 한 번 더 확인

      StockRepository.instance.addOrUpdate(
        name: name,
        initialRemaining: setSize, // 새로 등록하는 약은 "한 판 가득" 상태로 시작
        setSize: setSize,
      );
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => HomeScreen(profile: UserProfile.empty())),
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
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w500),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(Icons.home_outlined,
                                color: Colors.black, size: 28),
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

                        // 헤더
                        Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.black)),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Text('약 LIST',
                                  style: TextStyle(fontSize: 15)),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: IconButton(
                                    icon: const Icon(Icons.add,
                                        size: 20, color: Colors.black),
                                    onPressed: () async {
                                      final List<String>? selectedNames =
                                          await Navigator.push<List<String>>(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MedicineSearchPage(
                                                  isForRegistration: true,
                                                  userProfile:
                                                      widget.userProfile,
                                                )),
                                      );
                                      if (selectedNames != null &&
                                          selectedNames.isNotEmpty) {
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

                        // 약 목록
                        medicines.isEmpty
                            ? const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '+ 버튼으로 약을 추가해주세요.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: medicines.length,
                                separatorBuilder: (_, _) => const Divider(
                                    height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final medicine = medicines[index];
                                  final controller = medicine['controller']
                                      as TextEditingController;
                                  final isEditing =
                                      medicine['editing'] as bool;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [

                                        // ── 이름 수정 / 완료 버튼 ──
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isEditing) {
                                                medicines[index]
                                                    ['editing'] = false;
                                                medicines[index]['name'] =
                                                    controller.text;
                                              } else {
                                                // 다른 항목 편집 모드 해제
                                                for (int i = 0;
                                                    i < medicines.length;
                                                    i++) {
                                                  if (i != index) {
                                                    medicines[i]
                                                        ['editing'] = false;
                                                    medicines[i]['name'] =
                                                        (medicines[i][
                                                                    'controller']
                                                                as TextEditingController)
                                                            .text;
                                                  }
                                                }
                                                medicines[index]
                                                    ['editing'] = true;
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isEditing
                                                  ? Colors.black
                                                  : Colors.white,
                                              border: Border.all(
                                                  color: Colors.black),
                                            ),
                                            child: Text(
                                              isEditing ? '완료' : '이름 수정',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isEditing
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // ── 약 이름 ──────────────
                                        Expanded(
                                          child: isEditing
                                              ? TextField(
                                                  controller: controller,
                                                  decoration:
                                                      const InputDecoration(
                                                    isDense: true,
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 8),
                                                  ),
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                  autofocus: true,
                                                )
                                              : Text(
                                                  controller.text,
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                        ),

                                        // ── 삭제 버튼 ────────────
                                        GestureDetector(
                                          onTap: () =>
                                              _removeMedicine(index),
                                          child: const Padding(
                                            padding:
                                                EdgeInsets.only(left: 6),
                                            child: Icon(Icons.close,
                                                size: 18,
                                                color: Colors.black38),
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

                const SizedBox(height: 16),

                // ── 복약 횟수 수정 섹션 ───────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [

                        // 헤더
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.black)),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: const Text('복약 횟수',
                              style: TextStyle(fontSize: 15)),
                        ),

                        // 약별 복약 수정 버튼 목록
                        medicines.isEmpty
                            ? const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '약을 추가하면 복약 정보를 입력할 수 있어요.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: medicines.length,
                                separatorBuilder: (_, _) => const Divider(
                                    height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final isRegistered =
                                      dosageData[index]['registered']
                                          as bool;
                                  final dosageInfo = dosageData[index]
                                      ['dosageInfo'] as DosageInfo?;
                                  final name =
                                      medicines[index]['name'] as String;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // 약 이름
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              ),
                                            ),

                                            // 복약 횟수 수정 버튼
                                            GestureDetector(
                                              onTap: () =>
                                                  _openDosageEditPage(
                                                      index),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isRegistered
                                                      ? Colors.green.shade50
                                                      : Colors.white,
                                                  border: Border.all(
                                                    color: isRegistered
                                                        ? Colors.green
                                                        : Colors.black54,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (isRegistered) ...[
                                                      const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 14),
                                                      const SizedBox(
                                                          width: 4),
                                                    ],
                                                    Text(
                                                      isRegistered
                                                          ? '복약 횟수 수정'
                                                          : '복약 횟수 입력',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isRegistered
                                                            ? Colors.green
                                                            : Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // 등록된 경우 요약 표시
                                        if (isRegistered &&
                                            dosageInfo != null) ...[
                                          const SizedBox(height: 8),
                                          _buildDosageSummary(dosageInfo),
                                        ],
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

                const SizedBox(height: 16),

                // ── ✅ 상비약 설정 섹션 ───────────────
                // "매일 챙겨먹는 약(복약 스케줄)"이 아니라 "집에 두고 필요할 때
                // 꺼내 먹는 약"인 경우 체크합니다. 체크하면 한 판(세트)에
                // 몇 개가 들어있는지 입력받아, 홈 화면의 알약판 UI에서
                // 재고를 추적할 수 있도록 합니다.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [

                        // 헤더
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.black)),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: const Text('상비약 설정',
                              style: TextStyle(fontSize: 15)),
                        ),

                        medicines.isEmpty
                            ? const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '약을 추가하면 상비약 여부를 설정할 수 있어요.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45),
                                ),
                              )
                            : Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        12, 10, 12, 0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '매일 챙겨먹는 약이 아니라, 집에 두고 필요할 때\n'
                                        '꺼내 먹는 약이라면 체크해주세요.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: medicines.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(
                                            height: 1,
                                            color: Colors.black12),
                                    itemBuilder: (context, index) {
                                      final name =
                                          medicines[index]['name']
                                              as String;
                                      final isStock =
                                          stockData[index]['isStock']
                                              as bool;
                                      final setSizeController = stockData[
                                              index]['setSizeController']
                                          as TextEditingController;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: isStock,
                                                  onChanged: (checked) {
                                                    setState(() {
                                                      stockData[index]
                                                              ['isStock'] =
                                                          checked ?? false;
                                                    });
                                                  },
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                        fontSize: 15),
                                                  ),
                                                ),
                                                Text(
                                                  '상비약',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isStock
                                                        ? Colors.black87
                                                        : Colors.black38,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // 체크했을 때만 한 판 개수 입력칸 펼치기
                                            if (isStock)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        left: 40,
                                                        bottom: 8),
                                                child: Row(
                                                  children: [
                                                    const Text(
                                                      '한 판 개수',
                                                      style: TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                    const SizedBox(
                                                        width: 8),
                                                    SizedBox(
                                                      width: 70,
                                                      height: 36,
                                                      child: TextField(
                                                        controller:
                                                            setSizeController,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        textAlign:
                                                            TextAlign
                                                                .center,
                                                        decoration:
                                                            const InputDecoration(
                                                          isDense: true,
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          6),
                                                        ),
                                                        style:
                                                            const TextStyle(
                                                                fontSize:
                                                                    14),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: 6),
                                                    const Text(
                                                      '개',
                                                      style: TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── 등록하기 버튼 ──────────────────
                SizedBox(
                  width: 250,
                  height: 60,
                  child: ElevatedButton(
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
                    child: const Text('등록하기',
                        style: TextStyle(fontSize: 20)),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 복약 정보 요약 위젯
  Widget _buildDosageSummary(DosageInfo info) {
    final lines = <String>[];

    if (info.pillTimesPerDay > 0) {
      lines.add('알약: 1일 ${info.pillTimesPerDay}회 / ${info.pillDays}일분');
    }
    if (info.pillTimings.isNotEmpty) {
      const timingLabels = {
        MedicineTiming.afterMeal30: '식후 30분',
        MedicineTiming.beforeMeal30: '식전 30분',
        MedicineTiming.beforeSleep: '취침 전',
        MedicineTiming.rightAfterMeal: '식후 즉시',
      };
      lines.add(
          info.pillTimings.map((t) => timingLabels[t]).join(', '));
    }
    if (info.syrupTimesPerDay > 0) {
      lines.add(
          '시럽: 1회 ${info.syrupMlPerDose.toStringAsFixed(0)}mL / ${info.syrupTimesPerDay}회');
    }
    if (info.syrupStorages.isNotEmpty) {
      const storageLabels = {
        SyrupStorage.refrigerated: '냉장 보관',
        SyrupStorage.roomTemp: '실온 보관',
      };
      lines.add(
          info.syrupStorages.map((s) => storageLabels[s]).join(', '));
    }

    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Text(l,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87)))
            .toList(),
      ),
    );
  }
}