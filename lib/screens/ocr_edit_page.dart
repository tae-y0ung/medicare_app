import 'package:flutter/material.dart';
import 'home_page.dart';
import 'medicine_search_page.dart';
import 'dosage_edit_page.dart';
import 'user_profile.dart';
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
  State<OcrEditPage> createState() => _OcrEditPageState();
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
    medicines = widget.ocrMedicines.map<Map<String, dynamic>>((medicine) {
      final name = (medicine['medicineName'] ?? '').toString();

      return <String, dynamic>{
        'name': name,

        'controller': TextEditingController(text: name),

        'editing': false,

        // 넘어온 원본 약 정보 보존
        'meta': Map<String, dynamic>.from(medicine),
      };
    }).toList();

    // ─────────────────────────────
    // 2. OCR 복약 정보
    // ─────────────────────────────
    dosageData = widget.ocrMedicines.map<Map<String, dynamic>>((medicine) {
      final dailyCount = _toInt(medicine['dailyCount']);

      final period = _toInt(medicine['period']);

      final timing = (medicine['timing'] ?? '').toString();

      // OCR에서 복약정보를 인식했다면
      // DosageInfo 초기값으로 바로 넣기
      final hasDosage = dailyCount > 0 || period > 0;

      final dosageInfo = DosageInfo(
        pillTimesPerDay: dailyCount,
        pillDays: period,
        pillTimings: _timingFromOcr(timing),
      );

      return {
        'registered': hasDosage,
        'dosageInfo': hasDosage ? dosageInfo : null,
      };
    }).toList();

    // ─────────────────────────────
    // 3. 상비약 설정
    // OCR에서 읽은 모든 약 이름과 같은 인덱스 생성
    // ─────────────────────────────
    stockData = widget.ocrMedicines.map<Map<String, dynamic>>((medicine) {
      final initialIsStock = medicine['isStock'] == true;

      return {
        'isStock': initialIsStock,

        'setSizeController': TextEditingController(),

        // API에서 자동 조회
        'minIntervalHours': null,

        'usageText': '',

        'itemSeq': medicine['itemSeq'],

        'intervalLoading': false,
      };
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (int i = 0; i < stockData.length; i++) {
        if (stockData[i]['isStock'] == true) {
          await _loadStockIntervalFromApi(i);
        }
      }
    });
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  int? _extractMinIntervalHours(String usage) {
    if (usage.trim().isEmpty) {
      return null;
    }

    final text = usage
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    RegExpMatch? match;

    // 4~6시간 간격 / 4-6시간 간격
    match = RegExp(
      r'(\d+)\s*[~～\-]\s*(\d+)\s*시간\s*(?:이상\s*)?간격',
    ).firstMatch(text);

    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    // 4시간 이상 간격
    match = RegExp(r'(\d+)\s*시간\s*이상\s*간격').firstMatch(text);

    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    // 8시간 간격
    match = RegExp(r'(\d+)\s*시간\s*간격').firstMatch(text);

    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    // 매 6시간
    match = RegExp(r'매\s*(\d+)\s*시간').firstMatch(text);

    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    // 6시간마다
    match = RegExp(r'(\d+)\s*시간마다').firstMatch(text);

    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    return null;
  }

  Future<void> _loadStockIntervalFromApi(int index) async {
    if (index < 0 || index >= medicines.length) {
      return;
    }

    final controller = medicines[index]['controller'] as TextEditingController;

    final medicineName = controller.text.trim();

    if (medicineName.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        stockData[index]['intervalLoading'] = true;
      });
    }

    try {
      final response = await ApiService.searchDrugs(medicineName);

      final rawMedicines = response['medicines'];

      Map<String, dynamic>? matchedDrug;

      if (rawMedicines is List) {
        final targetName = medicineName.replaceAll(' ', '').trim();

        // 먼저 정확히 같은 제품명 찾기
        for (final item in rawMedicines) {
          if (item is! Map) {
            continue;
          }

          final drug = Map<String, dynamic>.from(item);

          final itemName = (drug['itemName'] ?? '')
              .toString()
              .replaceAll(' ', '')
              .trim();

          if (itemName == targetName) {
            matchedDrug = drug;
            break;
          }
        }

        // 검색 결과가 딱 하나라면 사용
        if (matchedDrug == null &&
            rawMedicines.length == 1 &&
            rawMedicines.first is Map) {
          matchedDrug = Map<String, dynamic>.from(rawMedicines.first as Map);
        }
      }

      if (matchedDrug == null) {
        if (!mounted) return;

        setState(() {
          stockData[index]['minIntervalHours'] = null;

          stockData[index]['usageText'] = '';

          stockData[index]['itemSeq'] = null;

          stockData[index]['intervalLoading'] = false;
        });

        return;
      }

      Map<String, dynamic> raw = {};

      if (matchedDrug['raw'] is Map) {
        raw = Map<String, dynamic>.from(matchedDrug['raw'] as Map);
      }

      // API의 공식 용법·용량
      final usage = (matchedDrug['usage'] ?? raw['UD_DOC_DATA'] ?? '')
          .toString();

      final minIntervalHours = _extractMinIntervalHours(usage);

      final itemSeq = (matchedDrug['itemSeq'] ?? raw['ITEM_SEQ'] ?? '')
          .toString()
          .trim();

      debugPrint('========== 상비약 복용간격 조회 ==========');

      debugPrint('약 이름: $medicineName');

      debugPrint('itemSeq: $itemSeq');

      debugPrint(
        'minIntervalHours: '
        '$minIntervalHours',
      );

      debugPrint('usage: $usage');

      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        stockData[index]['minIntervalHours'] = minIntervalHours;

        stockData[index]['usageText'] = usage;

        stockData[index]['itemSeq'] = itemSeq;

        stockData[index]['intervalLoading'] = false;
      });
    } catch (e) {
      debugPrint('상비약 복용 간격 조회 실패: $e');

      if (!mounted) return;

      setState(() {
        stockData[index]['minIntervalHours'] = null;

        stockData[index]['usageText'] = '';

        stockData[index]['itemSeq'] = null;

        stockData[index]['intervalLoading'] = false;
      });
    }
  }

  Set<MedicineTiming> _timingFromOcr(String timing) {
    final result = <MedicineTiming>{};

    final text = timing.replaceAll(' ', '');

    if (text.contains('식전')) {
      result.add(MedicineTiming.beforeMeal30);
    }

    if (text.contains('식후30분')) {
      result.add(MedicineTiming.afterMeal30);
    } else if (text.contains('식후즉시')) {
      result.add(MedicineTiming.rightAfterMeal);
    } else if (text == '식후') {
      // OCR이 단순히 "식후"라고만 읽은 경우
      result.add(MedicineTiming.afterMeal30);
    }

    if (text.contains('취침')) {
      result.add(MedicineTiming.beforeSleep);
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

  void _addMedicinesWithNames(List<String> names) {
    if (names.isEmpty) {
      return;
    }

    debugPrint('OcrEditPage 추가 요청 약: $names');

    setState(() {
      for (final rawName in names) {
        final name = rawName.trim();

        if (name.isEmpty) {
          continue;
        }

        // 이미 목록에 있는 약은 중복 추가하지 않음
        final alreadyExists = medicines.any((medicine) {
          final controller = medicine['controller'] as TextEditingController;

          return controller.text.trim() == name;
        });

        if (alreadyExists) {
          debugPrint('이미 존재하는 약: $name');

          continue;
        }

        // ============================
        // 1. 약 이름 목록
        // ============================

        medicines.add(<String, dynamic>{
          'name': name,

          'controller': TextEditingController(text: name),

          'editing': false,

          'meta': <String, dynamic>{'medicineName': name},
        });

        // ============================
        // 2. 복약 정보
        // ============================

        dosageData.add(<String, dynamic>{
          'registered': false,

          'dosageInfo': null as DosageInfo?,
        });

        // ============================
        // 3. 상비약 정보
        // ============================

        stockData.add(<String, dynamic>{
          'isStock': false,

          'setSizeController': TextEditingController(),

          'minIntervalHours': null,

          'usageText': '',

          'itemSeq': null,

          'intervalLoading': false,
        });

        debugPrint('약 LIST에 추가 완료: $name');
      }
    });

    debugPrint(
      '현재 medicines 개수: '
      '${medicines.length}',
    );

    debugPrint(
      '현재 약 목록: '
      '${medicines.map((m) => (m['controller'] as TextEditingController).text).toList()}',
    );
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

  List<Map<String, dynamic>> _buildPrescriptionMedicines() {
    final result = <Map<String, dynamic>>[];

    final startDate = DateTime.now();

    for (int i = 0; i < medicines.length; i++) {
      final controller = medicines[i]['controller'] as TextEditingController;

      final medicineName = controller.text.trim();

      if (medicineName.isEmpty) {
        continue;
      }

      // ========================================
      // 상세 약 정보 보존
      // ========================================

      final rawMeta = medicines[i]['meta'];

      final meta = rawMeta is Map
          ? Map<String, dynamic>.from(rawMeta)
          : <String, dynamic>{};

      final detailFields = <String, dynamic>{
        'itemSeq': meta['itemSeq'],

        'manufacturer': meta['manufacturer'],

        'ingredient': meta['ingredient'],

        'purchaseType': meta['purchaseType'],

        'medicineType': meta['medicineType'],

        'medicineTypeLabel': meta['medicineTypeLabel'],

        'effect': meta['effect'],

        'usage': meta['usage'],

        'cautions': meta['cautions'],

        'contraindications': meta['contraindications'],

        'category': meta['category'],

        'productType': meta['productType'],

        'imageUrl': meta['imageUrl'],
      };

      detailFields.removeWhere((key, value) {
        if (value == null) {
          return true;
        }

        if (value is String && value.trim().isEmpty) {
          return true;
        }

        if (value is List && value.isEmpty) {
          return true;
        }

        return false;
      });

      final isStock = stockData[i]['isStock'] == true;

      // ========================================
      // 1. 상비약
      // 복약 횟수/기간/복약 시간 필요 없음
      // ========================================

      if (isStock) {
        final stockText =
            (stockData[i]['setSizeController'] as TextEditingController).text
                .trim();

        final stockCount = int.tryParse(stockText);

        if (stockCount == null || stockCount <= 0) {
          continue;
        }

        result.add({
          'medicineName': medicineName,

          'isStock': true,

          'asNeeded': true,

          // 정기 복용하지 않음
          'dailyCount': 0,

          'dosage': 1.0,

          'timing': '필요 시',

          'period': 0,

          // 등록일부터 보유
          'startDate': _formatDate(startDate),

          // 종료일 없음
          'endDate': '',

          'setSize': stockCount,

          'totalCount': stockCount,
          // 초기 재고량
          'remainingCount': stockCount,

          // 상세 페이지에서 넘어온 정보 먼저
          ...detailFields,

          // API에서 다시 조회한 값이 있으면
          // 이 값들이 최종적으로 우선됨
          'itemSeq': stockData[i]['itemSeq'] ?? detailFields['itemSeq'],

          'usage':
              (stockData[i]['usageText'] ?? '').toString().trim().isNotEmpty
              ? stockData[i]['usageText']
              : detailFields['usage'],

          'minIntervalHours': stockData[i]['minIntervalHours'],
        });

        // 중요:
        // 아래 정기 복약 처리로 내려가지 않음
        continue;
      }

      // ========================================
      // 2. 일반 처방약
      // 기존처럼 복약 정보 필요
      // ========================================

      final registered = dosageData[i]['registered'] == true;

      if (!registered) {
        continue;
      }

      final info = dosageData[i]['dosageInfo'] as DosageInfo?;

      if (info == null) {
        continue;
      }

      int dailyCount;
      double dosage;
      int period;
      String timing;

      if (info.pillTimesPerDay > 0) {
        dailyCount = info.pillTimesPerDay;

        dosage = 1.0;

        period = info.pillDays > 0 ? info.pillDays : 1;

        timing = _timingToString(info);
      } else if (info.syrupTimesPerDay > 0) {
        dailyCount = info.syrupTimesPerDay;

        dosage = info.syrupMlPerDose;

        period = 1;
        timing = '시럽';
      } else {
        continue;
      }

      final endDate = startDate.add(Duration(days: period - 1));

      result.add({
        'medicineName': medicineName,

        'isStock': false,

        'asNeeded': false,

        'dailyCount': dailyCount,

        'dosage': dosage,

        'timing': timing,

        'startDate': _formatDate(startDate),

        'endDate': _formatDate(endDate),

        'period': period,

        ...detailFields,
      });
    }

    return result;
  }

  Future<void> _onRegisterPressed() async {
    if (_isSaving) return;

    if (medicines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('등록할 약이 없습니다.')));
      return;
    }

    // ------------------------------------
    // TextField에 수정 중인 이름 최종 반영
    // ------------------------------------
    for (int i = 0; i < medicines.length; i++) {
      final controller = medicines[i]['controller'] as TextEditingController;

      medicines[i]['name'] = controller.text.trim();

      medicines[i]['editing'] = false;
    }

    // ------------------------------------
    // 상비약 한 판 개수 검사
    // ------------------------------------
    final missingSetSizeNames = <String>[];

    for (int i = 0; i < medicines.length; i++) {
      final isStock = stockData[i]['isStock'] as bool;

      if (!isStock) continue;

      final text = (stockData[i]['setSizeController'] as TextEditingController)
          .text
          .trim();

      final setSize = int.tryParse(text);

      if (setSize == null || setSize <= 0) {
        missingSetSizeNames.add(medicines[i]['name'] as String);
      }
    }

    if (missingSetSizeNames.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '상비약으로 등록하려면 보유 수량을 입력해주세요.\n'
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

    for (int i = 0; i < medicines.length; i++) {
      final isStock = stockData[i]['isStock'] == true;

      // 상비약은 복약 횟수 입력 필요 없음
      if (isStock) {
        continue;
      }

      final registered = dosageData[i]['registered'] == true;

      if (!registered) {
        unregisteredNames.add(medicines[i]['name'] as String);
      }
    }
    // 복약 정보가 빠진 약이 있다면 확인창
    if (unregisteredNames.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('복약 정보 미입력'),
          content: Text(
            '아직 복약 정보가 입력되지 않은 약이 있어요.\n\n'
            '${unregisteredNames.map((n) => '• $n').join('\n')}\n\n'
            '복약 정보가 있는 약만 저장하시겠어요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('돌아가기'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '그래도 등록',
                style: TextStyle(color: Colors.black),
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

      final finalMedicines = _buildPrescriptionMedicines();

      final result = await ApiService.saveEditedPrescription(
        userId: widget.userProfile.userId,
        medicines: finalMedicines,
        pickedFile: widget.prescriptionImage,
      );

      debugPrint('처방전 최종 저장 결과: $result');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('약 등록이 완료되었습니다.')));

      // 저장 성공 후 홈 이동
      _navigateHome();
    } catch (e) {
      debugPrint('약 등록 중 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('약 등록 중 오류가 발생했습니다.\n$e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _navigateHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(profile: widget.userProfile),
      ),
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
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                                child: Image.asset(
                                  'assets/images/medicare_logo.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        '약 이름 확인 및 수정',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(
                              Icons.home_outlined,
                              color: Colors.black,
                              size: 28,
                            ),
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
                              bottom: BorderSide(color: Colors.black),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Text(
                                '약 LIST',
                                style: TextStyle(fontSize: 15),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                    onPressed: () async {
                                      debugPrint('약 LIST + 버튼 클릭');

                                      final List<String>? selectedNames =
                                          await Navigator.push<List<String>>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  MedicineSearchPage(
                                                    isForRegistration: true,

                                                    userProfile:
                                                        widget.userProfile,
                                                  ),
                                            ),
                                          );

                                      if (!mounted) {
                                        return;
                                      }

                                      debugPrint(
                                        'OcrEditPage가 받은 선택 결과: '
                                        '$selectedNames',
                                      );

                                      if (selectedNames == null ||
                                          selectedNames.isEmpty) {
                                        debugPrint('추가할 약이 반환되지 않음');

                                        return;
                                      }

                                      _addMedicinesWithNames(selectedNames);
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
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '+ 버튼으로 약을 추가해주세요.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black45,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: medicines.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: Colors.black12,
                                ),
                                itemBuilder: (context, index) {
                                  final medicine = medicines[index];
                                  final controller =
                                      medicine['controller']
                                          as TextEditingController;
                                  final isEditing = medicine['editing'] as bool;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        // ── 이름 수정 / 완료 버튼 ──
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isEditing) {
                                                medicines[index]['editing'] =
                                                    false;
                                                medicines[index]['name'] =
                                                    controller.text;
                                              } else {
                                                // 다른 항목 편집 모드 해제
                                                for (
                                                  int i = 0;
                                                  i < medicines.length;
                                                  i++
                                                ) {
                                                  if (i != index) {
                                                    medicines[i]['editing'] =
                                                        false;
                                                    medicines[i]['name'] =
                                                        (medicines[i]['controller']
                                                                as TextEditingController)
                                                            .text;
                                                  }
                                                }
                                                medicines[index]['editing'] =
                                                    true;
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isEditing
                                                  ? Colors.black
                                                  : Colors.white,
                                              border: Border.all(
                                                color: Colors.black,
                                              ),
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
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                  ),
                                                  autofocus: true,
                                                )
                                              : Text(
                                                  controller.text,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                  ),
                                                ),
                                        ),

                                        // ── 삭제 버튼 ────────────
                                        GestureDetector(
                                          onTap: () => _removeMedicine(index),
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: 6),
                                            child: Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.black38,
                                            ),
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
                              bottom: BorderSide(color: Colors.black),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: const Text(
                            '복약 횟수',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),

                        // 약별 복약 수정 버튼 목록
                        medicines.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '약을 추가하면 복약 정보를 입력할 수 있어요.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black45,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: medicines.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: Colors.black12,
                                ),
                                itemBuilder: (context, index) {
                                  final isRegistered =
                                      dosageData[index]['registered'] as bool;

                                  final dosageInfo =
                                      dosageData[index]['dosageInfo']
                                          as DosageInfo?;
                                  final name =
                                      medicines[index]['name'] as String;
                                  final isStock =
                                      stockData[index]['isStock'] == true;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
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
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),

                                            // 복약 횟수 수정 버튼
                                            if (isStock)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Colors.blueGrey.shade50,
                                                  border: Border.all(
                                                    color: Colors.blueGrey,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .medical_services_outlined,
                                                      size: 14,
                                                      color: Colors.blueGrey,
                                                    ),

                                                    SizedBox(width: 4),

                                                    Text(
                                                      '필요 시 복용',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.blueGrey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              GestureDetector(
                                                onTap: () =>
                                                    _openDosageEditPage(index),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
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
                                                          4,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (isRegistered) ...[
                                                        const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 14,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
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
                                        if (!isStock &&
                                            isRegistered &&
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
                              bottom: BorderSide(color: Colors.black),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: const Text(
                            '상비약 설정',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),

                        medicines.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '약을 추가하면 상비약 여부를 설정할 수 있어요.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black45,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
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
                                    separatorBuilder: (_, _) => const Divider(
                                      height: 1,
                                      color: Colors.black12,
                                    ),
                                    itemBuilder: (context, index) {
                                      final name =
                                          medicines[index]['name'] as String;
                                      final isStock =
                                          stockData[index]['isStock'] as bool;
                                      final setSizeController =
                                          stockData[index]['setSizeController']
                                              as TextEditingController;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: isStock,

                                                  onChanged: (checked) async {
                                                    final value =
                                                        checked ?? false;

                                                    setState(() {
                                                      stockData[index]['isStock'] =
                                                          value;

                                                      if (value) {
                                                        dosageData[index]['registered'] =
                                                            false;

                                                        dosageData[index]['dosageInfo'] =
                                                            null;
                                                      }
                                                    });

                                                    if (value) {
                                                      await _loadStockIntervalFromApi(
                                                        index,
                                                      );
                                                    }
                                                  },
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
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
                                                padding: const EdgeInsets.only(
                                                  left: 40,
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Text(
                                                      '보유 수량',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
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
                                                            TextAlign.center,
                                                        decoration: const InputDecoration(
                                                          isDense: true,
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                              ),
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Text(
                                                      '개',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (isStock)
                                              Builder(
                                                builder: (_) {
                                                  final loading =
                                                      stockData[index]['intervalLoading'] ==
                                                      true;

                                                  final interval =
                                                      stockData[index]['minIntervalHours'];

                                                  if (loading) {
                                                    return const Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 40,
                                                        bottom: 8,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            '공식 복용 간격 조회 중...',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .black54,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }

                                                  if (interval is int &&
                                                      interval > 0) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 40,
                                                            bottom: 8,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.schedule,
                                                            size: 15,
                                                            color: Colors.green,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            '공식 용법 기준 최소 '
                                                            '$interval시간 간격',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .green,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }

                                                  return const Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 40,
                                                      bottom: 8,
                                                    ),
                                                    child: Text(
                                                      '공식 용법에서 시간 단위 복용 간격을 '
                                                      '찾지 못했습니다.',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  );
                                                },
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
                    onPressed: _isSaving ? null : _onRegisterPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black38,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '등록 완료',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
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
      lines.add(info.pillTimings.map((t) => timingLabels[t]).join(', '));
    }
    if (info.syrupTimesPerDay > 0) {
      lines.add(
        '시럽: 1회 ${info.syrupMlPerDose.toStringAsFixed(0)}mL / ${info.syrupTimesPerDay}회',
      );
    }
    if (info.syrupStorages.isNotEmpty) {
      const storageLabels = {
        SyrupStorage.refrigerated: '냉장 보관',
        SyrupStorage.roomTemp: '실온 보관',
      };
      lines.add(info.syrupStorages.map((s) => storageLabels[s]).join(', '));
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
            .map(
              (l) => Text(
                l,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            )
            .toList(),
      ),
    );
  }
}
