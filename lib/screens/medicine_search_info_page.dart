import 'package:flutter/material.dart';
import 'ocr_edit_page.dart';
import 'user_profile.dart'; // ✅ UserProfile 모델

class MedicineSearchInfoPage extends StatelessWidget {
  final String symptomLabel;

  const MedicineSearchInfoPage({
    super.key,
    required this.symptomLabel,
  });

  // ✅ 증상별 더미 약 추천 데이터 (나중에 DB/API로 교체)
  static const Map<String, List<Map<String, String>>> _symptomMedicines = {
    '감기 / 열': [
      {
        'name': '타이레놀',
        'dosage': '하루 3회, 식후 30분',
        'caution': '음주 금지\n과다복용 주의',
      },
      {
        'name': '판콜에이',
        'dosage': '하루 3회, 식후 30분',
        'caution': '운전 금지\n졸림 유발 가능',
      },
      {
        'name': '타이레놀콜드',
        'dosage': '하루 2회, 식후 30분',
        'caution': '음주 금지\n임산부 주의',
      },
    ],
    '통증': [
      {
        'name': '이부프로펜',
        'dosage': '하루 3회, 식후 30분',
        'caution': '공복 금지\n위장장애 주의',
      },
      {
        'name': '부루펜',
        'dosage': '하루 3회, 식후 30분',
        'caution': '음주 금지\n장기복용 주의',
      },
      {
        'name': '게보린',
        'dosage': '하루 3회, 식후 30분',
        'caution': '음주 금지\n운전 금지',
      },
    ],
    '소화 / 위장': [
      {
        'name': '베아제',
        'dosage': '하루 3회, 식후 즉시',
        'caution': '과다복용 주의',
      },
      {
        'name': '훼스탈',
        'dosage': '하루 3회, 식후 즉시',
        'caution': '알레르기 주의',
      },
      {
        'name': '우루사',
        'dosage': '하루 3회, 식후 30분',
        'caution': '간 질환자 상담 필요',
      },
    ],
    '알레르기': [
      {
        'name': '지르텍',
        'dosage': '하루 1회, 취침 전',
        'caution': '졸림 유발\n운전 금지',
      },
      {
        'name': '클라리틴',
        'dosage': '하루 1회, 식후',
        'caution': '음주 금지',
      },
      {
        'name': '알레그라',
        'dosage': '하루 1회, 식후',
        'caution': '자몽주스 금지',
      },
    ],
    '수면 / 피로': [
      {
        'name': '아로나민골드',
        'dosage': '하루 1회, 식후',
        'caution': '과다복용 주의',
      },
      {
        'name': '박카스',
        'dosage': '하루 2회',
        'caution': '카페인 민감자 주의',
      },
      {
        'name': '멜라토닌',
        'dosage': '하루 1회, 취침 전',
        'caution': '운전 금지\n음주 금지',
      },
    ],
    '피부': [
      {
        'name': '후시딘',
        'dosage': '하루 2~3회, patch 도포',
        'caution': '눈 주위 사용 금지',
      },
      {
        'name': '마데카솔',
        'dosage': '하루 2~3회, patch 도포',
        'caution': '알레르기 주의',
      },
      {
        'name': '센텔라크림',
        'dosage': '하루 2회',
        'caution': '상처 부위 직접 도포 금지',
      },
    ],
    '응급 증상': [
      {
        'name': '니트로글리세린',
        'dosage': '증상 발생 시 1회',
        'caution': '즉시 병원 방문 필요',
      },
      {
        'name': '에피네프린',
        'dosage': '증상 발생 시 1회',
        'caution': '즉시 응급실 방문 필요',
      },
      {
        'name': '아스피린',
        'dosage': '응급 시 1회',
        'caution': '출혈 위험 주의',
      },
    ],
  };

  List<Map<String, String>> get _medicines =>
      _symptomMedicines[symptomLabel] ??
      const [
        {'name': '약 이름', 'dosage': '하루 n회, 식후 n분', 'caution': '음주 금지\n운전 금지'},
      ];

  void _onSelectMedicine(BuildContext context, String medicineName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OcrEditPage(
          medicineNames: [medicineName],
          userProfile: UserProfile.empty(), // ✅ UserProfile 전달
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicines = _medicines;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── 로고 ───────────────────────────
              Image.asset(
                'assets/images/medicare_logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),

              // ── 제목 (증상 이름) ───────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  symptomLabel,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                ),
              ),

              // ── 증상별 약 추천 박스 ─────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // 헤더
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        border: Border(bottom: BorderSide(color: Colors.black)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('증상별 약 추천', style: TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 약 리스트
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (final medicine in medicines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _medicineCard(context, medicine),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 등록하기 버튼 ──────────────────
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 250,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 여러 약을 한꺼번에 등록하는 흐름이 필요하다면 여기서 처리
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB3B3B3),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                    child: const Text(
                      '등록하기',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  // 약 추천 카드: 이미지 + 약 이름/복약 횟수/주의사항 + 선택 버튼
  Widget _medicineCard(BuildContext context, Map<String, String> medicine) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 약 이미지 (더미 placeholder)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 90,
              height: 90,
              color: const Color(0xFFEFEFEF),
              child: const Icon(
                Icons.medication_outlined,
                size: 36,
                color: Colors.black38,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('약 이름', medicine['name'] ?? ''),
                const SizedBox(height: 4),
                _infoRow('복약 횟수', medicine['dosage'] ?? ''),
                const SizedBox(height: 4),
                _infoRow('주의 사항', medicine['caution'] ?? ''),
              ],
            ),
          ),

          // 선택 버튼
          Align(
            alignment: Alignment.bottomRight,
            child: OutlinedButton(
              onPressed: () => _onSelectMedicine(context, medicine['name'] ?? ''),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Text('선택', style: TextStyle(color: Colors.black, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}