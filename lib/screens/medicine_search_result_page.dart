import 'package:flutter/material.dart';
import 'medicine_detail_page.dart';
import 'ocr_edit_page.dart';
import 'user_profile.dart';
import '../services/api_service.dart';

enum MedicineSearchMode { info, register }

class MedicineSearchResultPage extends StatefulWidget {
  final String query;
  final MedicineSearchMode mode;
  final List<String> selectedMedicines;
  final UserProfile userProfile; // ✅ UserProfile 추가
  final void Function(List<String> selectedNames)? onSelectionComplete;

  const MedicineSearchResultPage({
    super.key,
    required this.query,
    this.mode = MedicineSearchMode.info,
    this.selectedMedicines = const [],
    required this.userProfile, // ✅ UserProfile 추가
    this.onSelectionComplete,
  });

  @override
  State<MedicineSearchResultPage> createState() => _MedicineSearchResultPageState();
}

class _MedicineSearchResultPageState extends State<MedicineSearchResultPage> {
  final Set<String> _selected = {};

  List<Map<String, dynamic>>
    _results = [];

bool _isLoading = true;

String? _errorMessage;

  static ({String label, Color color, IconData icon}) _purchaseInfo(String type) {
    switch (type) {
      case 'convenience':
        return (label: '편의점 구매 가능', color: const Color(0xFF1565C0), icon: Icons.store_outlined);
      case 'prescription':
        return (label: '처방전 필요', color: const Color(0xFFC62828), icon: Icons.local_hospital_outlined);
      default:
        return (label: '약국 구매 가능', color: const Color(0xFF2E7D32), icon: Icons.local_pharmacy_outlined);
    }
  }

@override
void initState() {
  super.initState();

  _selected.addAll(
    widget.selectedMedicines,
  );

  _searchMedicines();
}

Future<void> _searchMedicines() async {
  final query =
      widget.query.trim();

  if (query.isEmpty) {
    setState(() {
      _isLoading = false;
      _results = [];
      _errorMessage =
          '검색어가 비어 있습니다.';
    });

    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response =
        await ApiService.searchDrugs(
      query,
    );

    final rawMedicines =
        response['medicines'];

    final List<
        Map<String, dynamic>>
        results = [];

    if (rawMedicines is List) {
      for (final item
          in rawMedicines) {
        if (item is! Map) {
          continue;
        }

        final drug =
            Map<String, dynamic>.from(
          item,
        );

        results.add(
          _convertDrug(
            drug,
          ),
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _results = results;
      _isLoading = false;
    });
  } catch (e) {
    debugPrint(
      '의약품 검색 오류: $e',
    );

    if (!mounted) return;

    setState(() {
      _results = [];
      _isLoading = false;
      _errorMessage =
          '의약품 정보를 불러오지 못했습니다.\n$e';
    });
  }
}

Map<String, dynamic> _convertDrug(
  Map<String, dynamic> drug,
) {
  Map<String, dynamic> raw = {};

  if (drug['raw'] is Map) {
    raw =
        Map<String, dynamic>.from(
      drug['raw'],
    );
  }

  final productName =
      (
        drug['itemName']
        ?? raw['ITEM_NAME']
        ?? ''
      )
          .toString()
          .trim();

  final manufacturer =
      (
        drug['entpName']
        ?? raw['ENTP_NAME']
        ?? ''
      )
          .toString()
          .trim();

  final ingredient =
      (
        drug['mainIngredient']
        ?? raw['ITEM_INGR_NAME']
        ?? ''
      )
          .toString()
          .trim();

  final category =
      (
        drug['category']
        ?? raw['SPCLTY_PBLC']
        ?? ''
      )
          .toString()
          .trim();

  final productType =
      (
        drug['productType']
        ?? raw['PRDUCT_TYPE']
        ?? ''
      )
          .toString()
          .trim();

  final imageUrl =
      (
        drug['imageUrl']
        ?? raw['BIG_PRDT_IMG_URL']
        ?? ''
      )
          .toString()
          .trim();

  final purchaseType =
      category.contains('전문')
          ? 'prescription'
          : 'pharmacy';

  return {
    // 기존 화면에서 사용하던 key
    'productName':
        productName,

    'manufacturer':
        manufacturer.isEmpty
            ? '제조사 정보 없음'
            : manufacturer,

    'ingredient':
        ingredient.isEmpty
            ? '성분 정보 없음'
            : ingredient,

    'purchaseType':
        purchaseType,

    'effect':
        productType.isEmpty
            ? '상세정보 조회 필요'
            : productType,

    'dosage':
        '복용법은 제품 설명 또는 처방을 확인해주세요.',

    'cautions':
        <String>[],

    'contraindications':
        <String>[],

    // 식약처 데이터도 유지
    'itemSeq':
        drug['itemSeq']
        ?? raw['ITEM_SEQ'],

    'category':
        category,

    'productType':
        productType,

    'imageUrl':
        imageUrl,

    'itemEngName':
        drug['itemEngName']
        ?? raw['ITEM_ENG_NAME'],

    'raw':
        raw,
  };
}

  void _onCardTap(Map<String, dynamic> medicine) {
    if (widget.mode == MedicineSearchMode.info) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineDetailPage(
            medicine: medicine,
            profile: widget.userProfile,
          ),
        ),
      );
    } else {
      setState(() {
        final name = medicine['productName'] as String;
        if (_selected.contains(name)) {
          _selected.remove(name);
        } else {
          _selected.add(name);
        }
      });
    }
  }

  void _onRegisterSelected() {
    // ✅ 호출한 쪽이 선택 결과를 직접 받아서 처리하고 싶은 경우(예: MedicineSearchPage가
    // 받아서 자기를 연 곳에 그대로 전달), onSelectionComplete 콜백으로 넘겨줍니다.
    if (widget.onSelectionComplete != null) {
      widget.onSelectionComplete!(_selected.toList());
      return;
    }

    final ocrMedicines =
      _selected.map((name) {
    return <String, dynamic>{
      'medicineName': name,
      'dailyCount': 0,
      'dosage': 1.0,
      'period': 0,
      'timing': '',
    };
  }).toList();

  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => OcrEditPage(
      ocrMedicines: ocrMedicines,
      userProfile: widget.userProfile,
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    final isRegisterMode = widget.mode == MedicineSearchMode.register;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // ── 헤더 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
              child: Row(
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
                        '"${widget.query}" 검색 결과',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            if (isRegisterMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF5F5F5),
                child: const Text(
                  '등록할 약을 선택하세요.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),

            const Divider(height: 1, color: Colors.black12),

            // ── 결과 목록 ──────────────────────────────────────
            Expanded(
  child: _isLoading
      ? const Center(
          child:
              CircularProgressIndicator(),
        )
      : _errorMessage != null
          ? Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color:
                          Colors.black38,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      _errorMessage!,
                      textAlign:
                          TextAlign.center,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    OutlinedButton(
                      onPressed:
                          _searchMedicines,
                      child:
                          const Text(
                        '다시 시도',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _results.isEmpty
              ? const Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          Colors.black45,
                    ),
                  ),
                )
              : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final medicine = _results[index];
                        final productName = medicine['productName'] as String;
                        final purchase = _purchaseInfo(medicine['purchaseType'] as String);
                        final isSelected = _selected.contains(productName);

                        return GestureDetector(
                          onTap: () => _onCardTap(medicine),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isRegisterMode && isSelected
                                  ? const Color(0xFFF0F0F0)
                                  : Colors.white,
                              border: Border.all(
                                color: isRegisterMode && isSelected
                                    ? Colors.black
                                    : Colors.black26,
                                width: isRegisterMode && isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Builder(
  builder: (context) {
    final imageUrl =
        (
          medicine['imageUrl']
          ?? ''
        )
            .toString()
            .trim();

    // ✅ 이미지 URL 확인
    debugPrint(
      '[DRUG IMAGE] ${medicine['productName']}',
    );

    debugPrint(
      '[DRUG IMAGE URL] $imageUrl',
    );

    // 이미지 주소 자체가 없는 경우
    if (imageUrl.isEmpty) {
      debugPrint(
        '[DRUG IMAGE] 이미지 URL 없음',
      );

      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(
            0xFFF2F2F2,
          ),
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.medication_outlined,
          size: 30,
          color: Colors.black38,
        ),
      );
    }

    final proxyUrl =
    ApiService.drugImageProxyUrl(
  imageUrl,
);

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(8),
      child: Image.network(
        proxyUrl,
        width: 64,
        height: 64,
        fit: BoxFit.contain,

        // ✅ 이미지 로딩 실패 원인 출력
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            '[DRUG IMAGE ERROR] $error',
          );

          debugPrint(
            '[DRUG IMAGE FAILED URL] $imageUrl',
          );

          return Container(
            width: 64,
            height: 64,
            color: const Color(
              0xFFF2F2F2,
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: Colors.black38,
            ),
          );
        },
      ),
    );
  },
),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        medicine['manufacturer'] as String,
                                        style: const TextStyle(fontSize: 13, color: Colors.black45),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(purchase.icon, size: 14, color: purchase.color),
                                          const SizedBox(width: 4),
                                          Text(
                                            purchase.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: purchase.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isRegisterMode)
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isSelected ? Colors.black : Colors.black26,
                                    size: 22,
                                  )
                                else
                                  const Icon(Icons.chevron_right, color: Colors.black38),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // register 모드: 하단 선택 완료 버튼
            if (isRegisterMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selected.isNotEmpty ? _onRegisterSelected : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: Colors.black38,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _selected.isEmpty
                          ? '약을 선택해주세요'
                          : '등록하기',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}