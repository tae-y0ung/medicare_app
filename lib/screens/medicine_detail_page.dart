import 'package:flutter/material.dart';

/// 약 상세 정보 페이지
///
/// MedicineSearchResultPage에서 제품을 탭했을 때 이동하는 화면입니다.
/// 성분/효능, 복용법, 구매처, 주의사항/금기사항을 보여줍니다.
/// 이 루트에서는 복약 등록 기능이 없습니다.
class MedicineDetailPage extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailPage({super.key, required this.medicine});

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
      case 'pharmacy':
      default:
        return (
          label: '약국 구매 가능 (일반의약품)',
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          icon: Icons.local_pharmacy_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchase = _purchaseInfo(medicine['purchaseType'] as String? ?? 'pharmacy');
    final cautions = (medicine['cautions'] as List?)?.cast<String>() ?? [];
    final contraindications =
        (medicine['contraindications'] as List?)?.cast<String>() ?? [];

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
                  const Expanded(
                    child: Center(
                      child: Text(
                        '약 상세 정보',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
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

            // ── 본문 ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 제품명 + 제조사 ────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            size: 36,
                            color: Colors.black38,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medicine['productName'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                medicine['manufacturer'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── 구매처 배지 ────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: purchase.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(purchase.icon, color: purchase.color, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            purchase.label,
                            style: TextStyle(
                              color: purchase.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 성분 / 효능 ────────────────────────────
                    _sectionCard(
                      icon: Icons.science_outlined,
                      title: '성분 / 효능',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _labeledRow('주성분', medicine['ingredient'] as String? ?? ''),
                          const SizedBox(height: 8),
                          _labeledRow('효능·효과', medicine['effect'] as String? ?? ''),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 복용법 ─────────────────────────────────
                    _sectionCard(
                      icon: Icons.schedule_outlined,
                      title: '복용법',
                      child: Text(
                        medicine['dosage'] as String? ?? '',
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 주의사항 ───────────────────────────────
                    if (cautions.isNotEmpty)
                      _sectionCard(
                        icon: Icons.warning_amber_outlined,
                        title: '주의사항',
                        iconColor: const Color(0xFFF57F17),
                        child: Column(
                          children: cautions
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              fontSize: 14, color: Color(0xFFF57F17))),
                                      Expanded(
                                        child: Text(c,
                                            style: const TextStyle(fontSize: 14, height: 1.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                    if (cautions.isNotEmpty) const SizedBox(height: 12),

                    // ── 금기사항 ───────────────────────────────
                    if (contraindications.isNotEmpty)
                      _sectionCard(
                        icon: Icons.block_outlined,
                        title: '금기사항 (복용 불가)',
                        iconColor: const Color(0xFFB71C1C),
                        headerColor: const Color(0xFFFFEBEE),
                        child: Column(
                          children: contraindications
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('✕ ',
                                          style: TextStyle(
                                              fontSize: 13, color: Color(0xFFB71C1C))),
                                      Expanded(
                                        child: Text(c,
                                            style: const TextStyle(
                                                fontSize: 14, height: 1.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── 안내 문구 ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '이 정보는 일반적인 참고용입니다.\n'
                        '정확한 복용법과 주의사항은 약사 또는 의사와 상담하세요.',
                        style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 섹션 카드 공통 위젯
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color iconColor = const Color(0xFF37474F),
    Color? headerColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor ?? const Color(0xFFF8F8F8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: const Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          // 섹션 본문
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _labeledRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
}