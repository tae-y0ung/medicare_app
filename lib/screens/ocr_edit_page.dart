import 'package:flutter/material.dart';
import 'home_page.dart';
import 'medicine_search_page.dart';
import 'dosage_edit_page.dart';
import 'user_profile.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/loading_overlay.dart';
import 'package:flutter/services.dart';

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

  final TextEditingController _prescriptionCategoryController =
      TextEditingController();

  late final String _prescriptionGroupId =
      '${DateTime.now().microsecondsSinceEpoch}';

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
    dosageData = widget.ocrMedicines
        .map<Map<String, dynamic>>(
          (medicine) => _createInitialDosageData(medicine),
        )
        .toList();

    // ─────────────────────────────
    // 3. 상비약 설정
    // OCR에서 읽은 모든 약 이름과 같은 인덱스 생성
    // ─────────────────────────────
    stockData = widget.ocrMedicines.map<Map<String, dynamic>>((medicine) {
      final initialIsStock = medicine['isStock'] == true;

      return {
        'isStock': initialIsStock,

        'setSizeController': TextEditingController(),

        'selectedPackageOption': null,

        // API에서 자동 조회
        'minIntervalHours': null,

        'usageText': '',

        'itemSeq': medicine['itemSeq'],

        'intervalLoading': false,
      };
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < medicines.length; i++) {
        _loadPackageOptions(i);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (int i = 0; i < stockData.length; i++) {
        if (stockData[i]['isStock'] == true) {
          await _loadStockIntervalFromApi(i);
        }
      }
    });
  }

  Widget _buildStockSettingItem(int index) {
    final medicine = medicines[index];
    final stock = stockData[index];

    final nameController = medicine['controller'] as TextEditingController;

    final countController = stock['setSizeController'] as TextEditingController;

    final meta = medicine['meta'] as Map<String, dynamic>;
    final isStock = stock['isStock'] == true;

    final rawOptions = meta['packageOptions'];

    final options = rawOptions is List
        ? rawOptions
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
        : <String>[];

    final selected = (stock['selectedPackageOption'] ?? '').toString();

    final selectedValue = options.contains(selected) ? selected : null;

    final intervalLoading = stock['intervalLoading'] == true;
    final interval = stock['minIntervalHours'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 항상 표시: 체크박스 + 약 이름
          Row(
            children: [
              Checkbox(
                value: isStock,
                onChanged: (checked) {
                  final value = checked ?? false;

                  setState(() {
                    stock['isStock'] = value;
                  });

                  if (value) {
                    _loadPackageOptions(index);
                    _loadStockIntervalFromApi(index);
                  }
                },
              ),
              Expanded(
                child: Text(
                  nameController.text,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              Text(
                '상비약',
                style: TextStyle(
                  fontSize: 13,
                  color: isStock ? Colors.black87 : Colors.black38,
                ),
              ),
            ],
          ),

          // 체크한 약만: 약 이름 아래에 규격과 수량 표시
          if (isStock)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    '포장 규격 선택',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  if (options.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        '${identityHashCode(stock)}-$selectedValue',
                      ),
                      value: selectedValue,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: '구매한 포장 규격을 선택하세요',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: options.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        final count = _packageCountFromOption(value);

                        setState(() {
                          stock['selectedPackageOption'] = value;

                          countController.text = count != null
                              ? count.toString()
                              : '';
                        });
                      },
                    )
                  else
                    const Text(
                      '조회된 포장 규격이 없거나 조회 중입니다.\n'
                      '보유 수량을 직접 입력해주세요.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('보유 수량', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: countController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('개'),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (intervalLoading)
                    const Text(
                      '공식 복용 간격 조회 중...',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    )
                  else if (interval is int && interval > 0)
                    Text(
                      '공식 용법 기준 최소 $interval시간 간격',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    )
                  else
                    const Text(
                      '공식 용법에서 시간 단위 복용 간격을 '
                      '찾지 못했습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _createInitialDosageData(Map<String, dynamic> medicine) {
    final dailyCount = _toInt(medicine['dailyCount']);
    final period = _toInt(medicine['period']);
    final timing = (medicine['timing'] ?? '').toString().trim();

    final parsedTimings = _timingFromOcr(timing);

    return <String, dynamic>{
      'registered': true,
      'dosageInfo': DosageInfo(
        // OCR에서 읽은 값이 있으면 유지
        pillTimesPerDay: dailyCount > 0 ? dailyCount : 3,
        pillDays: period > 0 ? period : 3,

        // 기존 시간이 있으면 유지, 없을 때만 기본값
        pillTimings: parsedTimings.isNotEmpty
            ? parsedTimings
            : <MedicineTiming>{MedicineTiming.afterMeal30},
      ),
    };
  }

  void _onMedicineNameChanged(int index, String newName) {
    if (index < 0 || index >= medicines.length) return;

    final meta = medicines[index]['meta'] as Map<String, dynamic>;

    final previousName = (meta['medicineName'] ?? '').toString().trim();

    // 이미 처리한 변경이면 중복 초기화하지 않음
    if (newName.trim() == previousName && meta['manualNameEdited'] == true) {
      return;
    }

    setState(() {
      medicines[index]['name'] = newName.trim();

      // 기존 OCR 약 추천 제거
      meta['suggestedMedicineName'] = null;
      meta['medicineCandidates'] = <Map<String, dynamic>>[];
      meta['manualNameEdited'] = true;

      // 수동 변경된 약 이름 기록
      meta['medicineName'] = newName.trim();

      // 이전 약의 식약처 품목코드 해제
      meta['itemSeq'] = null;
      meta['medicineUserConfirmed'] = false;

      // 이전 약의 상세정보도 초기화
      for (final field in [
        'manufacturer',
        'ingredient',
        'effect',
        'usage',
        'cautions',
        'contraindications',
        'packageOptions',
        'packageCount',
        'packageUnit',
        'packageCountUnit',
      ]) {
        meta.remove(field);
      }

      stockData[index]['itemSeq'] = null;
      stockData[index]['usageText'] = '';
      stockData[index]['minIntervalHours'] = null;
      stockData[index]['selectedPackageOption'] = null;
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

  List<Map<String, dynamic>> _medicineSuggestions(int index) {
    final meta = medicines[index]['meta'] as Map<String, dynamic>;
    // 사용자가 직접 약 이름을 수정했다면
    // 이전 OCR 기준으로 검색한 추천을 표시하지 않음
    if (meta['manualNameEdited'] == true) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addCandidate(Map<String, dynamic> candidate) {
      final name = (candidate['itemName'] ?? '').toString().trim();

      if (name.isEmpty) return;

      final key = name.replaceAll(' ', '').toLowerCase();
      if (!seen.add(key)) return;

      final currentName =
          (medicines[index]['controller'] as TextEditingController).text.trim();

      // 이름이 같더라도 품목코드가 미확정이면
      // 사용자가 공식 품목을 선택할 수 있게 한다.
      final currentItemSeq = (meta['itemSeq'] ?? '').toString().trim();

      final candidateItemSeq = (candidate['itemSeq'] ?? '').toString().trim();

      if (name == currentName &&
          currentItemSeq.isNotEmpty &&
          currentItemSeq == candidateItemSeq) {
        return;
      }

      result.add(candidate);
    }

    // 1. 백엔드가 추천한 공식 의약품명
    final suggested = (meta['suggestedMedicineName'] ?? '').toString().trim();

    if (suggested.isNotEmpty) {
      addCandidate({
        'itemName': suggested,
        // 기존 추천에는 itemSeq가 없을 수 있음
        'itemSeq': '',
        'requiresLookup': true,
        'numberConflict': meta['ocrNumberConflict'] == true,
      });
    }

    // 2. 식약처 부분 검색에서 가져온 후보들
    final rawCandidates = meta['medicineCandidates'];

    if (rawCandidates is List) {
      for (final raw in rawCandidates) {
        if (raw is! Map) continue;

        addCandidate(Map<String, dynamic>.from(raw));
      }
    }

    return result;
  }

  Future<void> _selectMedicineSuggestion(
    int index,
    Map<String, dynamic> candidate,
  ) async {
    if (index < 0 || index >= medicines.length) return;

    final targetMedicine = medicines[index];

    final selectedName = (candidate['itemName'] ?? '').toString().trim();

    var selectedItemSeq = (candidate['itemSeq'] ?? '').toString().trim();

    if (selectedName.isEmpty) return;

    // 백엔드 suggestedMedicineName에는 itemSeq가
    // 없는 경우가 있으므로 공식 이름으로 다시 조회한다.
    if (selectedItemSeq.isEmpty) {
      try {
        final response = await ApiService.searchDrugs(selectedName);

        final items = response['medicines'];

        if (items is List) {
          for (final raw in items) {
            if (raw is! Map) continue;

            final item = Map<String, dynamic>.from(raw);

            final name = (item['itemName'] ?? '').toString().trim();

            // 반드시 공식 제품명 전체가 일치해야 함
            if (name == selectedName) {
              selectedItemSeq = (item['itemSeq'] ?? '').toString().trim();
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('추천 의약품 조회 실패: $e');
      }
    }

    if (!mounted) return;

    if (selectedItemSeq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식약처 품목정보를 확인하지 못했습니다. 다시 시도해주세요.')),
      );
      return;
    }

    // 검색하는 동안 항목이 삭제되거나 이동한 경우 보호
    if (index >= medicines.length ||
        !identical(medicines[index], targetMedicine)) {
      return;
    }

    setState(() {
      final controller =
          medicines[index]['controller'] as TextEditingController;

      controller.text = selectedName;

      medicines[index]['name'] = selectedName;
      medicines[index]['editing'] = false;

      final meta = medicines[index]['meta'] as Map<String, dynamic>;

      // 사용자 선택을 통해 공식 품목 확정
      meta['medicineName'] = selectedName;
      meta['itemSeq'] = selectedItemSeq;
      meta['needsReview'] = true;
      meta['medicineAutoCorrected'] = false;
      meta['medicineUserConfirmed'] = true;
      meta['suggestedMedicineName'] = null;
      meta['medicineCandidates'] = [];
      meta['manualNameEdited'] = false;

      // 이전 약의 상세정보가 남지 않도록 초기화
      for (final field in [
        'manufacturer',
        'ingredient',
        'purchaseType',
        'medicineType',
        'medicineTypeLabel',
        'effect',
        'usage',
        'cautions',
        'contraindications',
        'category',
        'productType',
        'imageUrl',
        'packageUnit',
        'packageOptions',
        'packageCount',
        'packageCountUnit',
      ]) {
        meta.remove(field);
      }

      stockData[index]['itemSeq'] = selectedItemSeq;
      stockData[index]['usageText'] = '';
      stockData[index]['minIntervalHours'] = null;
      stockData[index]['selectedPackageOption'] = null;
    });

    // 새 품목코드 기준으로 포장정보 갱신
    await _loadPackageOptions(index);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$selectedName 선택 완료')));
  }

  Future<void> _openMedicineSearchDialog(int index) async {
  if (index < 0 || index >= medicines.length) return;

  final currentController =
      medicines[index]['controller'] as TextEditingController;

  final searchController = TextEditingController(
    text: currentController.text,
  );

  List<Map<String, dynamic>> results = [];
  bool isLoading = false;
  String? errorMessage;

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> search() async {
              final keyword = searchController.text.trim();

              if (keyword.isEmpty) {
                setDialogState(() {
                  results = [];
                  errorMessage = '검색할 약 이름을 입력해주세요.';
                });
                return;
              }

              setDialogState(() {
                isLoading = true;
                results = [];
                errorMessage = null;
              });

              try {
                final response =
                    await ApiService.searchDrugs(keyword);

                final raw = response['medicines'];

                final found = raw is List
                    ? raw
                        .whereType<Map>()
                        .map(
                          (e) => Map<String, dynamic>.from(e),
                        )
                        .where(
                          (e) =>
                              (e['itemName'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty &&
                              (e['itemSeq'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty,
                        )
                        .toList()
                    : <Map<String, dynamic>>[];

                if (!dialogContext.mounted) return;

                setDialogState(() {
                  results = found;
                  isLoading = false;
                  errorMessage = found.isEmpty
                      ? '품목기준코드가 있는 의약품을 찾지 못했습니다.'
                      : null;
                });
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  isLoading = false;
                  errorMessage = '검색 실패: $e';
                });
              }
            }

            return AlertDialog(
              title: const Text('의약품 검색 및 선택'),
              content: SizedBox(
                width: 480,
                height: 430,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => search(),
                      decoration: InputDecoration(
                        hintText: '약 이름을 입력하세요',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: isLoading ? null : search,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '식약처 검색 결과에서 제품을 선택해주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (isLoading)
                      const LinearProgressIndicator(),

                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),

                    Expanded(
                      child: ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, resultIndex) {
                          final drug = results[resultIndex];

                          final name =
                              (drug['itemName'] ?? '').toString();

                          final itemSeq =
                              (drug['itemSeq'] ?? '').toString();

                          return ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '품목기준코드: $itemSeq',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () async {
                              Navigator.pop(dialogContext);

                              await _selectMedicineSuggestion(
                                index,
                                drug,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    // 팝업의 종료 애니메이션 이후 컨트롤러를 해제
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchController.dispose();
    });
  }
}


  Widget _buildMedicineSuggestions(int index) {
    final suggestions = _medicineSuggestions(index);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9DEE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '식약처 의약품 추천',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            for (final candidate in suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (candidate['itemName'] ?? '').toString(),
                      style: const TextStyle(fontSize: 13),
                    ),

                    if (candidate['numberConflict'] == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Text(
                          '숫자 또는 함량이 다를 수 있습니다. '
                          '원본 처방전을 확인하세요.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () =>
                            _selectMedicineSuggestion(index, candidate),
                        child: const Text('이 약 선택'),
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              '추천 결과는 자동 적용되지 않습니다.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
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

    _prescriptionCategoryController.dispose();

    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchDosageInfo(String medicineName) async {
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

        dosageData.add(_createInitialDosageData(<String, dynamic>{}));

        // ============================
        // 3. 상비약 정보
        // ============================

        stockData.add(<String, dynamic>{
          'isStock': false,

          'setSizeController': TextEditingController(),

          'selectedPackageOption': null,

          'minIntervalHours': null,

          'usageText': '',

          'itemSeq': null,

          'intervalLoading': false,
        });

        _loadPackageOptions(medicines.length - 1);

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
      } else if (info.syrupMlPerDose > 0) {
  // 시럽은 1회 복용량만 저장하고,
  // 하루 복용 횟수는 처방 정보가 확인된 후 설정
  dailyCount = 1;
  dosage = info.syrupMlPerDose;
  period = 1;
  timing = '시럽';
} else {
  continue;
}

      final endDate = startDate.add(Duration(days: period - 1));

      final totalCount = dailyCount * period * dosage;

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

        // 전체 처방 수량
        'totalCount': totalCount,

        // 최초 등록 시 남은 수량
        'remainingCount': totalCount,

        ...detailFields,
      });
    }

    return result;
  }

  int? _packageCountFromOption(String option) {
    final text = option
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('＊', '*');

    if (text.isEmpty) return null;

    // 전체 수량 + 괄호 안 포장 설명
    // 예: 28정(14정/PTP×2) → 전체 28정
    final totalBeforeDetails = RegExp(
      r'^(\d+)(?:정|캡슐|캅셀|개)\(',
    ).firstMatch(text);

    if (totalBeforeDetails != null) {
      final count = int.tryParse(totalBeforeDetails.group(1)!);
      return count != null && count > 0 ? count : null;
    }

    // 단일 수량
    // 예: 28정, 30캡슐
    final singleCount = RegExp(r'^(\d+)(?:정|캡슐|캅셀|개)$').firstMatch(text);

    if (singleCount != null) {
      final count = int.tryParse(singleCount.group(1)!);
      return count != null && count > 0 ? count : null;
    }

    // 한 포장 수량 × 포장 개수
    // 예: 14정/PTP×2, 14정×2PTP → 28
    final multipliedCount = RegExp(
      r'^(\d+)(?:정|캡슐|캅셀|개)'
      r'(?:/[^×xX*()]+)?'
      r'[×xX*](\d+)'
      r'(?:PTP|포|판|병|통|박스|상자|팩)?$',
      caseSensitive: false,
    ).firstMatch(text);

    if (multipliedCount != null) {
      final perPackage = int.tryParse(multipliedCount.group(1)!);

      final packageCount = int.tryParse(multipliedCount.group(2)!);

      if (perPackage != null &&
          packageCount != null &&
          perPackage > 0 &&
          packageCount > 0) {
        return perPackage * packageCount;
      }
    }

    // 확실하지 않은 형식은 임의 계산하지 않음
    return null;
  }

  Future<void> _loadPackageOptions(int index) async {
    if (index < 0 || index >= medicines.length) return;

    final meta = medicines[index]['meta'] as Map<String, dynamic>;
    var itemSeq = (meta['itemSeq'] ?? '').toString().trim();

    // 품목기준코드가 없다면 약 이름으로 검색
    if (itemSeq.isEmpty) {
      final controller =
          medicines[index]['controller'] as TextEditingController;
      final name = controller.text.trim();

      if (name.isEmpty) return;

      try {
        final searchResult = await ApiService.searchDrugs(name);
        final rawMedicines = searchResult['medicines'];

        if (rawMedicines is List) {
          for (final item in rawMedicines) {
            if (item is! Map) continue;

            final drug = Map<String, dynamic>.from(item);
            final itemName = (drug['itemName'] ?? '').toString().trim();

            // 다른 약이 선택되지 않도록 정확히 일치해야 함
            if (itemName == name) {
              itemSeq = (drug['itemSeq'] ?? '').toString();
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('포장 규격 약 검색 실패: $e');
      }
    }

    if (itemSeq.isEmpty) return;

    try {
      final response = await ApiService.getDrugDetail(itemSeq);
      final rawDrug = response['drug'];

      if (rawDrug is! Map) return;

      final drug = Map<String, dynamic>.from(rawDrug);

      if (!mounted || index >= medicines.length) return;

      setState(() {
        final currentMeta = medicines[index]['meta'] as Map<String, dynamic>;

        currentMeta['itemSeq'] = itemSeq;
        currentMeta['packageUnit'] = drug['packageUnit'] ?? '';
        currentMeta['packageOptions'] = drug['packageOptions'] ?? <String>[];
        currentMeta['packageCount'] = drug['packageCount'];
        currentMeta['packageCountUnit'] = drug['packageCountUnit'] ?? '';
      });
    } catch (e) {
      debugPrint('포장 규격 상세 조회 실패: $e');
    }
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
// 직접 변경된 의약품의 품목기준코드 검사
// ------------------------------------
final unverifiedMedicines = <String>[];

for (int i = 0; i < medicines.length; i++) {
  final meta =
      medicines[i]['meta'] as Map<String, dynamic>;

  final itemSeq =
      (meta['itemSeq'] ?? '').toString().trim();

  final name =
      (medicines[i]['controller'] as TextEditingController)
          .text
          .trim();

  final confirmedName =
      (meta['medicineName'] ?? '').toString().trim();

  // 수동 수정 이력이 있거나
  // 공식 품목 선택 후 이름이 달라진 경우 차단
  final manuallyEdited =
      meta['manualNameEdited'] == true ||
      (meta['medicineUserConfirmed'] == true &&
          name != confirmedName);

  if (manuallyEdited && itemSeq.isEmpty) {
    unverifiedMedicines.add(name);
  } else if (manuallyEdited &&
      name != confirmedName) {
    unverifiedMedicines.add(name);
  }
}

if (unverifiedMedicines.isNotEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '다음 약은 검색 결과에서 공식 제품을 선택해주세요.\n'
        '${unverifiedMedicines.join(', ')}',
      ),
    ),
  );
  return;
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

      for (final medicine in finalMedicines) {
        debugPrint(
          '[GROUP SEND] ${medicine['medicineName']} '
          '/ ${medicine['prescriptionGroupId']} '
          '/ ${medicine['prescriptionCategory']}',
        );
      }

      final enteredCategory =
    _prescriptionCategoryController.text.trim();

final now = DateTime.now();

final defaultCategory =
    '${now.year}.'
    '${now.month.toString().padLeft(2, '0')}.'
    '${now.day.toString().padLeft(2, '0')} 처방전';

final categoryName = enteredCategory.isNotEmpty
    ? enteredCategory
    : defaultCategory;

for (final medicine in finalMedicines) {
  if (medicine['isStock'] == true) continue;

  medicine['prescriptionGroupId'] = _prescriptionGroupId;
  medicine['prescriptionCategory'] = categoryName;
}

      // 이번 처방전의 모든 정기복용약에 같은 그룹 정보 부여
      for (final medicine in finalMedicines) {
        if (medicine['isStock'] == true) continue;

        medicine['prescriptionGroupId'] = _prescriptionGroupId;
        medicine['prescriptionCategory'] = categoryName;
      }

      debugPrint('===== 처방전 그룹 전송 확인 =====');
      for (final medicine in finalMedicines) {
        debugPrint(
          '${medicine['medicineName']} / '
          'groupId: ${medicine['prescriptionGroupId']} / '
          'category: ${medicine['prescriptionCategory']}',
        );
      }

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
    return LoadingOverlay(
      isLoading: _isSaving,
      message: '처방전을 등록하고 있어요...',
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

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '처방전 카테고리',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _prescriptionCategoryController,
                                maxLength: 40,
                                decoration: InputDecoration(
                                  hintText: '예: 감기 처방전, 위장약 처방전',
                                  helperText: '비워두면 등록 날짜로 이름이 생성됩니다.',
                                  prefixIcon: const Icon(Icons.folder_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                                        OutlinedButton.icon(
  onPressed: () => _openMedicineSearchDialog(index),
  label: const Text(
    '수정',
    style: TextStyle(fontSize: 12),
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 8,
    ),
  ),
),

                                        const SizedBox(width: 8),

                                        // ── 약 이름 ──────────────
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
  controller.text,
  style: const TextStyle(
    fontSize: 15,
  ),
),

                                              _buildMedicineSuggestions(index),
                                            ],
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
                            border: Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          child: const Text(
                            '복약 횟수',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),

                        if (medicines.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              '약을 추가하면 복약 정보를 설정할 수 있어요.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: medicines.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Colors.black12),
                            itemBuilder: (context, index) {
                              final controller =
                                  medicines[index]['controller']
                                      as TextEditingController;

                              final isRegistered =
                                  dosageData[index]['registered'] == true;

                              final dosageInfo =
                                  dosageData[index]['dosageInfo']
                                      as DosageInfo?;

                              final isStock =
                                  stockData[index]['isStock'] == true;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 약 이름과 수정 버튼을 같은 줄에 배치
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            controller.text,
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _openDosageEditPage(index),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isRegistered
                                                ? '복약 횟수 수정'
                                                : '복약 횟수 입력',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black87,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            minimumSize: const Size(0, 38),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // 복약 정보 요약은 아래에 유지
                                    if (!isStock && dosageInfo != null)
                                      _buildDosageSummary(dosageInfo),

                                    if (isStock)
                                      const Text(
                                        '상비약으로 설정됨 · 필요 시 복용',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                          child: Text(
                            '실제 처방·제품 복용법에 맞게 확인하고 수정해주세요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 별도 상비약 설정 박스 ───────────
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
                            border: Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          child: const Text(
                            '상비약 설정',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),

                        if (medicines.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              '등록할 약이 없습니다.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: medicines.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Colors.black12),
                            itemBuilder: (context, index) {
                              return _buildStockSettingItem(index);
                            },
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
    if (info.syrupMlPerDose > 0) {
  lines.add(
    '시럽: 1회 ${info.syrupMlPerDose.toStringAsFixed(0)}mL',
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
        color: const Color(0xFFF0EAF8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB9A5E0)),
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
