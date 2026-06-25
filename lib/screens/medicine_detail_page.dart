import 'package:flutter/material.dart';

/// 약 상세 정보 페이지
///
/// MedicineSearchResultPage(검색 결과, info 모드)에서 카드를 탭했을 때 이동하는 화면입니다.
/// 약 이름만 보고 넘어가지 않도록, 제조사/성분/효능/복약법/주의사항/금기사항을
/// 한 화면에서 자세히 볼 수 있게 보여줍니다.
///
/// medicine은 MedicineSearchResultPage._db와 같은 형태의 Map입니다:
/// {productName, manufacturer, ingredient, purchaseType, effect, dosage, cautions, contraindications}
class MedicineDetailPage extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailPage({
    super.key,
    required this.medicine,
  });

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
  Widget build(BuildContext context) {
    final productName = medicine['productName'] as String? ?? '약 이름';
    final manufacturer = medicine['manufacturer'] as String? ?? '';
    final ingredient = medicine['ingredient'] as String? ?? '';
    final effect = medicine['effect'] as String? ?? '';
    final dosage = medicine['dosage'] as String? ?? '';
    final purchaseType = medicine['purchaseType'] as String? ?? 'pharmacy';
    final cautions = (medicine['cautions'] as List?)?.cast<String>() ?? const [];
    final contraindications =
        (medicine['contraindications'] as List?)?.cast<String>() ?? const [];
    final purchase = _purchaseInfo(purchaseType);

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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: purchase.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: purchase.color.withValues(alpha: 0.4)),
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
                _infoSection(icon: Icons.science_outlined, title: '성분', content: ingredient),
              if (ingredient.isNotEmpty) const SizedBox(height: 12),

              if (effect.isNotEmpty)
                _infoSection(icon: Icons.healing_outlined, title: '효능·효과', content: effect),
              if (effect.isNotEmpty) const SizedBox(height: 12),

              if (dosage.isNotEmpty)
                _infoSection(icon: Icons.schedule, title: '용법·용량', content: dosage),
              if (dosage.isNotEmpty) const SizedBox(height: 16),

              // ── 주의사항 박스 (강조) ──────────────
              if (cautions.isNotEmpty)
                _warningSection(
                  icon: Icons.warning_amber_rounded,
                  title: '주의사항',
                  items: cautions,
                  color: Colors.orange,
                ),
              if (cautions.isNotEmpty) const SizedBox(height: 12),

              // ── 금기사항 박스 (더 강하게 강조) ─────
              if (contraindications.isNotEmpty)
                _warningSection(
                  icon: Icons.dangerous_outlined,
                  title: '금기사항 (이런 경우 복용하지 마세요)',
                  items: contraindications,
                  color: Colors.redAccent,
                ),

              const SizedBox(height: 32),

              // ── 닫기 버튼 ───────────────────────
              Center(
                child: SizedBox(
                  width: 200,
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

              const SizedBox(height: 20),
            ],
          ),
        ),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _warningSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.06),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, height: 1.4),
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
}