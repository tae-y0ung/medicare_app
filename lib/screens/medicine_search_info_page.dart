// medicine_search_info_page.dart
import 'package:flutter/material.dart';
import 'medicine_detail_page.dart';

class MedicineSearchInfoPage extends StatelessWidget {
  final String symptomLabel;

  const MedicineSearchInfoPage({
    super.key,
    required this.symptomLabel,
  });

  static const Map<String, List<Map<String, dynamic>>> _symptomMedicines = {
    '감기 / 열': [
      {
        'productName': '타이레놀',
        'manufacturer': '한국얀센',
        'ingredient': '아세트아미노펜 500mg',
        'purchaseType': 'pharmacy',
        'effect': '해열·진통 (두통, 치통, 근육통, 생리통 등)',
        'dosage': '하루 3회, 식후 30분',
        'cautions': ['음주 중 또는 음주 후 복용 금지', '간 질환자는 복용 전 의사 상담', '1일 최대 4,000mg 초과 금지'],
        'contraindications': ['중증 간기능 장애', '아세트아미노펜 과민반응'],
      },
      {
        'productName': '판콜에이',
        'manufacturer': '동화약품',
        'ingredient': '아세트아미노펜·구아이페네신·클로르페니라민말레산염 등',
        'purchaseType': 'pharmacy',
        'effect': '감기 증상 완화 (발열·콧물·코막힘·기침)',
        'dosage': '하루 3회, 식후 30분',
        'cautions': ['졸림 유발 — 운전·기계 조작 금지', '음주 금지', '다른 감기약과 중복 복용 금지'],
        'contraindications': ['MAO 억제제 복용 중', '중증 고혈압'],
      },
      {
        'productName': '타이레놀콜드',
        'manufacturer': '한국얀센',
        'ingredient': '아세트아미노펜·슈도에페드린 등',
        'purchaseType': 'pharmacy',
        'effect': '감기 복합 증상 완화 (발열·코막힘·기침)',
        'dosage': '하루 2회, 식후 30분',
        'cautions': ['음주 금지', '임산부 복용 전 의사 상담'],
        'contraindications': ['중증 고혈압', '아세트아미노펜 과민반응'],
      },
    ],
    '통증': [
      {
        'productName': '이부프로펜',
        'manufacturer': '한국화이자',
        'ingredient': '이부프로펜 200mg',
        'purchaseType': 'pharmacy',
        'effect': '해열·진통·소염 (두통, 치통, 생리통, 근육통)',
        'dosage': '하루 3회, 식후 30분',
        'cautions': ['공복 복용 금지', '음주 금지', '임신 3개월 이후 복용 금지'],
        'contraindications': ['소화성 궤양', '심부전', '중증 신·간 기능 장애'],
      },
      {
        'productName': '부루펜',
        'manufacturer': '삼일제약',
        'ingredient': '이부프로펜 100mg/5mL',
        'purchaseType': 'pharmacy',
        'effect': '해열·진통·소염',
        'dosage': '하루 3회, 식후 30분',
        'cautions': ['음주 금지', '장기복용 주의'],
        'contraindications': ['소화성 궤양', 'NSAID 과민반응'],
      },
      {
        'productName': '게보린',
        'manufacturer': '삼진제약',
        'ingredient': '아세트아미노펜·이소프로필안티피린·카페인무수물',
        'purchaseType': 'pharmacy',
        'effect': '두통·치통·생리통·근육통 완화',
        'dosage': '하루 3회, 식후 30분',
        'cautions': ['음주 금지', '운전 주의', '카페인 민감자 주의', '15세 미만 소아 복용 금지'],
        'contraindications': ['혈액 질환', '중증 간·신 기능 장애'],
      },
    ],
    '소화 / 위장': [
      {
        'productName': '베아제',
        'manufacturer': '동아제약',
        'ingredient': '판크레아틴·우르소데옥시콜산·건조수산화알루미늄겔 등',
        'purchaseType': 'pharmacy',
        'effect': '소화불량·식후 더부룩함·과식 후 소화 촉진',
        'dosage': '하루 3회, 식후 즉시',
        'cautions': ['돼지 유래 성분 포함 — 관련 알레르기 주의', '담도 폐쇄 환자 복용 금지'],
        'contraindications': ['담도 폐쇄', '급성 췌장염'],
      },
      {
        'productName': '훼스탈',
        'manufacturer': '한독',
        'ingredient': '판크레아틴·셀룰라아제·헤미셀룰라아제',
        'purchaseType': 'pharmacy',
        'effect': '소화 효소 보충, 소화불량·팽만감 완화',
        'dosage': '하루 3회, 식사 중 또는 식후',
        'cautions': ['돼지 유래 성분 포함', '씹지 말고 통째로 삼킬 것'],
        'contraindications': ['급성 췌장염', '담도 폐쇄'],
      },
      {
        'productName': '우루사',
        'manufacturer': '대웅제약',
        'ingredient': '우르소데옥시콜산 100mg',
        'purchaseType': 'pharmacy',
        'effect': '피로 회복·간 기능 개선 보조',
        'dosage': '하루 3회, 식후 30분',
        'cautions': ['담도가 완전히 막힌 경우 복용 금지', '임산부는 의사 상담 필수'],
        'contraindications': ['담도 완전 폐쇄', '급성 담낭염'],
      },
    ],
    '알레르기': [
      {
        'productName': '지르텍',
        'manufacturer': '한국UCB',
        'ingredient': '세티리진염산염 10mg',
        'purchaseType': 'prescription',
        'effect': '알레르기 비염·두드러기·아토피 피부염',
        'dosage': '하루 1회, 취침 전',
        'cautions': ['졸림 유발 — 운전·기계 조작 주의', '음주 금지', '신장 기능 저하 환자는 용량 조절 필요'],
        'contraindications': ['세티리진·히드록시진 과민반응', '중증 신기능 장애'],
      },
      {
        'productName': '클라리틴',
        'manufacturer': '바이엘코리아',
        'ingredient': '로라타딘 10mg',
        'purchaseType': 'pharmacy',
        'effect': '알레르기 비염·만성 두드러기',
        'dosage': '하루 1회, 식후',
        'cautions': ['음주 금지', '간 기능 저하 환자 주의'],
        'contraindications': ['로라타딘 과민반응'],
      },
      {
        'productName': '알레그라',
        'manufacturer': '사노피',
        'ingredient': '펙소페나딘염산염 120mg',
        'purchaseType': 'pharmacy',
        'effect': '알레르기 비염·두드러기',
        'dosage': '하루 1회, 식후',
        'cautions': ['자몽주스와 함께 복용 금지', '제산제 복용 시 2시간 간격 유지'],
        'contraindications': ['펙소페나딘 과민반응'],
      },
    ],
    '수면 / 피로': [
      {
        'productName': '아로나민골드',
        'manufacturer': '일동제약',
        'ingredient': '활성형 비타민B1·B2·B6·B12 복합',
        'purchaseType': 'pharmacy',
        'effect': '신체 피로 회복·영양 보충',
        'dosage': '하루 1회, 식후',
        'cautions': ['과다복용 주의', '소변이 노랗게 변할 수 있음 (정상)'],
        'contraindications': [],
      },
      {
        'productName': '박카스',
        'manufacturer': '동아제약',
        'ingredient': '타우린 1,000mg·카페인 30mg',
        'purchaseType': 'pharmacy',
        'effect': '육체적 피로 회복',
        'dosage': '하루 2회',
        'cautions': ['카페인 민감자 주의', '어린이 복용 주의'],
        'contraindications': [],
      },
      {
        'productName': '멜라토닌',
        'manufacturer': '다수',
        'ingredient': '멜라토닌 0.5~5mg',
        'purchaseType': 'pharmacy',
        'effect': '수면 리듬 조절·시차 적응 보조',
        'dosage': '하루 1회, 취침 전 30분',
        'cautions': ['운전 금지', '음주 금지', '장기복용 전 의사 상담'],
        'contraindications': ['자가면역 질환', '임산부·수유부'],
      },
    ],
    '피부': [
      {
        'productName': '후시딘',
        'manufacturer': '동화약품',
        'ingredient': '푸시드산나트륨 2%',
        'purchaseType': 'pharmacy',
        'effect': '피부 세균 감염 (상처·습진·농가진)',
        'dosage': '하루 2~3회, 환부에 도포',
        'cautions': ['눈 주위 사용 금지', '장기간 넓은 부위 사용 금지'],
        'contraindications': ['푸시드산 과민반응'],
      },
      {
        'productName': '마데카솔',
        'manufacturer': '동국제약',
        'ingredient': '센텔라아시아티카 추출물·네오마이신황산염',
        'purchaseType': 'pharmacy',
        'effect': '상처 치유 촉진·피부 재생',
        'dosage': '하루 2~3회, 환부에 도포',
        'cautions': ['알레르기 주의', '눈 주위 사용 금지'],
        'contraindications': ['네오마이신 과민반응'],
      },
      {
        'productName': '센텔라크림',
        'manufacturer': '다수',
        'ingredient': '센텔라아시아티카 추출물',
        'purchaseType': 'pharmacy',
        'effect': '피부 진정·보습·재생 보조',
        'dosage': '하루 2회, 세안 후 도포',
        'cautions': ['상처 부위 직접 도포 금지', '눈 점막 접촉 주의'],
        'contraindications': [],
      },
    ],
    '응급 증상': [
      {
        'productName': '니트로글리세린',
        'manufacturer': '다수',
        'ingredient': '니트로글리세린 0.5mg',
        'purchaseType': 'prescription',
        'effect': '협심증 발작 완화',
        'dosage': '증상 발생 시 혀 밑에 1정 — 5분 후 미개선 시 즉시 응급실',
        'cautions': ['즉시 병원 방문 필요', '저혈압 유발 가능 — 앉거나 누운 상태에서 복용', '빛·열에 민감 — 차광 보관'],
        'contraindications': ['중증 저혈압', '폐쇄각녹내장', 'PDE-5 억제제(비아그라 등) 복용 중'],
      },
      {
        'productName': '에피네프린 자가주사',
        'manufacturer': '다수',
        'ingredient': '에피네프린 0.3mg',
        'purchaseType': 'prescription',
        'effect': '아나필락시스(중증 알레르기 반응) 응급 처치',
        'dosage': '증상 발생 시 허벅지 외측에 1회 주사 — 주사 후 즉시 응급실',
        'cautions': ['주사 후 반드시 응급실 방문', '어린이는 체중에 따라 용량 다름'],
        'contraindications': [],
      },
      {
        'productName': '아스피린 (응급용)',
        'manufacturer': '바이엘코리아',
        'ingredient': '아세틸살리실산 300~500mg',
        'purchaseType': 'pharmacy',
        'effect': '심근경색 의심 시 혈전 억제 응급 보조',
        'dosage': '심근경색 의심 시 즉시 1정 씹어 복용 — 즉시 응급실',
        'cautions': ['출혈 위험 — 복용 후 반드시 병원 방문', '위장 출혈 병력자 주의'],
        'contraindications': ['출혈성 소인', '살리실산염 과민반응'],
      },
    ],
  };

  List<Map<String, dynamic>> get _medicines =>
      _symptomMedicines[symptomLabel] ?? [];

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

  @override
  Widget build(BuildContext context) {
    final medicines = _medicines;

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
                        symptomLabel,
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

            // ── 안내 배너 ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF5F5F5),
              child: const Text(
                '약을 탭하면 성분·복용법·주의사항을 확인할 수 있습니다.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),

            const Divider(height: 1, color: Colors.black12),

            // ── 약 목록 ────────────────────────────────────────
            Expanded(
              child: medicines.isEmpty
                  ? const Center(
                      child: Text(
                        '추천 약 정보가 없습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.black45),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: medicines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final medicine = medicines[index];
                        final purchase = _purchaseInfo(
                            medicine['purchaseType'] as String? ?? 'pharmacy');

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MedicineDetailPage(medicine: medicine),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // 약 아이콘
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.medication_outlined,
                                    size: 30,
                                    color: Colors.black38,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // 약 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine['productName'] as String,
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
                                          Icon(purchase.icon,
                                              size: 14,
                                              color: purchase.color),
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

                                // 상세보기 화살표
                                const Icon(Icons.chevron_right,
                                    color: Colors.black38),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}