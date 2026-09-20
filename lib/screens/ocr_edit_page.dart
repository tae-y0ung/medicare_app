import 'package:flutter/material.dart';
import 'home_page.dart';
import 'medicine_search_page.dart';
import 'dosage_edit_page.dart';
import 'user_profile.dart';
import 'stock_repository.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class OcrEditPage extends StatefulWidget {
  final List<Map<String, dynamic>> ocrMedicines;
  final XFile? prescriptionImage;
  final UserProfile userProfile;

  const OcrEditPage({
    super.key,
    this.ocrMedicines = const [],
    this.prescriptionImage,
    required this.userProfile,
  });

  @override
  State<OcrEditPage> createState() =>
      _OcrEditPageState();
}

class _OcrEditPageState extends State<OcrEditPage> {
  late List<Map<String, dynamic>> medicines;
  late List<Map<String, dynamic>> dosageData;
  // ✅ 상비약 여부 + 한 판 개수(setSize)를 medicines/dosageData와 같은 인덱스로 관리
  late List<Map<String, dynamic>> stockData;

  bool _isSaving = false;

  @override
void initState() {
  super.initState();

  // ─────────────────────────────
  // 1. OCR 약 이름
  // ─────────────────────────────
  medicines = widget.ocrMedicines.map((medicine) {
    final name =
        (medicine['medicineName'] ?? '').toString();

    return {
      'name': name,
      'controller': TextEditingController(
        text: name,
      ),
      'editing': false,
    };
  }).toList();

  // ─────────────────────────────
  // 2. OCR 복약 정보
  // ─────────────────────────────
  dosageData = widget.ocrMedicines.map((medicine) {
    final dailyCount = _toInt(
      medicine['dailyCount'],
    );

    final period = _toInt(
      medicine['period'],
    );

    final timing =
        (medicine['timing'] ?? '').toString();

    // OCR에서 복약정보를 인식했다면
    // DosageInfo 초기값으로 바로 넣기
    final hasDosage =
        dailyCount > 0 || period > 0;

    final dosageInfo = DosageInfo(
      pillTimesPerDay: dailyCount,
      pillDays: period,
      pillTimings: _timingFromOcr(timing),
    );

    return {
      'registered': hasDosage,
      'dosageInfo':
          hasDosage ? dosageInfo : null,
    };
  }).toList();

  // ─────────────────────────────
  // 3. 상비약 설정
  // OCR에서 읽은 모든 약 이름과 같은 인덱스 생성
  // ─────────────────────────────
  stockData = widget.ocrMedicines.map((medicine) {
    final initialIsStock = medicine['isStock'] == true;   // ← 넘어온 값 확인
    return {
      'isStock': initialIsStock,   // ← false 대신 이 값 사용
      'setSizeController': TextEditingController(),
    };
  }).toList();
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse(
        value.toString(),
      ) ??
      0;
}

Set<MedicineTiming> _timingFromOcr(
  String timing,
) {
  final result = <MedicineTiming>{};

  final text = timing.replaceAll(' ', '');

  if (text.contains('식전')) {
    result.add(
      MedicineTiming.beforeMeal30,
    );
  }

  if (text.contains('식후30분')) {
    result.add(
      MedicineTiming.afterMeal30,
    );
  } else if (text.contains('식후즉시')) {
    result.add(
      MedicineTiming.rightAfterMeal,
    );
  } else if (text == '식후') {
    // OCR이 단순히 "식후"라고만 읽은 경우
    result.add(
      MedicineTiming.afterMeal30,
    );
  }

  if (text.contains('취침')) {
    result.add(
      MedicineTiming.beforeSleep,
    );
  }

  return result;
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

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

String _timingToString(DosageInfo info) {
  final labels = <String>[];

  if (info.pillTimings.contains(MedicineTiming.beforeMeal30)) {
    labels.add('식전 30분');
  }

  if (info.pillTimings.contains(MedicineTiming.afterMeal30)) {
    labels.add('식후 30분');
  }

  if (info.pillTimings.contains(MedicineTiming.rightAfterMeal)) {
    labels.add('식후 즉시');
  }

  if (info.pillTimings.contains(MedicineTiming.beforeSleep)) {
    labels.add('취침 전');
  }

  if (labels.isEmpty) {
    return '복용 시간 미지정';
  }

  return labels.join(', ');
}

List<Map<String, dynamic>>
    _buildPrescriptionMedicines() {
  final result =
      <Map<String, dynamic>>[];

  final startDate = DateTime.now();

  for (int i = 0;
      i < medicines.length;
      i++) {
    final registered =
        dosageData[i]['registered']
            as bool;

    // 복약 정보를 입력하지 않은 약은
    // schedule 생성 대상에서 제외
    if (!registered) {
      continue;
    }

    final info =
        dosageData[i]['dosageInfo']
            as DosageInfo?;

    if (info == null) {
      continue;
    }

    final controller =
        medicines[i]['controller']
            as TextEditingController;

    final medicineName =
        controller.text.trim();

    if (medicineName.isEmpty) {
      continue;
    }

    int dailyCount;
    double dosage;
    int period;
    String timing;

    // ─────────────────────────
    // 알약
    // ─────────────────────────
    if (info.pillTimesPerDay > 0) {
      dailyCount =
          info.pillTimesPerDay;

      // 현재 DosageEditPage에는
      // 1회 몇 정인지 입력하는 값이 없으므로
      // 일단 1정으로 처리
      dosage = 1.0;

      period =
          info.pillDays > 0
              ? info.pillDays
              : 1;

      timing =
          _timingToString(info);
    }

    // ─────────────────────────
    // 시럽
    // ─────────────────────────
    else if (info.syrupTimesPerDay >
        0) {
      dailyCount =
          info.syrupTimesPerDay;

      dosage =
          info.syrupMlPerDose;

      // 현재 시럽에는 복용 일수 입력칸이
      // 없으므로 일단 1일
      period = 1;

      timing = '시럽';
    } else {
      continue;
    }

    final endDate = startDate.add(
      Duration(
        days: period - 1,
      ),
    );

    final isStock =
        stockData[i]['isStock']
            as bool;

    int? setSize;

    if (isStock) {
      final text =
          (stockData[i]
                      ['setSizeController']
                  as TextEditingController)
              .text
              .trim();

      setSize = int.tryParse(text);
    }

    result.add({
      'medicineName':
          medicineName,

      'dailyCount':
          dailyCount,

      'dosage':
          dosage,

      'timing':
          timing,

      'startDate':
          _formatDate(startDate),

      'endDate':
          _formatDate(endDate),

      'period':
          period,

      // 처방전 정보에도 같이 저장
      'isStock':
          isStock,

      'setSize':
          setSize,
    });
  }

  return result;
}

  Future<void> _onRegisterPressed() async {
  if (_isSaving) return;

  if (medicines.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('등록할 약이 없습니다.'),
      ),
    );
    return;
  }

