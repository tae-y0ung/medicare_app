import 'package:flutter/material.dart';
import 'user_profile.dart';
import 'ocr_edit_page.dart';
import '../services/api_service.dart';

class MedicineDetailPage extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final UserProfile? profile;

  const MedicineDetailPage({
    super.key,
    required this.medicine,
    this.profile,
  });

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  Map<String, dynamic> get medicine => widget.medicine;
  UserProfile? get profile => widget.profile;

  bool _isFavorite = false;
  bool _favoriteLoading = true;
  bool _favoriteUpdating = false;
  bool _favoriteLoadSucceeded = false;
  String? _favoriteId;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return <String>[];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _loadFavorite() async {
    final userId = widget.profile?.userId.trim() ?? '';
    final itemSeq =
        (widget.medicine['itemSeq'] ?? '').toString().trim();

    if (userId.isEmpty || itemSeq.isEmpty) {
      if (!mounted) return;

      setState(() {
        _favoriteLoading = false;
        _favoriteLoadSucceeded = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _favoriteLoading = true;
        _favoriteLoadSucceeded = false;
      });
    }

    try {
      final result = await ApiService.getMedicineReuseOptions(userId);
      final options = result['options'];

      Map<String, dynamic>? favorite;

      if (options is List) {
        for (final raw in options) {
          if (raw is! Map) continue;

          final item = Map<String, dynamic>.from(raw);
          final seq = (item['itemSeq'] ?? '').toString().trim();

          if (item['sourceType'] == 'favorite' && seq == itemSeq) {
            favorite = item;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _isFavorite = favorite != null;
        _favoriteId = favorite?['sourceId']?.toString();
        _favoriteLoading = false;
        _favoriteLoadSucceeded = true;
      });
    } catch (e) {
      debugPrint('즐겨찾기 조회 오류: $e');

      if (!mounted) return;

      setState(() {
        _favoriteLoading = false;
        _favoriteLoadSucceeded = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기를 불러오지 못했습니다: $e')),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteUpdating ||
        _favoriteLoading ||
        !_favoriteLoadSucceeded) {
      return;
    }

    final userId = widget.profile?.userId.trim() ?? '';
    final itemSeq =
        (widget.medicine['itemSeq'] ?? '').toString().trim();
    final medicineName = (widget.medicine['productName'] ??
            widget.medicine['medicineName'] ??
            '')
        .toString()
        .trim();

    if (userId.isEmpty || itemSeq.isEmpty) return;

    final wasFavorite = _isFavorite;

    setState(() {
      _favoriteUpdating = true;
    });

    try {
      if (wasFavorite) {
        final favoriteId = _favoriteId?.trim() ?? '';

        if (favoriteId.isEmpty) {
          throw Exception('삭제할 즐겨찾기 ID가 없습니다.');
        }

        await ApiService.deleteMedicineFavorite(
          favoriteId,
          userId,
        );
      } else {
        await ApiService.addMedicineFavorite(
          userId: userId,
          itemSeq: itemSeq,
          medicineName: medicineName,
          category: 'stock',
        );
      }

      await _loadFavorite();

      if (!mounted) return;

      if (!_favoriteLoadSucceeded) {
        throw Exception('변경 후 즐겨찾기 상태 확인 실패');
      }

      if (_isFavorite == wasFavorite) {
        throw Exception('서버의 즐겨찾기 상태가 변경되지 않았습니다.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? '즐겨찾기가 해제되었습니다.'
                : '즐겨찾기에 등록되었습니다.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('즐겨찾기 변경 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 변경 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoriteUpdating = false;
        });
      }
    }
  }

  static ({String label, Color color, IconData icon}) _purchaseInfo(
    String type,
  ) {
    switch (type) {
      case 'convenience':
        return (
          label: '안전상비의약품 · 편의점 구매 가능',
          color: const Color(0xFF1565C0),
          icon: Icons.store_outlined,
        );

      case 'prescription':
        return (
          label: '전문의약품 · 처방전 필요',
          color: const Color(0xFFC62828),
          icon: Icons.local_hospital_outlined,
        );

      default:
        return (
          label: '일반의약품 · 약국 구매 가능',
          color: const Color(0xFF2E7D32),
          icon: Icons.local_pharmacy_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName =
        (medicine['productName'] ?? '약 이름').toString();
    final manufacturer =
        (medicine['manufacturer'] ?? '').toString();

    // 화면에서는 성분을 숨기지만 약 등록 데이터에는 유지합니다.
    final ingredient = (medicine['ingredient'] ?? '').toString();
    final effect = (medicine['effect'] ?? '').toString();
    final dosage = (medicine['dosage'] ?? '').toString();
    final dosageSummary = _stringList(medicine['dosageSummary']);

    final purchaseType =
        (medicine['purchaseType'] ?? 'pharmacy').toString();
    final purchase = _purchaseInfo(purchaseType);

    final cautions = _stringList(medicine['cautions']);
    final contraindications =
        _stringList(medicine['contraindications']);
    final precautionSummary =
        _stringList(medicine['precautionSummary']);
    final precautionDetails = _mapList(medicine['precautionDetails']);

    final precautions =
        (medicine['precautions'] ?? '').toString().trim();
    final warning = (medicine['warning'] ?? '').toString().trim();
    final caution = (medicine['caution'] ?? '').toString().trim();
    final interactionInfo =
        (medicine['interactionInfo'] ?? '').toString().trim();
    final sideEffect =
        (medicine['sideEffect'] ?? '').toString().trim();

    final hasFullPrecautions = precautionDetails.isNotEmpty ||
        precautions.isNotEmpty ||
        warning.isNotEmpty ||
        caution.isNotEmpty ||
        interactionInfo.isNotEmpty ||
        sideEffect.isNotEmpty ||
        cautions.isNotEmpty;

    final interactionCheckRaw = medicine['interactionCheck'];
    final interactionCheck = interactionCheckRaw is Map
        ? Map<String, dynamic>.from(interactionCheckRaw)
        : <String, dynamic>{};

    final interactionCheckError =
        (medicine['interactionCheckError'] ?? '').toString().trim();

    final allergyCheckRaw = medicine['allergyCheck'];
    final allergyCheck = allergyCheckRaw is Map
        ? Map<String, dynamic>.from(allergyCheckRaw)
        : <String, dynamic>{};

    final allergyCheckError =
        (medicine['allergyCheckError'] ?? '').toString().trim();

    final itemSeq = (medicine['itemSeq'] ?? '').toString().trim();
    final category = (medicine['category'] ?? '').toString().trim();
    final productType =
        (medicine['productType'] ?? '').toString().trim();
    final imageUrl = (medicine['imageUrl'] ?? '').toString().trim();

    final medicineType =
        purchaseType == 'prescription' ? 'prescription' : 'otc';

    final medicineTypeLabel = purchaseType == 'prescription'
        ? '전문의약품'
        : purchaseType == 'convenience'
            ? '안전상비의약품'
            : '일반의약품';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 즐겨찾기 + 닫기
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: _isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                    onPressed: _favoriteLoading ||
                            !_favoriteLoadSucceeded ||
                            _favoriteUpdating
                        ? null
                        : _toggleFavorite,
                    icon: _favoriteLoading || _favoriteUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 32,
                            color: _isFavorite
                                ? const Color(0xFFD6A12A)
                                : Colors.black,
                          ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

                            // ── 실제 약 이미지 ─────────────────
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 160,
                    height: 160,
                    color: const Color(0xFFEFEFEF),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            ApiService.drugImageProxyUrl(imageUrl),
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              debugPrint(
                                '[DETAIL IMAGE ERROR] $error',
                              );

                              return const Icon(
                                Icons.medication_outlined,
                                size: 64,
                                color: Colors.black38,
                              );
                            },
                          )
                        : const Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: Colors.black38,
                          ),
                  ),
                ),
              ),


              const SizedBox(height: 16),

              Center(
                child: Text(
                  productName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (manufacturer.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    manufacturer,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // 구매처 뱃지
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: purchase.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: purchase.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        purchase.icon,
                        size: 16,
                        color: purchase.color,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          purchase.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: purchase.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 1. 효능·효과
              if (effect.isNotEmpty) ...[
                _infoSection(
                  icon: Icons.healing_outlined,
                  title: '효능·효과',
                  content: effect,
                ),
                const SizedBox(height: 16),
              ],

              // 2. 알레르기 주의
              if (allergyCheckError.isNotEmpty) ...[
                _resultExpandableSection(
                  storageKey: 'allergy_result_$itemSeq',
                  title: '알레르기 주의',
                  result: '확인하지 못했습니다. 위험이 없다는 뜻은 아닙니다.',
                  icon: Icons.error_outline,
                  color: Colors.orange,
                  child: const Text(
                    '알레르기 정보를 확인하지 못했습니다.\n'
                    '이 표시는 알레르기 위험이 없다는 의미가 아닙니다. '
                    '복용 전 의사 또는 약사와 상담하세요.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (allergyCheck.isNotEmpty) ...[
                _allergyResultSection(
                  allergyCheck,
                  storageKey: 'allergy_result_$itemSeq',
                ),
                const SizedBox(height: 16),
              ],

              // 3. 복약 안전 확인
              if (interactionCheckError.isNotEmpty) ...[
                _resultExpandableSection(
                  storageKey: 'interaction_result_$itemSeq',
                  title: '복약 안전 확인',
                  result: '확인하지 못했습니다. 안전함을 의미하지 않습니다.',
                  icon: Icons.error_outline,
                  color: Colors.orange,
                  child: const Text(
                    '병용금기 정보를 확인하지 못했습니다.\n'
                    '이 표시는 안전함을 의미하지 않습니다. '
                    '함께 복용하기 전 의사 또는 약사와 상담하세요.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (interactionCheck.isNotEmpty) ...[
                _interactionResultSection(
                  interactionCheck,
                  storageKey: 'interaction_result_$itemSeq',
                ),
                const SizedBox(height: 16),
              ],

              // 4. 용법·용량: 제목 유지
              if (dosageSummary.isNotEmpty) ...[
                _dosageSection(summaryItems: dosageSummary),
                const SizedBox(height: 16),
              ],

              // 5. 핵심 주의사항
              if (precautionSummary.isNotEmpty) ...[
                _precautionSummarySection(
                  summaryItems: precautionSummary,
                  precautionDetails: precautionDetails,
                  precautions: precautions,
                  warning: warning,
                  caution: caution,
                  interactionInfo: interactionInfo,
                  sideEffect: sideEffect,
                  cautions: cautions,
                  hasFullPrecautions: hasFullPrecautions,
                ),
                const SizedBox(height: 16),
              ],

              // 6. 금기사항
              if (contraindications.isNotEmpty)
                _contraindicationSection(items: contraindications),

              const SizedBox(height: 32),

              // 약 등록 + 닫기
              Row(
                children: [
                  if (profile != null)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OcrEditPage(
                                  ocrMedicines: [
                                    <String, dynamic>{
                                      'medicineName': productName,
                                      'isStock': false,
                                      'asNeeded': false,
                                      'itemSeq': itemSeq,

                                      // 포장 정보는 등록 데이터에 유지
                                      'packageUnit':
                                          medicine['packageUnit'] ?? '',
                                      'packageOptions':
                                          medicine['packageOptions'] ??
                                              const [],
                                      'packageCount':
                                          medicine['packageCount'],
                                      'packageCountUnit':
                                          medicine['packageCountUnit'] ??
                                              '',

                                      'manufacturer': manufacturer,
                                      'ingredient': ingredient,
                                      'purchaseType': purchaseType,
                                      'medicineType': medicineType,
                                      'medicineTypeLabel':
                                          medicineTypeLabel,
                                      'effect': effect,

                                      // 문자열 용법은 usage로 전달
                                      'usage': dosage,

                                      'cautions': cautions,
                                      'contraindications':
                                          contraindications,
                                      'category': category,
                                      'productType': productType,
                                      'imageUrl': imageUrl,
                                    },
                                  ],
                                  userProfile: profile!,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '+ 약 등록',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  if (profile != null) const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '닫기',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── 결과 요약 + 접기/펼치기 공통 위젯 ──────────
  // 정상 결과는 제목 한 줄, 주의·오류 결과는 펼치기 가능
Widget _resultExpandableSection({
  required String storageKey,
  required String title,
  required String result,
  required IconData icon,
  required Color color,
  required Widget child,
  bool expandable = true,
}) {
  final titleRow = Row(
    children: [
      Icon(icon, size: 21, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    ],
  );

  return Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color.withValues(alpha: 0.45),
      ),
    ),

    // 주의사항이 없으면 화살표·상세 내용 없이 한 줄만 표시
    child: !expandable
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: titleRow,
          )
        : ExpansionTile(
            key: PageStorageKey<String>(storageKey),
            initiallyExpanded: false,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            iconColor: color,
            collapsedIconColor: color,
            title: titleRow,
            subtitle: result.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      result,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
            children: [
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: child,
              ),
            ],
          ),
  );
}


  // ── 알레르기 요약 및 상세 ────────────────────
  Widget _allergyResultSection(
  Map<String, dynamic> check, {
  required String storageKey,
}) {
  final message = (check['message'] ?? '').toString().trim();
  final matches = _mapList(check['matchedAllergies']);

  final hasWarning =
      check['hasWarning'] == true || matches.isNotEmpty;

  // 확인 실패나 불명확한 응답은 정상으로 처리하지 않음
  final hasCheckProblem = check['success'] == false ||
      (check['hasWarning'] is! bool && matches.isEmpty);

  final Color color;
  final IconData icon;
  final String title;
  final String result;

  if (hasWarning) {
    color = Colors.redAccent;
    icon = Icons.warning_amber_rounded;
    title = '알레르기 주의';
    result = hasCheckProblem
        ? '알레르기 주의사항이 있으며, 일부 정보를 확인하지 못했습니다.'
        : '등록된 알레르기와 일치하는 성분이 있습니다. 복용 전 상담하세요.';
  } else if (hasCheckProblem) {
    color = Colors.orange;
    icon = Icons.error_outline;
    title = '알레르기 확인 필요';
    result = '확인하지 못했습니다. 위험이 없다는 뜻은 아닙니다.';
  } else {
    color = Colors.green;
    icon = Icons.verified_outlined;
    title = '알레르기 확인';
    result = '';
  }

  return _resultExpandableSection(
    storageKey: storageKey,
    title: title,
    result: result,
    icon: icon,
    color: color,
    expandable: hasWarning || hasCheckProblem,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.isNotEmpty) ...[
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
        ],

        ...matches.map((match) {
          final allergy =
              (match['allergy'] ?? '').toString().trim();
          final ingredient =
              (match['ingredient'] ?? '').toString().trim();

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allergy.isNotEmpty)
                  Text(
                    '등록 알레르기: $allergy',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                if (ingredient.isNotEmpty) ...[
                  if (allergy.isNotEmpty)
                    const SizedBox(height: 4),
                  Text(
                    '약 성분: $ingredient',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        const Text(
          '등록된 알레르기와 제공된 성분 정보를 기준으로 한 결과입니다. '
          '복용 전 의사 또는 약사와 상담하세요.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Colors.black54,
          ),
        ),
      ],
    ),
  );
}


  // ── 병용·중복 복약 안전 확인 ──────────────────
  Widget _interactionResultSection(
    Map<String, dynamic> check, {
    required String storageKey,
  }) {
    final durWarnings =
        _extractInteractionMessages(check['durWarnings']);

    final duplicateMedicineWarnings =
        _extractInteractionMessages(
      check['duplicateMedicineWarnings'],
    );

    final duplicateIngredientWarnings =
        _extractInteractionMessages(
      check['duplicateIngredientWarnings'],
    );

    var generalWarnings =
        _extractInteractionMessages(check['warnings']);

    final duplicateWarningsFromGeneral =
        generalWarnings.where((message) {
      return message.contains('동일 성분') ||
          message.contains('중복 성분');
    }).toList();

    final allDuplicateIngredientWarnings = <String>{
      ...duplicateIngredientWarnings,
      ...duplicateWarningsFromGeneral,
    }.toList();

    final alreadyShown = <String>{
      ...durWarnings,
      ...duplicateMedicineWarnings,
      ...allDuplicateIngredientWarnings,
    };

    generalWarnings = generalWarnings
        .where((message) => !alreadyShown.contains(message))
        .toList();

    final durErrors =
        _extractInteractionMessages(check['durErrors']);
    final skippedMedications =
        _extractInteractionMessages(check['skippedMedications']);

    final hasWarning = durWarnings.isNotEmpty ||
        duplicateMedicineWarnings.isNotEmpty ||
        allDuplicateIngredientWarnings.isNotEmpty ||
        generalWarnings.isNotEmpty;

    // 비어 있지 않은 오류 목록은 메시지 추출 실패 시에도 감지
    final hasCheckProblem = check['success'] == false ||
        (check['durErrors'] is List &&
            (check['durErrors'] as List).isNotEmpty) ||
        (check['skippedMedications'] is List &&
            (check['skippedMedications'] as List).isNotEmpty);

    final checkedMedicationCount =
        int.tryParse((check['checkedMedicationCount'] ?? '').toString());

    final backendMessage =
        (check['message'] ?? '').toString().trim();

    final Color color;
final IconData icon;
final String title;
final String result;

if (hasWarning) {
  color = Colors.redAccent;
  icon = Icons.warning_amber_rounded;
  title = '복약 안전 주의';
  result = hasCheckProblem
      ? '복약 주의사항이 있으며, 일부 약은 확인하지 못했습니다.'
      : '함께 복용할 때 주의가 필요한 항목이 있습니다.';
} else if (hasCheckProblem) {
  color = Colors.orange;
  icon = Icons.info_outline;
  title = '복약 안전 확인 필요';
  result = '일부 정보를 확인하지 못했습니다. 안전함을 의미하지 않습니다.';
} else {
  color = Colors.green;
  icon = Icons.verified_outlined;
  title = '복약 안전 확인';
  result = '';
}

return _resultExpandableSection(
  storageKey: storageKey,
  title: title,
  result: result,
  icon: icon,
  color: color,
  expandable: hasWarning || hasCheckProblem,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checkedMedicationCount != null &&
              checkedMedicationCount > 0) ...[
            Text(
              '현재 복용약 $checkedMedicationCount개와 비교했습니다.',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (backendMessage.isNotEmpty) ...[
            Text(
              backendMessage,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (durWarnings.isNotEmpty)
            _interactionWarningGroup(
              title: '병용금기',
              items: durWarnings,
              color: Colors.redAccent,
            ),

          if (duplicateMedicineWarnings.isNotEmpty)
            _interactionWarningGroup(
              title: '중복 약 주의',
              items: duplicateMedicineWarnings,
              color: Colors.deepOrange,
            ),

          if (allDuplicateIngredientWarnings.isNotEmpty)
            _interactionWarningGroup(
              title: '중복 성분 주의',
              items: allDuplicateIngredientWarnings,
              color: Colors.deepOrange,
            ),

          if (generalWarnings.isNotEmpty)
            _interactionWarningGroup(
              title: '기타 복약 주의',
              items: generalWarnings,
              color: Colors.orange,
            ),

          // 경고와 검사 실패가 동시에 있어도 모두 표시
          if (hasCheckProblem) ...[
            const Text(
              '일부 복약 안전 정보를 확인하지 못했습니다. '
              '확인되지 않은 항목은 의사 또는 약사와 상담하세요.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (durErrors.isNotEmpty)
              _interactionWarningGroup(
                title: '확인 중 오류',
                items: durErrors,
                color: Colors.orange,
              ),
            if (skippedMedications.isNotEmpty)
              _interactionWarningGroup(
                title: '확인하지 못한 복용약',
                items: skippedMedications,
                color: Colors.orange,
              ),
          ],

          const Text(
            '등록된 복용약과 제공된 정보를 기준으로 한 결과입니다. '
            '경고가 표시되지 않아도 모든 병용 위험이 없음을 보장하지 않습니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractInteractionMessages(dynamic value) {
    if (value is! List) return <String>[];

    final result = <String>[];

    for (final item in value) {
      String text = '';

      if (item is String) {
        text = item.trim();
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item);

        text = (map['message'] ?? '').toString().trim();

        if (text.isEmpty) {
          final medicineName = (map['medicineName'] ??
                  map['currentMedicineName'] ??
                  map['itemName'] ??
                  '')
              .toString()
              .trim();

          final ingredient =
              (map['ingredient'] ?? '').toString().trim();

          final reason =
              (map['reason'] ?? map['error'] ?? '').toString().trim();

          text = <String>[
            if (medicineName.isNotEmpty) medicineName,
            if (ingredient.isNotEmpty) ingredient,
            if (reason.isNotEmpty) reason,
          ].join(' · ');
        }
      }

      if (text.isNotEmpty && !result.contains(text)) {
        result.add(text);
      }
    }

    return result;
  }

  Widget _interactionWarningGroup({
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 7),
          ...items.map(
            (item) => _bulletItem(
              item,
              fontSize: 13,
              bulletColor: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── 효능·효과 등 일반 정보 ───────────────────
  Widget _infoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── 용법·용량: 기존 제목 유지 ────────────────
  Widget _dosageSection({
    required List<String> summaryItems,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, size: 20, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                '용법·용량',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...summaryItems.map((item) => _bulletItem(item)),
        ],
      ),
    );
  }

  // ── 핵심 주의사항 ─────────────────────────
  Widget _precautionSummarySection({
    required List<String> summaryItems,
    required List<Map<String, dynamic>> precautionDetails,
    required String precautions,
    required String warning,
    required String caution,
    required String interactionInfo,
    required String sideEffect,
    required List<String> cautions,
    required bool hasFullPrecautions,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(10),
        color: Colors.orange.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  '핵심 주의사항',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: summaryItems
                  .map((item) => _bulletItem(item))
                  .toList(),
            ),
          ),
          if (hasFullPrecautions) ...[
            const Divider(height: 1),
            ExpansionTile(
              initiallyExpanded: false,
              shape: const Border(),
              collapsedShape: const Border(),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: const Text(
                '전체 주의사항 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                if (precautionDetails.isNotEmpty)
                  ...precautionDetails.map((section) {
                    final title =
                        (section['title'] ?? '').toString().trim();
                    final items = _stringList(section['items']);

                    if (items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return _precautionDetailSection(
                      title: title,
                      items: items,
                    );
                  }),

                // 상세 목록이 없으면 기존 텍스트 사용
                if (precautionDetails.isEmpty) ...[
                  if (precautions.isNotEmpty)
                    _fullPrecautionItem(
                      title: '전체 주의사항',
                      content: precautions,
                    ),
                  if (warning.isNotEmpty)
                    _fullPrecautionItem(
                      title: '중요 경고',
                      content: warning,
                    ),
                  if (caution.isNotEmpty)
                    _fullPrecautionItem(
                      title: '복용 시 주의',
                      content: caution,
                    ),
                  if (interactionInfo.isNotEmpty)
                    _fullPrecautionItem(
                      title: '함께 복용 시 주의',
                      content: interactionInfo,
                    ),
                  if (cautions.isNotEmpty)
                    _fullPrecautionItem(
                      title: '기타 주의사항',
                      content: cautions.join('\n\n'),
                    ),
                  if (sideEffect.isNotEmpty)
                    _fullPrecautionItem(
                      title: '이상반응',
                      content: sideEffect,
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── 금기사항 ─────────────────────────────
  Widget _contraindicationSection({
    required List<String> items,
  }) {
    final previewItems = items.take(4).toList();
    final hasMore = items.length > 4;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.dangerous_outlined,
                  size: 21,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '금기사항 (이런 경우 복용하지 마세요)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: previewItems
                  .map((item) => _bulletItem(item))
                  .toList(),
            ),
          ),
          if (hasMore) ...[
            const Divider(height: 1),
            ExpansionTile(
              initiallyExpanded: false,
              shape: const Border(),
              collapsedShape: const Border(),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text(
                '전체 금기사항 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: items
                  .skip(4)
                  .map((item) => _bulletItem(item))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _precautionDetailSection({
    required String title,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...items.map(
            (item) => _bulletItem(item, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _fullPrecautionItem({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 공통 글머리표
  Widget _bulletItem(
    String text, {
    double fontSize = 14,
    Color bulletColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: fontSize,
              height: 1.5,
              color: bulletColor,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
