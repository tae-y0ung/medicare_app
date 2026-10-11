import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'medicine_detail_page.dart';
import 'user_profile.dart';

class MedicineSearchInfoPage extends StatefulWidget {
  final String symptomLabel;
  final UserProfile? profile;

  const MedicineSearchInfoPage({
    super.key,
    required this.symptomLabel,
    this.profile,
  });

  @override
  State<MedicineSearchInfoPage> createState() => _MedicineSearchInfoPageState();
}

class _MedicineSearchInfoPageState extends State<MedicineSearchInfoPage> {
  bool _isLoading = true;

  String _errorMessage = '';

  String _notice = '';

  int _excludedCount = 0;

  List<Map<String, dynamic>> _medicines = [];

  String? _openingItemSeq;

  @override
  void initState() {
    super.initState();

    _loadRecommendations();
  }

  // ========================================
  // 기존 UI 카테고리
  // → 백엔드 검색용 증상 변환
  // ========================================

  String get _backendSymptom {
    switch (widget.symptomLabel) {
      case '감기 / 열':
        return '감기';

      case '통증':
        return '두통';

      case '소화 / 위장':
        return '소화불량';

      case '알레르기':
        return '알레르기';

      case '수면 / 피로':
        return '피로';

      case '피부':
        return '피부';

      case '응급 증상':
        return '응급 증상';

      default:
        return widget.symptomLabel;
    }
  }

  // ========================================
  // 증상별 추천 조회
  // ========================================

  Future<void> _loadRecommendations() async {
    final profile = widget.profile;

    if (profile == null || profile.userId.trim().isEmpty) {
      setState(() {
        _isLoading = false;

        _errorMessage = '사용자 정보를 확인할 수 없습니다.';
      });

      return;
    }

    setState(() {
      _isLoading = true;

      _errorMessage = '';
    });

    try {
      final result = await ApiService.recommendBySymptom(
        userId: profile.userId,

        symptom: _backendSymptom,
      );

      final rawRecommendations = result['recommendations'];

      final medicines = rawRecommendations is List
          ? rawRecommendations
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _medicines = medicines;

        _excludedCount = (result['excludedCount'] as num?)?.toInt() ?? 0;

        _notice = (result['notice'] ?? '').toString().trim();

        _isLoading = false;
      });