  // ------------------------------------
  // TextField에 수정 중인 이름 최종 반영
  // ------------------------------------
  for (int i = 0;
      i < medicines.length;
      i++) {
    final controller =
        medicines[i]['controller']
            as TextEditingController;

    medicines[i]['name'] =
        controller.text.trim();

    medicines[i]['editing'] = false;
  }

  // ------------------------------------
  // 상비약 한 판 개수 검사
  // ------------------------------------
  final missingSetSizeNames = <String>[];

  for (int i = 0;
      i < medicines.length;
      i++) {
    final isStock =
        stockData[i]['isStock'] as bool;

    if (!isStock) continue;

    final text =
        (stockData[i]['setSizeController']
                as TextEditingController)
            .text
            .trim();

    final setSize =
        int.tryParse(text);

    if (setSize == null ||
        setSize <= 0) {
      missingSetSizeNames.add(
        medicines[i]['name'] as String,
      );
    }
  }

  if (missingSetSizeNames.isNotEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '상비약으로 등록하려면 한 판 개수를 입력해주세요.\n'
          '(${missingSetSizeNames.join(', ')})',
        ),
      ),
    );

    return;
  }

  // ------------------------------------
  // 복약정보가 없는 약 확인
  // ------------------------------------
  final unregisteredNames = <String>[];

  for (int i = 0;
      i < medicines.length;
      i++) {
    if (!(dosageData[i]['registered']
        as bool)) {
      unregisteredNames.add(
        medicines[i]['name'] as String,
      );
    }
  }

  // 복약 정보가 빠진 약이 있다면 확인창
  if (unregisteredNames.isNotEmpty) {
    final shouldContinue =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            const Text('복약 정보 미입력'),
        content: Text(
          '아직 복약 정보가 입력되지 않은 약이 있어요.\n\n'
          '${unregisteredNames.map((n) => '• $n').join('\n')}\n\n'
          '복약 정보가 있는 약만 저장하시겠어요?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text('돌아가기'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child: const Text(
              '그래도 등록',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldContinue != true) {
      return;
    }
  }

  // ------------------------------------
  // 실제 서버 저장 시작
  // ------------------------------------
  try {
    setState(() {
      _isSaving = true;
    });

    debugPrint(
      '등록 사용자 ID: '
      '${widget.userProfile.userId}',
    );

final finalMedicines =
    _buildPrescriptionMedicines();

final result =
    await ApiService
        .saveEditedPrescription(
  userId:
      widget.userProfile.userId,
  medicines:
      finalMedicines,
   pickedFile: widget.prescriptionImage,
);

debugPrint(
  '처방전 최종 저장 결과: $result',
);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          '약 등록이 완료되었습니다.',
        ),
      ),
    );

    // 저장 성공 후 홈 이동
    _navigateHome();
  } catch (e) {
    debugPrint(
      '약 등록 중 오류: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '약 등록 중 오류가 발생했습니다.\n$e',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
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
          builder: (context) => HomeScreen(profile: widget.userProfile)),
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

                // ── 등록 완료 버튼 ──────────────────
                SizedBox(
  width: 250,
  height: 60,
  child: ElevatedButton(
    onPressed:
        _isSaving
            ? null
            : _onRegisterPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor:
          Colors.black,
      foregroundColor:
          Colors.white,
      disabledBackgroundColor:
          Colors.black38,
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(8),
      ),
    ),
    child: _isSaving
        ? const SizedBox(
            width: 24,
            height: 24,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Text(
            '등록 완료',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
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