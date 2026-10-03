import 'package:flutter/material.dart';
import 'medicine_detail_page.dart';
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
  State<MedicineSearchResultPage> createState() =>
      _MedicineSearchResultPageState();
}

class _MedicineSearchResultPageState extends State<MedicineSearchResultPage> {
  final Set<String> _selected = {};

  List<Map<String, dynamic>> _results = [];
  String _purchaseFilter = 'all';

  List<Map<String, dynamic>> get _filteredResults {
    if (_purchaseFilter == 'all') {
      return _results;
    }

    return _results.where((medicine) {
      return (medicine['purchaseType'] ?? '').toString() == _purchaseFilter;
    }).toList();
  }

  bool _isLoading = true;

  String? _errorMessage;

  static ({String label, Color color, IconData icon}) _purchaseInfo(
    String type,
  ) {
    switch (type) {
      case 'convenience':
        return (
          label: '편의점 구매 가능',
          color: const Color(0xFF1565C0),
          icon: Icons.store_outlined,
        );
      case 'prescription':
        return (
          label: '처방전 필요',
          color: const Color(0xFFC62828),
          icon: Icons.local_hospital_outlined,
        );
      default:
        return (
          label: '약국 구매 가능',
          color: const Color(0xFF2E7D32),
          icon: Icons.local_pharmacy_outlined,
        );
    }
  }

  Widget _purchaseFilterButton({required String value, required String label}) {
    final selected = _purchaseFilter == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _purchaseFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.black : Colors.black26),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _selected.addAll(widget.selectedMedicines);

    _searchMedicines();
  }

  Future<void> _searchMedicines() async {
    final query = widget.query.trim();

    if (query.isEmpty) {
      setState(() {
        _isLoading = false;
        _results = [];
        _errorMessage = '검색어가 비어 있습니다.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.searchDrugs(query);

      final rawMedicines = response['medicines'];

      final List<Map<String, dynamic>> results = [];

      if (rawMedicines is List) {
        for (final item in rawMedicines) {
          if (item is! Map) {
            continue;
          }

          final drug = Map<String, dynamic>.from(item);

          results.add(_convertDrug(drug));
        }
      }

      if (!mounted) return;

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('의약품 검색 오류: $e');

      if (!mounted) return;

      setState(() {
        _results = [];
        _isLoading = false;
        _errorMessage = '의약품 정보를 불러오지 못했습니다.\n$e';
      });
    }
  }

String _cleanDrugDocumentText(
  String text,
) {
  var result = text;

  // CDATA 제거
  result = result
      .replaceAll(
        '<![CDATA[',
        '',
      )
      .replaceAll(
        ']]>',
        '',
      );

  // XML / HTML 태그 제거
  result = result.replaceAll(
    RegExp(r'<[^>]+>'),
    ' ',
  );

  // 자주 등장하는 HTML entity 처리
  result = result
      .replaceAll(
        '&nbsp;',
        ' ',
      )
      .replaceAll(
        '&amp;',
        '&',
      )
      .replaceAll(
        '&lt;',
        '<',
      )
      .replaceAll(
        '&gt;',
        '>',
      )
      .replaceAll(
        '&quot;',
        '"',
      )
      .replaceAll(
        '&#39;',
        "'",
      );

  // &#12316; 같은 숫자 entity 처리
  result = result.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (match) {
      final code =
          int.tryParse(
        match.group(1) ?? '',
      );

      if (code == null) {
        return match.group(0) ?? '';
      }

      return String.fromCharCode(
        code,
      );
    },
  );

  // 여러 공백 / 줄바꿈 정리
  result = result.replaceAll(
    RegExp(r'\s+'),
    ' ',
  );

  return result.trim();
}

List<String> _extractDrugWarnings(
  String document, {
  required bool contraindications,
}) {
  if (document.trim().isEmpty) {
    return <String>[];
  }

  final result = <String>[];

  final articleRegex = RegExp(
    r'<ARTICLE[^>]*title="([^"]*)"[^>]*>(.*?)</ARTICLE>',
    caseSensitive: false,
    dotAll: true,
  );

  final paragraphRegex = RegExp(
    r'<PARAGRAPH[^>]*>(.*?)</PARAGRAPH>',
    caseSensitive: false,
    dotAll: true,
  );

  final articles =
      articleRegex.allMatches(
    document,
  );

  for (final article in articles) {
    final title =
        _cleanDrugDocumentText(
      article.group(1) ?? '',
    );

    final body =
        article.group(2) ?? '';

    // ==============================
    // 금기사항 여부 판단
    // ==============================
    final isContraindication =
        title.contains(
          '복용하지 말',
        ) ||
        title.contains(
          '투여하지 말',
        ) ||
        title.contains(
          '사용하지 말',
        ) ||
        title.contains(
          '금기',
        );

    if (contraindications !=
        isContraindication) {
      continue;
    }

    final paragraphs =
        paragraphRegex.allMatches(
      body,
    );

    // PARAGRAPH가 없는 경우
    if (paragraphs.isEmpty) {
      final cleaned =
          _cleanDrugDocumentText(
        body,
      );

      if (cleaned.isNotEmpty) {
        final item =
            title.isEmpty
                ? cleaned
                : '$title - $cleaned';

        if (!result.contains(item)) {
          result.add(item);
        }
      }

      continue;
    }

    // PARAGRAPH 단위로 저장
    for (final paragraph
        in paragraphs) {
      final cleaned =
          _cleanDrugDocumentText(
        paragraph.group(1) ?? '',
      );

      if (cleaned.isEmpty) {
        continue;
      }

      final item =
          title.isEmpty
              ? cleaned
              : '$title - $cleaned';

      if (!result.contains(item)) {
        result.add(item);
      }
    }
  }

  // 식약처 데이터 형식이 달라져 ARTICLE 파싱이
  // 실패한 경우에는 주의사항 전체라도 보여줌
  if (result.isEmpty &&
      !contraindications) {
    final fallback =
        _cleanDrugDocumentText(
      document,
    );

    if (fallback.isNotEmpty) {
      result.add(fallback);
    }
  }

  return result;
}

String _cleanWarningText(String text) {
  var result = text;

  // 혹시 백슬래시가 포함되어 넘어오는 경우
  result = result
      .replaceAll(r'\<', '<')
      .replaceAll(r'\>', '>');

  // CDATA 제거
  result = result
      .replaceAll('<![CDATA[', '')
      .replaceAll(']]>', '');

  // XML / HTML 태그 제거
  result = result.replaceAll(
    RegExp(r'<[^>]+>'),
    ' ',
  );

  // HTML entity
  result = result
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  // &#12316; 같은 숫자 코드
  result = result.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (match) {
      final code = int.tryParse(
        match.group(1) ?? '',
      );

      if (code == null) {
        return match.group(0) ?? '';
      }

      return String.fromCharCode(code);
    },
  );

  result = result.replaceAll(
    RegExp(r'\s+'),
    ' ',
  );

  return result.trim();
}

