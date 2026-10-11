import 'package:flutter/material.dart';
import 'user_profile.dart';
import 'ocr_edit_page.dart';

class MedicineDetailPage extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final UserProfile? profile;

  const MedicineDetailPage({super.key, required this.medicine, this.profile});

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
    final productName = medicine['productName'] as String? ?? '약 이름';
    final manufacturer = medicine['manufacturer'] as String? ?? '';
    final ingredient = medicine['ingredient'] as String? ?? '';
    final effect = medicine['effect'] as String? ?? '';
    final dosage = medicine['dosage'] as String? ?? '';
    final dosageSummary =
        (medicine['dosageSummary'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final purchaseType = medicine['purchaseType'] as String? ?? 'pharmacy';
    final purchase = _purchaseInfo(purchaseType);
    final cautions =
        (medicine['cautions'] as List?)?.cast<String>() ?? const [];

    final contraindications =
        (medicine['contraindications'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final precautionSummary =
        (medicine['precautionSummary'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final precautionDetails =
        (medicine['precautionDetails'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    final precautions = (medicine['precautions'] ?? '').toString().trim();

    final warning = (medicine['warning'] ?? '').toString().trim();

    final caution = (medicine['caution'] ?? '').toString().trim();

    final interactionInfo = (medicine['interactionInfo'] ?? '')
        .toString()
        .trim();

    final sideEffect = (medicine['sideEffect'] ?? '').toString().trim();

    final hasFullPrecautions =
        precautionDetails.isNotEmpty ||
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

    final interactionCheckError = (medicine['interactionCheckError'] ?? '')
        .toString()
        .trim();

    final allergyCheckRaw = medicine['allergyCheck'];

    final allergyCheck = allergyCheckRaw is Map
        ? Map<String, dynamic>.from(allergyCheckRaw)
        : <String, dynamic>{};

    final allergyCheckError = (medicine['allergyCheckError'] ?? '')
        .toString()
        .trim();

    final itemSeq = (medicine['itemSeq'] ?? '').toString().trim();

    final category = (medicine['category'] ?? '').toString().trim();

    final productType = (medicine['productType'] ?? '').toString().trim();

    final imageUrl = (medicine['imageUrl'] ?? '').toString().trim();

    final medicineType = purchaseType == 'prescription'
        ? 'prescription'
        : 'otc';

    final medicineTypeLabel = purchaseType == 'prescription'
        ? '전문의약품'
        : purchaseType == 'convenience'
        ? '안전상비의약품'
        : '일반의약품';

    List<String> _extractInteractionMessages(dynamic value) {
      if (value is! List) {
        return <String>[];
      }

      final result = <String>[];

      for (final item in value) {
        String text = '';

        if (item is String) {
          text = item.trim();
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);

          text = (map['message'] ?? '').toString().trim();

          // message가 없는 응답의 fallback
          if (text.isEmpty) {
            final medicineName =
                (map['medicineName'] ??
                        map['currentMedicineName'] ??
                        map['itemName'] ??
                        '')
                    .toString()
                    .trim();

            final ingredient = (map['ingredient'] ?? '').toString().trim();

            final reason = (map['reason'] ?? map['error'] ?? '')
                .toString()
                .trim();

            final parts = <String>[
              if (medicineName.isNotEmpty) medicineName,

              if (ingredient.isNotEmpty) ingredient,

              if (reason.isNotEmpty) reason,
            ];

            text = parts.join(' · ');
          }
        }

        if (text.isNotEmpty && !result.contains(text)) {
          result.add(text);
        }
      }

      return result;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 닫기 버튼 ───────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 22, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // ── 약 이미지 (더미 placeholder) ─────
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 160,
                    height: 160,
                    color: const Color(0xFFEFEFEF),
                    child: const Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 약 이름 + 제조사 ─────────────────
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
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // ── 구매처 뱃지 ──────────────────────
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
                      Icon(purchase.icon, size: 16, color: purchase.color),
                      const SizedBox(width: 6),
                      Text(
                        purchase.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: purchase.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (ingredient.isNotEmpty)
                _infoSection(
                  icon: Icons.science_outlined,
                  title: '성분',
                  content: ingredient,
                ),
              if (ingredient.isNotEmpty) const SizedBox(height: 12),

              if (effect.isNotEmpty)
                _infoSection(
                  icon: Icons.healing_outlined,
                  title: '효능·효과',
                  content: effect,
                ),
              if (effect.isNotEmpty) const SizedBox(height: 12),

              if (dosageSummary.isNotEmpty)
                _dosageSection(summaryItems: dosageSummary),

              if (dosageSummary.isNotEmpty) const SizedBox(height: 16),

              // ========================================
              // 알레르기 확인
              // ========================================
              if (allergyCheck.isNotEmpty) _allergyCheckSection(allergyCheck),

              if (allergyCheck.isNotEmpty) const SizedBox(height: 16),

              if (allergyCheckError.isNotEmpty) _allergyCheckErrorSection(),

              if (allergyCheckError.isNotEmpty) const SizedBox(height: 16),

              // ========================================
              // 병용 / 중복 복약 안전 확인
              // ========================================
              if (interactionCheck.isNotEmpty)
                _interactionCheckSection(interactionCheck),

              if (interactionCheck.isNotEmpty) const SizedBox(height: 16),

              if (interactionCheckError.isNotEmpty)
                _interactionCheckErrorSection(),

              if (interactionCheckError.isNotEmpty) const SizedBox(height: 16),

              // ── 핵심 주의사항 ─────────────────────
              if (precautionSummary.isNotEmpty)
                _precautionSummarySection(
                  summaryItems: precautionSummary,

                  precautionDetails: precautionDetails,

                  precautions: precautions,

                  warning: warning,

                  caution: caution,

                  interactionInfo: interactionInfo,

                  sideEffect: sideEffect,

                  cautions: cautions,

                  contraindications: contraindications,

                  hasFullPrecautions: hasFullPrecautions,
                ),

              if (precautionSummary.isNotEmpty && contraindications.isNotEmpty)
                const SizedBox(height: 16),

              if (contraindications.isNotEmpty)
                _contraindicationSection(items: contraindications),

              const SizedBox(height: 32),

              // ── 닫기 버튼 ───────────────────────
              // ── 등록하기 + 닫기 버튼 ───────────────────────
              // ── 복용하기(왼쪽) + 닫기(오른쪽) 버튼 ───────────────────
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

                                      // 식약처 식별값
                                      'itemSeq': itemSeq,

                                      // 약 기본 정보
                                      'manufacturer': manufacturer,
                                      'ingredient': ingredient,

                                      // 일반/전문의약품 분류
                                      'purchaseType': purchaseType,
                                      'medicineType': medicineType,
                                      'medicineTypeLabel': medicineTypeLabel,

                                      // 상세 약 정보
                                      'effect': effect,

                                      // 중요:
                                      // dosage는 복약 등록에서 숫자로 사용하므로
                                      // 상세페이지의 문자열 용법은 usage로 전달
                                      'usage': dosage,

                                      'cautions': cautions,
                                      'contraindications': contraindications,

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
                          style: TextStyle(fontSize: 16, color: Colors.black),
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

  Widget _dosageSection({required List<String> summaryItems}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, size: 20, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                '용법·용량',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...summaryItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 15)),

                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractInteractionMessages(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    final result = <String>[];

    for (final item in value) {
      String text = '';

      // 문자열 형태
      if (item is String) {
        text = item.trim();
      }
      // Map 형태
      else if (item is Map) {
        final map = Map<String, dynamic>.from(item);

        // 가장 먼저 message 사용
        text = (map['message'] ?? '').toString().trim();

        // message가 없는 경우 fallback
        if (text.isEmpty) {
          final medicineName =
              (map['medicineName'] ??
                      map['currentMedicineName'] ??
                      map['itemName'] ??
                      '')
                  .toString()
                  .trim();

          final ingredient = (map['ingredient'] ?? '').toString().trim();

          final reason = (map['reason'] ?? map['error'] ?? '')
              .toString()
              .trim();

          final parts = <String>[
            if (medicineName.isNotEmpty) medicineName,

            if (ingredient.isNotEmpty) ingredient,

            if (reason.isNotEmpty) reason,
          ];

          text = parts.join(' · ');
        }
      }

      if (text.isNotEmpty && !result.contains(text)) {
        result.add(text);
      }
    }

    return result;
  }

  Widget _allergyCheckSection(Map<String, dynamic> check) {
    final hasWarning = check['hasWarning'] == true;

    final message = (check['message'] ?? '').toString().trim();

    final matchedRaw = check['matchedAllergies'];

    final matchedAllergies = matchedRaw is List
        ? matchedRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    // ========================================
    // 알레르기 일치
    // ========================================

    if (hasWarning) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 22,
                  color: Colors.redAccent,
                ),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    '알레르기 주의',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (message.isNotEmpty)
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),

            if (message.isNotEmpty && matchedAllergies.isNotEmpty)
              const SizedBox(height: 12),

            ...matchedAllergies.map((match) {
              final allergy = (match['allergy'] ?? '').toString().trim();

              final ingredient = (match['ingredient'] ?? '').toString().trim();

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
                        '등록 알레르기: '
                        '$allergy',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),

                    if (ingredient.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        '약 성분: '
                        '$ingredient',
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

            const SizedBox(height: 3),

            const Text(
              '등록된 알레르기 정보와 '
              '약 성분이 일치합니다. '
              '복용 전 의사 또는 약사와 '
              '상담하세요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // ========================================
    // 일치 없음
    // ========================================

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, size: 21, color: Colors.green),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '알레르기 확인 완료',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message.isNotEmpty
                      ? message
                      : '현재 등록된 알레르기 '
                            '성분과 일치하는 성분이 '
                            '확인되지 않았습니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allergyCheckErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 21, color: Colors.orange),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              '알레르기 정보를 확인하지 '
              '못했습니다. 이 표시는 '
              '알레르기 위험이 없다는 의미가 '
              '아닙니다.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interactionCheckSection(Map<String, dynamic> check) {
    final durWarnings = _extractInteractionMessages(check['durWarnings']);

    final duplicateMedicineWarnings = _extractInteractionMessages(
      check['duplicateMedicineWarnings'],
    );

    final duplicateIngredientWarnings = _extractInteractionMessages(
      check['duplicateIngredientWarnings'],
    );

    var generalWarnings = _extractInteractionMessages(check['warnings']);

    final duplicateWarningsFromGeneral = generalWarnings.where((message) {
      final text = message.toLowerCase();

      return text.contains('동일 성분') || text.contains('중복 성분');
    }).toList();

    generalWarnings = generalWarnings
        .where((message) => !duplicateWarningsFromGeneral.contains(message))
        .toList();

    final alreadyShown = <String>{
      ...durWarnings,
      ...duplicateMedicineWarnings,
      ...duplicateIngredientWarnings,
    };

    generalWarnings = generalWarnings
        .where((item) => !alreadyShown.contains(item))
        .toList();

    final durErrors = _extractInteractionMessages(check['durErrors']);

    final skippedMedications = _extractInteractionMessages(
      check['skippedMedications'],
    );

    final allDuplicateIngredientWarnings = <String>{
      ...duplicateIngredientWarnings,
      ...duplicateWarningsFromGeneral,
    }.toList();

    final hasWarning =
        durWarnings.isNotEmpty ||
        duplicateMedicineWarnings.isNotEmpty ||
        duplicateIngredientWarnings.isNotEmpty ||
        duplicateWarningsFromGeneral.isNotEmpty ||
        generalWarnings.isNotEmpty;

    final hasCheckProblem =
        durErrors.isNotEmpty || skippedMedications.isNotEmpty;

    final checkedMedicationCount = (check['checkedMedicationCount'] as num?)
        ?.toInt();

    final backendMessage = (check['message'] ?? '').toString().trim();

    // ========================================
    // 실제 경고가 있는 경우
    // ========================================

    if (hasWarning) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.redAccent.withValues(alpha: 0.05),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.redAccent,
                  size: 21,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '복약 안전 확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),

            if (checkedMedicationCount != null && checkedMedicationCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '현재 복용약 '
                  '$checkedMedicationCount개와 '
                  '비교했습니다.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),

            const SizedBox(height: 14),

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
          ],
        ),
      );
    }

    // ========================================
    // 검사 일부 실패
    // ========================================

    if (hasCheckProblem) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.orange.withValues(alpha: 0.06),
        ),
        padding: const EdgeInsets.all(16),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '일부 복용약의 병용금기 정보를 '
                '확인하지 못했습니다.',
                style: TextStyle(fontSize: 14, height: 1.45),
              ),
            ),
          ],
        ),
      );
    }

    // ========================================
    // 경고 없음
    // ========================================

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.green.withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, size: 21, color: Colors.green),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '병용금기 확인 완료',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  backendMessage.isNotEmpty
                      ? backendMessage
                      : '현재 등록된 복용약과 '
                            '확인된 병용금기가 없습니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontSize: 14, color: color)),

                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interactionCheckErrorSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.orange.withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(16),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.orange, size: 21),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              '병용금기 정보를 확인하지 '
              '못했습니다. 이 표시는 안전함을 '
              '의미하지 않습니다.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _precautionSummarySection({
    required List<String> summaryItems,
    required List<Map<String, dynamic>> precautionDetails,
    required String precautions,
    required String warning,
    required String caution,
    required String interactionInfo,
    required String sideEffect,
    required List<String> cautions,
    required List<String> contraindications,
    required bool hasFullPrecautions,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.orange.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
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
              children: summaryItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 15)),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 14, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          if (hasFullPrecautions) ...[
            const Divider(height: 1),

            Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: const Text(
                  '전체 주의사항 보기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                children: [
                  // ========================================
                  // 백엔드에서 ARTICLE 단위로 정리한
                  // 전체 주의사항
                  // ========================================
                  if (precautionDetails.isNotEmpty)
                    ...precautionDetails.map((section) {
                      final title = (section['title'] ?? '').toString().trim();

                      final items =
                          (section['items'] as List?)
                              ?.map((e) => e.toString().trim())
                              .where((e) => e.isNotEmpty)
                              .toList() ??
                          <String>[];

                      if (items.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _precautionDetailSection(
                        title: title,
                        items: items,
                      );
                    }),

                  // precautionDetails가 없는 약만
                  // 일반 텍스트를 fallback으로 사용
                  if (precautionDetails.isEmpty && precautions.isNotEmpty)
                    _fullPrecautionItem(title: '전체 주의사항', content: precautions),

                  // 기존 개별 필드가 있는 경우
                  if (precautionDetails.isEmpty && warning.isNotEmpty)
                    _fullPrecautionItem(title: '중요 경고', content: warning),

                  if (precautionDetails.isEmpty && caution.isNotEmpty)
                    _fullPrecautionItem(title: '복용 시 주의', content: caution),

                  if (precautionDetails.isEmpty && interactionInfo.isNotEmpty)
                    _fullPrecautionItem(
                      title: '함께 복용 시 주의',
                      content: interactionInfo,
                    ),

                  if (precautionDetails.isEmpty && cautions.isNotEmpty)
                    _fullPrecautionItem(
                      title: '기타 주의사항',
                      content: cautions.join('\n\n'),
                    ),

                  if (precautionDetails.isEmpty && sideEffect.isNotEmpty)
                    _fullPrecautionItem(title: '이상반응', content: sideEffect),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contraindicationSection({required List<String> items}) {
    final previewItems = items.take(4).toList();

    final hasMore = items.length > 4;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.55)),
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
                    '금기사항 '
                    '(이런 경우 복용하지 마세요)',
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
              children: previewItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 15)),

                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          if (hasMore) ...[
            const Divider(height: 1),

            Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  '전체 금기사항 보기 ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  ...items
                      .skip(4)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 15)),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
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
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),

                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullPrecautionItem({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
}
