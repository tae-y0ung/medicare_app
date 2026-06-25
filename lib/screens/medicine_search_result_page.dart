import 'package:flutter/material.dart';
import 'medicine_detail_page.dart';
import 'ocr_edit_page.dart';
import 'user_profile.dart';

enum MedicineSearchMode { info, register }

/// 약 검색 결과 목록 페이지
///
/// [mode] == info    : 약 정보 확인용. 카드 탭 → MedicineDetailPage (등록 없음)
/// [mode] == register: 약 직접 등록용. 카드 탭 → 선택 토글 → "선택 완료" 버튼
///
/// register 모드에서 "선택 완료"를 눌렀을 때 동작은 [onSelectionComplete]로 결정됩니다.
/// - onSelectionComplete가 없으면: 이 페이지를 연 곳이 "최종 등록"까지 책임지는 경우
///   (예: 홈 화면에서 바로 등록하는 흐름)이므로, 곧바로 OcrEditPage로 이동합니다.
/// - onSelectionComplete가 있으면: 이 페이지를 연 곳(예: MedicineSearchPage)이
///   선택된 이름 리스트를 받아서 자기 나름대로 처리하고 싶은 경우이므로,
///   그 콜백에 선택된 이름들을 넘겨줍니다. (보통 Navigator.pop으로 돌려주는 용도)
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

  static const Map<String, List<Map<String, dynamic>>> _db = {
    '타이레놀': [
      {
        'productName': '타이레놀 정 500mg',
        'manufacturer': '한국얀센',
        'ingredient': '아세트아미노펜 500mg',
        'purchaseType': 'pharmacy',
        'effect': '해열·진통(두통, 치통, 근육통, 생리통 등)',
        'dosage': '1회 1~2정, 1일 3~4회 (4~6시간 간격)',
        'cautions': ['음주 중 또는 음주 후 복용 금지', '간 질환자는 복용 전 의사 상담', '다른 아세트아미노펜 함유 제품과 중복 복용 금지', '1일 최대 4,000mg 초과 금지'],
        'contraindications': ['중증 간기능 장애', '아세트아미노펜 과민반응'],
      },
      {
        'productName': '타이레놀 8시간 이알서방정 650mg',
        'manufacturer': '한국얀센',
        'ingredient': '아세트아미노펜 650mg (서방형)',
        'purchaseType': 'pharmacy',
        'effect': '해열·진통 (8시간 지속)',
        'dosage': '1회 2정, 1일 3회 (8시간 간격) — 씹거나 쪼개지 말 것',
        'cautions': ['반드시 통째로 삼킬 것', '음주 금지', '1일 최대 3,900mg(6정) 초과 금지'],
        'contraindications': ['중증 간기능 장애', '아세트아미노펜 과민반응'],
      },
      {
        'productName': '타이레놀 어린이 시럽',
        'manufacturer': '한국얀센',
        'ingredient': '아세트아미노펜 32mg/mL',
        'purchaseType': 'pharmacy',
        'effect': '소아 해열·진통',
        'dosage': '체중·나이에 따라 조절 (동봉 계량컵 사용)',
        'cautions': ['2세 미만은 반드시 의사 처방 후 사용', '다른 아세트아미노펜 함유 제품과 중복 금지', '개봉 후 6개월 이내 사용'],
        'contraindications': ['아세트아미노펜 과민반응'],
      },
    ],
    '이부프로펜': [
      {
        'productName': '애드빌 리퀴-겔 200mg',
        'manufacturer': '한국화이자',
        'ingredient': '이부프로펜 200mg',
        'purchaseType': 'pharmacy',
        'effect': '해열·진통·소염 (두통, 치통, 생리통, 근육통)',
        'dosage': '1회 1~2캡슐, 1일 3회 (식후 30분)',
        'cautions': ['공복 복용 금지', '음주 금지', '임신 3개월 이후 복용 금지'],
        'contraindications': ['소화성 궤양', '심부전', '중증 신·간 기능 장애'],
      },
      {
        'productName': '부루펜 시럽',
        'manufacturer': '삼일제약',
        'ingredient': '이부프로펜 100mg/5mL',
        'purchaseType': 'pharmacy',
        'effect': '소아 해열·진통·소염',
        'dosage': '체중 기준 1회 5~10mg/kg, 1일 3~4회',
        'cautions': ['6개월 미만 영아 사용 금지', '수두·독감 증상 어린이에게 주의'],
        'contraindications': ['소화성 궤양', 'NSAID 과민반응'],
      },
    ],
    '아스피린': [
      {
        'productName': '아스피린 프로텍트 100mg',
        'manufacturer': '바이엘코리아',
        'ingredient': '아세틸살리실산 100mg',
        'purchaseType': 'pharmacy',
        'effect': '혈전 예방 (심근경색·뇌졸중 재발 억제)',
        'dosage': '1회 1정, 1일 1회',
        'cautions': ['출혈 위험 증가 — 수술 전 1주일 복용 중단', '음주 금지', '15세 미만 소아 복용 금지'],
        'contraindications': ['출혈성 소인', '살리실산염 과민반응', '소화성 궤양'],
      },
      {
        'productName': '바이엘 아스피린 500mg',
        'manufacturer': '바이엘코리아',
        'ingredient': '아세틸살리실산 500mg',
        'purchaseType': 'pharmacy',
        'effect': '해열·진통·소염',
        'dosage': '1회 1~2정, 1일 3~4회 (식후)',
        'cautions': ['15세 미만 소아 복용 금지', '음주 금지'],
        'contraindications': ['출혈성 소인', '소화성 궤양', '임신 3개월 이후'],
      },
    ],
    '판콜에이': [
      {
        'productName': '판콜에이 내복액',
        'manufacturer': '동화약품',
        'ingredient': '아세트아미노펜·구아이페네신·클로르페니라민말레산염 등',
        'purchaseType': 'pharmacy',
        'effect': '감기 증상 완화 (발열·콧물·코막힘·기침)',
        'dosage': '1회 1포(15mL), 1일 3회 (식후 30분)',
        'cautions': ['졸림 유발 — 운전·기계 조작 금지', '음주 금지', '다른 감기약과 중복 복용 금지'],
        'contraindications': ['MAO 억제제 복용 중', '중증 고혈압'],
      },
    ],
    '게보린': [
      {
        'productName': '게보린 정',
        'manufacturer': '삼진제약',
        'ingredient': '아세트아미노펜·이소프로필안티피린·카페인무수물',
        'purchaseType': 'pharmacy',
        'effect': '두통·치통·생리통·근육통 완화',
        'dosage': '1회 1정, 1일 3회 (4시간 이상 간격)',
        'cautions': ['음주 금지', '운전 주의', '카페인 민감자 주의', '15세 미만 소아 복용 금지', '1일 3정 초과 금지'],
        'contraindications': ['혈액 질환', '중증 간·신 기능 장애'],
      },
    ],
    '지르텍': [
      {
        'productName': '지르텍-D 정',
        'manufacturer': '한국UCB',
        'ingredient': '세티리진염산염 5mg·슈도에페드린염산염 120mg',
        'purchaseType': 'pharmacy',
        'effect': '알레르기 비염 (콧물·코막힘·재채기)',
        'dosage': '1회 1정, 1일 2회 (12시간 간격)',
        'cautions': ['졸림 유발 — 운전 주의', '고혈압·심장 질환자 복용 금지', '음주 금지', '12세 미만 소아 사용 금지'],
        'contraindications': ['MAO 억제제 복용 중', '중증 고혈압', '갑상선 기능 항진증'],
      },
      {
        'productName': '지르텍 정 10mg',
        'manufacturer': '한국UCB',
        'ingredient': '세티리진염산염 10mg',
        'purchaseType': 'prescription',
        'effect': '알레르기 비염·두드러기·아토피 피부염',
        'dosage': '1회 1정, 1일 1회 (취침 전 권장)',
        'cautions': ['졸림 유발 — 운전·기계 조작 주의', '음주 금지', '신장 기능 저하 환자는 용량 조절 필요'],
        'contraindications': ['세티리진·히드록시진 과민반응', '중증 신기능 장애'],
      },
    ],
    '베아제': [
      {
        'productName': '베아제 정',
        'manufacturer': '동아제약',
        'ingredient': '판크레아틴·우르소데옥시콜산·건조수산화알루미늄겔 등',
        'purchaseType': 'pharmacy',
        'effect': '소화불량·식후 더부룩함·과식 후 소화 촉진',
        'dosage': '1회 1정, 1일 3회 (식후 즉시)',
        'cautions': ['돼지 유래 성분 포함 — 관련 알레르기 주의', '담도 폐쇄 환자 복용 금지'],
        'contraindications': ['담도 폐쇄', '급성 췌장염'],
      },
    ],
    '훼스탈': [
      {
        'productName': '훼스탈 플러스 정',
        'manufacturer': '한독',
        'ingredient': '판크레아틴·셀룰라아제·헤미셀룰라아제',
        'purchaseType': 'pharmacy',
        'effect': '소화 효소 보충, 소화불량·팽만감 완화',
        'dosage': '1회 1~2정, 1일 3회 (식사 중 또는 식후)',
        'cautions': ['돼지 유래 성분 포함', '씹지 말고 통째로 삼킬 것'],
        'contraindications': ['급성 췌장염', '담도 폐쇄'],
      },
    ],
    '우루사': [
      {
        'productName': '우루사 100mg 연질캡슐',
        'manufacturer': '대웅제약',
        'ingredient': '우르소데옥시콜산 100mg',
        'purchaseType': 'pharmacy',
        'effect': '피로 회복·간 기능 개선 보조',
        'dosage': '1회 1캡슐, 1일 3회 (식후)',
        'cautions': ['담도가 완전히 막힌 경우 복용 금지', '임산부는 의사 상담 필수'],
        'contraindications': ['담도 완전 폐쇄', '급성 담낭염'],
      },
      {
        'productName': '우루사 200mg (전문의약품)',
        'manufacturer': '대웅제약',
        'ingredient': '우르소데옥시콜산 200mg',
        'purchaseType': 'prescription',
        'effect': '담석 용해·원발성 담즙성 간경변 치료',
        'dosage': '의사 처방에 따름',
        'cautions': ['반드시 처방전 필요', '정기적인 간 기능 검사 권장'],
        'contraindications': ['담도 완전 폐쇄', '급성 담낭염·담관염'],
      },
    ],
  };

  List<Map<String, dynamic>> get _results {
    final found = <Map<String, dynamic>>[];
    for (final key in _db.keys) {
      if (key.contains(widget.query)) found.addAll(_db[key]!);
    }
    return found;
  }

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

  void _onCardTap(Map<String, dynamic> medicine) {
    if (widget.mode == MedicineSearchMode.info) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MedicineDetailPage(medicine: medicine)),
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

    // 콜백이 없으면(예: 홈 화면 등에서 곧바로 등록까지 끝내고 싶은 경우)
    // 기존처럼 OcrEditPage로 직접 이동합니다.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OcrEditPage(
          medicineNames: _selected.toList(),
          userProfile: widget.userProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
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
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.black45),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final medicine = results[index];
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
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.medication_outlined, size: 30, color: Colors.black38),
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
                          : '선택 완료 (${_selected.length}개) → 등록하기',
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