List<String> _extractWarningItems(
  String document, {
  required bool contraindication,
}) {
  if (document.trim().isEmpty) {
    return <String>[];
  }

  final result = <String>[];

  final articleRegex = RegExp(
    r'<ARTICLE[^>]*title="([^"]*)"[^>]*>([\s\S]*?)</ARTICLE>',
    caseSensitive: false,
  );

  final paragraphRegex = RegExp(
    r'<PARAGRAPH[^>]*>([\s\S]*?)</PARAGRAPH>',
    caseSensitive: false,
  );

  final articles =
      articleRegex.allMatches(document);

  for (final article in articles) {
    final title = _cleanWarningText(
      article.group(1) ?? '',
    );

    final body =
        article.group(2) ?? '';

    final isContraindication =
        title.contains('복용하지 말') ||
        title.contains('투여하지 말') ||
        title.contains('사용하지 말') ||
        title.contains('금기');

    // 금기사항 / 일반 주의사항 분리
    if (contraindication !=
        isContraindication) {
      continue;
    }

    final paragraphs =
        paragraphRegex.allMatches(body);

    for (final paragraph
        in paragraphs) {
      final text =
          _cleanWarningText(
        paragraph.group(1) ?? '',
      );

      if (text.isEmpty) {
        continue;
      }

      if (!result.contains(text)) {
        result.add(text);
      }
    }
  }

  // XML 구조가 다른 약의 fallback
  if (result.isEmpty &&
      !contraindication) {
    final cleaned =
        _cleanWarningText(document);

    if (cleaned.isNotEmpty) {
      result.add(cleaned);
    }
  }

  return result;
}

  Map<String, dynamic> _convertDrug(Map<String, dynamic> drug) {
    Map<String, dynamic> raw = {};

    if (drug['raw'] is Map) {
      raw = Map<String, dynamic>.from(drug['raw']);
    }

    final productName = (drug['itemName'] ?? raw['ITEM_NAME'] ?? '')
        .toString()
        .trim();

    final manufacturer = (drug['entpName'] ?? raw['ENTP_NAME'] ?? '')
        .toString()
        .trim();

    final ingredient = (drug['mainIngredient'] ?? raw['ITEM_INGR_NAME'] ?? '')
        .toString()
        .trim();

    final category = (drug['category'] ?? raw['SPCLTY_PBLC'] ?? '')
        .toString()
        .trim();

    final productType = (drug['productType'] ?? raw['PRDUCT_TYPE'] ?? '')
        .toString()
        .trim();

    final imageUrl =
    (drug['imageUrl'] ??
            raw['BIG_PRDT_IMG_URL'] ??
            '')
        .toString()
        .trim();

// ========================================
// 식약처 사용상의 주의사항
// ========================================

final warningDocument =
    (drug['warning'] ??
            drug['nbDocData'] ??
            raw['NB_DOC_DATA'] ??
            '')
        .toString()
        .trim();

final cautions =
    _extractDrugWarnings(
  warningDocument,
  contraindications: false,
);

final contraindications =
    _extractDrugWarnings(
  warningDocument,
  contraindications: true,
);

// 디버깅용
debugPrint(
  '[DRUG WARNING] $productName',
);

debugPrint(
  '[DRUG WARNING] '
  'NB_DOC_DATA 길이: '
  '${warningDocument.length}',
);

debugPrint(
  '[DRUG WARNING] '
  '주의사항: ${cautions.length}개',
);

debugPrint(
  '[DRUG WARNING] '
  '금기사항: '
  '${contraindications.length}개',
);

final purchaseType =
    category.contains('전문')
        ? 'prescription'
        : 'pharmacy';

    return {
      // 기존 화면에서 사용하던 key
      'productName': productName,

      'manufacturer': manufacturer.isEmpty ? '제조사 정보 없음' : manufacturer,

      'ingredient': ingredient.isEmpty ? '성분 정보 없음' : ingredient,

      'purchaseType': purchaseType,

      'effect': productType.isEmpty ? '상세정보 조회 필요' : productType,

      'dosage': '복용법은 제품 설명 또는 처방을 확인해주세요.',

      'cautions': cautions,

      'contraindications': contraindications,

      // 식약처 데이터도 유지
      'itemSeq': drug['itemSeq'] ?? raw['ITEM_SEQ'],

      'category': category,

      'productType': productType,

      'imageUrl': imageUrl,

      'itemEngName': drug['itemEngName'] ?? raw['ITEM_ENG_NAME'],

      'raw': raw,
    };
  }

  void _onCardTap(Map<String, dynamic> medicine) {
    // 일반 검색
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

      return;
    }

    final name = (medicine['productName'] ?? '').toString().trim();

    if (name.isEmpty) {
      return;
    }

    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });

    debugPrint(
      '현재 선택된 약: '
      '$_selected',
    );
  }

  void _onRegisterSelected() {
    if (_selected.isEmpty) {
      return;
    }

    final selectedNames = _selected.toList();

    debugPrint(
      '등록 버튼 클릭: '
      '$selectedNames',
    );

    Navigator.pop<List<String>>(context, selectedNames);
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
                  Padding(
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

                  Expanded(
                    child: Center(
                      child: Text(
                        '"${widget.query}" 검색 결과',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFF5F5F5),
                child: const Text(
                  '등록할 약을 선택하세요.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),

            const Divider(height: 1, color: Colors.black12),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _purchaseFilterButton(value: 'all', label: '전체'),

                  const SizedBox(width: 8),

                  _purchaseFilterButton(value: 'pharmacy', label: '약국 구매 가능'),

                  const SizedBox(width: 8),

                  _purchaseFilterButton(value: 'prescription', label: '처방전 필요'),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── 결과 목록 ──────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.black38,
                            ),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _searchMedicines,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _results.isEmpty
                  ? const Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.black45),
                      ),
                    )
                  : _filteredResults.isEmpty
                  ? const Center(
                      child: Text(
                        '해당 조건의 약이 없습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.black45),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: _filteredResults.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final medicine = _filteredResults[index];
                        final productName = medicine['productName'] as String;
                        final purchase = _purchaseInfo(
                          medicine['purchaseType'] as String,
                        );
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
                                        (medicine['imageUrl'] ?? '')
                                            .toString()
                                            .trim();

                                    // ✅ 이미지 URL 확인
                                    debugPrint(
                                      '[DRUG IMAGE] ${medicine['productName']}',
                                    );

                                    debugPrint('[DRUG IMAGE URL] $imageUrl');

                                    // 이미지 주소 자체가 없는 경우
                                    if (imageUrl.isEmpty) {
                                      debugPrint('[DRUG IMAGE] 이미지 URL 없음');

                                      return Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F2F2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.medication_outlined,
                                          size: 30,
                                          color: Colors.black38,
                                        ),
                                      );
                                    }

                                    final proxyUrl =
                                        ApiService.drugImageProxyUrl(imageUrl);

                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        proxyUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.contain,

                                        // ✅ 이미지 로딩 실패 원인 출력
                                        errorBuilder: (context, error, stackTrace) {
                                          debugPrint(
                                            '[DRUG IMAGE ERROR] $error',
                                          );

                                          debugPrint(
                                            '[DRUG IMAGE FAILED URL] $imageUrl',
                                          );

                                          return Container(
                                            width: 64,
                                            height: 64,
                                            color: const Color(0xFFF2F2F2),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        medicine['manufacturer'] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            purchase.icon,
                                            size: 14,
                                            color: purchase.color,
                                          ),
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
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.black26,
                                    size: 22,
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.black38,
                                  ),
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
                    onPressed: _selected.isNotEmpty
                        ? _onRegisterSelected
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: Colors.black38,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _selected.isEmpty ? '약을 선택해주세요' : '등록하기',
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