      debugPrint(
        '증상 추천 결과: '
        '$medicines',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;

        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ========================================
  // 추천 약 클릭
  // ========================================

  Future<void> _openMedicine(Map<String, dynamic> recommendation) async {
    final profile = widget.profile;

    if (profile == null) {
      return;
    }

    final itemSeq = (recommendation['itemSeq'] ?? '').toString().trim();

    if (itemSeq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '의약품 품목번호를 '
            '확인할 수 없습니다.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _openingItemSeq = itemSeq;
    });

    try {
      // ====================================
      // 1. 상세정보
      // ====================================

      Map<String, dynamic> detailDrug = {};

      try {
        final detailResult = await ApiService.getDrugDetail(itemSeq);

        final rawDrug = detailResult['drug'];

        if (rawDrug is Map) {
          detailDrug = Map<String, dynamic>.from(rawDrug);
        }
      } catch (e) {
        debugPrint('추천 약 상세조회 실패: $e');
      }

      // ====================================
      // 2. 알레르기
      //
      // 증상 추천 API에서 이미
      // allergyCheck를 해준 결과가 있으므로
      // 그것을 우선 사용
      // ====================================

      Map<String, dynamic> allergyCheck = {};

      final rawAllergy = recommendation['allergyCheck'];

      if (rawAllergy is Map) {
        allergyCheck = Map<String, dynamic>.from(rawAllergy);
      }

      // ====================================
      // 3. 현재 복용약 병용금기
      //
      // 추천 목록 전체가 아니라
      // 사용자가 누른 약만 검사
      // ====================================

      Map<String, dynamic> interactionCheck = {};

      String interactionCheckError = '';

      try {
        interactionCheck = await ApiService.checkInteractions(
          userId: profile.userId,

          itemSeq: itemSeq,
        );
      } catch (e) {
        interactionCheckError = e.toString();

        debugPrint(
          '추천 약 병용금기 검사 실패: '
          '$e',
        );
      }

      // ====================================
      // 4. MedicineDetailPage 형식으로 변환
      // ====================================

      final medicine = <String, dynamic>{
        'productName':
            detailDrug['itemName'] ?? recommendation['medicineName'] ?? '',

        'manufacturer':
            detailDrug['entpName'] ?? recommendation['manufacturer'] ?? '',

        'ingredient':
            detailDrug['mainIngredient'] ?? recommendation['ingredient'] ?? '',

        'purchaseType':
            recommendation['purchaseType'] ??
            detailDrug['purchaseType'] ??
            'pharmacy',

        'effect': recommendation['efficacy'] ?? '',

        'dosage': recommendation['useMethod'] ?? '',

        'itemSeq': itemSeq,

        'imageUrl': detailDrug['imageUrl'] ?? recommendation['imageUrl'] ?? '',

        // 백엔드 정리된 상세 정보
        'dosageSummary': detailDrug['dosageSummary'] ?? const <String>[],

        'precautionSummary':
            detailDrug['precautionSummary'] ??
            recommendation['precautionSummary'] ??
            const <String>[],

        'precautionDetails': detailDrug['precautionDetails'] ?? const [],

        'contraindications': detailDrug['contraindications'] ?? const [],

        'precautions': detailDrug['precautions'] ?? '',

        // 증상 추천 API에서 받은 정보
        'warning': recommendation['warning'] ?? '',

        'caution': recommendation['caution'] ?? '',

        'interactionInfo': recommendation['interactionInfo'] ?? '',

        'sideEffect': recommendation['sideEffect'] ?? '',

        'matchedKeywords': recommendation['matchedKeywords'] ?? const [],

        // 안전 검사 결과
        'allergyCheck': allergyCheck,

        'allergyCheckError': '',

        'interactionCheck': interactionCheck,

        'interactionCheckError': interactionCheckError,
      };

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MedicineDetailPage(medicine: medicine, profile: profile),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingItemSeq = null;
        });
      }
    }
  }

  // ========================================
  // 구매 구분
  // ========================================

  static ({String label, Color color, Color bgColor, IconData icon})
  _purchaseInfo(String type) {
    switch (type) {
      case 'convenience':
        return (
          label: '편의점 구매 가능',

          color: const Color(0xFF1565C0),

          bgColor: const Color(0xFFE3F2FD),

          icon: Icons.store_outlined,
        );

      case 'prescription':
        return (
          label: '처방전 필요 (전문의약품)',

          color: const Color(0xFFC62828),

          bgColor: const Color(0xFFFFEBEE),

          icon: Icons.local_hospital_outlined,
        );

      default:
        return (
          label: '약국 구매 가능 (일반의약품)',

          color: const Color(0xFF2E7D32),

          bgColor: const Color(0xFFE8F5E9),

          icon: Icons.local_pharmacy_outlined,
        );
    }
  }

  // ========================================
  // 약 카드
  // ========================================

  Widget _medicineCard(Map<String, dynamic> medicine) {
    final purchase = _purchaseInfo(
      (medicine['purchaseType'] ?? 'pharmacy').toString(),
    );

    final itemSeq = (medicine['itemSeq'] ?? '').toString();

    final medicineName = (medicine['medicineName'] ?? '').toString();

    final manufacturer = (medicine['manufacturer'] ?? '').toString();

    final efficacy = (medicine['efficacy'] ?? '').toString().trim();

    final imageUrl = (medicine['imageUrl'] ?? '').toString().trim();

    final isOpening = _openingItemSeq == itemSeq;

    return GestureDetector(
      onTap: isOpening ? null : () => _openMedicine(medicine),

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          border: Border.all(color: Colors.black26),

          borderRadius: BorderRadius.circular(8),
        ),

        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // =========================
                // 약 이미지
                // =========================
                Container(
                  width: 56,
                  height: 56,

                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),

                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: imageUrl.isEmpty
                      ? const Icon(
                          Icons.medication_outlined,
                          size: 30,
                          color: Colors.black38,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),

                          child: Image.network(
                            ApiService.drugImageProxyUrl(imageUrl),

                            fit: BoxFit.contain,

                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.medication_outlined,
                                size: 30,
                                color: Colors.black38,
                              );
                            },
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                // =========================
                // 약 정보
                // =========================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (manufacturer.isNotEmpty) ...[
                        const SizedBox(height: 4),

                        Text(
                          manufacturer,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(purchase.icon, size: 14, color: purchase.color),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              purchase.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: purchase.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isOpening)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),

            // =========================
            // 효능 간단 표시
            // =========================
            if (efficacy.isNotEmpty) ...[
              const SizedBox(height: 12),

              const Divider(height: 1, color: Colors.black12),

              const SizedBox(height: 10),

              Text(
                efficacy,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================
  // 화면
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ────────────────────────
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
                        'assets/images/'
                        'medicare_logo.png',

                        width: 80,
                        height: 80,

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        widget.symptomLabel,

                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),

                        textAlign: TextAlign.center,
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

            const Divider(height: 1, color: Colors.black12),

            // ── 안내 배너 ────────────────────
            Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              color: const Color(0xFFF5F5F5),

              child: const Text(
                '식약처 효능·효과 정보를 '
                '기준으로 관련 의약품 후보를 '
                '보여드립니다. '
                '약을 탭하면 상세 안전정보를 '
                '확인할 수 있습니다.',

                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),

            const Divider(height: 1, color: Colors.black12),

            // ── 약 목록 ──────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          CircularProgressIndicator(),

                          SizedBox(height: 12),

                          Text(
                            '증상에 맞는 약을 '
                            '찾고 있습니다.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  // =========================
                  // 에러
                  // =========================
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),

                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 36,
                              color: Colors.orange,
                            ),

                            const SizedBox(height: 10),

                            Text(
                              _errorMessage,

                              textAlign: TextAlign.center,

                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 14),

                            OutlinedButton(
                              onPressed: _loadRecommendations,

                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    )
                  // =========================
                  // 결과 없음
                  // =========================
                  : _medicines.isEmpty
                  ? const Center(
                      child: Text(
                        '추천 약 정보가 '
                        '없습니다.',

                        style: TextStyle(fontSize: 16, color: Colors.black45),
                      ),
                    )
                  // =========================
                  // 정상 결과
                  // =========================
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),

                      children: [
                        if (_excludedCount > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),

                            padding: const EdgeInsets.all(10),

                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3F3),

                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Text(
                              '사용자의 알레르기 '
                              '정보 등을 기준으로 '
                              '$_excludedCount개의 '
                              '후보가 제외되었습니다.',

                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                                height: 1.4,
                              ),
                            ),
                          ),

                        ..._medicines.map(
                          (medicine) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),

                            child: _medicineCard(medicine),
                          ),
                        ),

                        if (_notice.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),

                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),

                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Text(
                              _notice,

                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
