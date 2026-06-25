import 'package:flutter/material.dart';
import 'medicine_search_info_page.dart';
import 'medicine_search_result_page.dart';
import 'user_profile.dart';

/// 약 검색 입구 페이지
///
/// 이 페이지 자체는 약 목록을 보여주지 않습니다. 검색창 + "증상별 약 추천" 박스만
/// 제공하고, 실제 결과는 항상 다음 화면으로 넘깁니다:
/// - 검색창에서 "검색"  → MedicineSearchResultPage (제조사/성분/주의사항까지 상세)
/// - 증상별 박스 탭     → MedicineSearchInfoPage (증상 전용 간단 카드, 기존 그대로)
///
/// [isForRegistration]이 true면 "약 등록" 흐름(OcrEditPage의 + 버튼 등)에서 열린
/// 것으로 보고, MedicineSearchResultPage를 register 모드로 열어 선택된 약 이름
/// 리스트를 이 페이지가 받아서 그대로 Navigator.pop으로 돌려줍니다.
/// (OcrEditPage가 List<String>을 await Navigator.push<List<String>>로 받는 기존
/// 구조와 호환됩니다.)
///
/// false(기본값)면 "정보 확인" 흐름(홈 화면 검색바 등)에서 열린 것으로 보고,
/// MedicineSearchResultPage를 info 모드로 엽니다. 이 경우 아무것도 pop하지 않습니다.
class MedicineSearchPage extends StatefulWidget {
  final bool isForRegistration;
  final UserProfile? userProfile;

  const MedicineSearchPage({
    super.key,
    this.isForRegistration = false,
    this.userProfile,
  });

  @override
  State<MedicineSearchPage> createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final searchController = TextEditingController();

  UserProfile get _profile => widget.userProfile ?? UserProfile.empty();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    _goToResultPage(query);
  }

  Future<void> _goToResultPage(String query) async {
    if (widget.isForRegistration) {
      // ✅ 등록 흐름: register 모드로 열고, 선택된 이름 리스트를 그대로 받아서
      // 이 페이지를 연 곳(OcrEditPage 등)에 다시 pop으로 전달
      final List<String>? selectedNames = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => MedicineSearchResultPage(
            query: query,
            mode: MedicineSearchMode.register,
            userProfile: _profile,
            onSelectionComplete: (names) => Navigator.pop(context, names),
          ),
        ),
      );
      if (selectedNames != null && selectedNames.isNotEmpty && mounted) {
        Navigator.pop(context, selectedNames);
      }
    } else {
      // ✅ 정보 확인 흐름: info 모드로 열기만 하면 됨
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicineSearchResultPage(
            query: query,
            mode: MedicineSearchMode.info,
            userProfile: _profile,
          ),
        ),
      );
    }
  }

  void _onSymptomBoxTap(String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineSearchInfoPage(symptomLabel: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ── 로고 + 제목 ────────────────────────
              const SizedBox(height: 10),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Image.asset(
                      'assets/images/medicare_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '약 검색',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 80),
                ],
              ),

              // ── 검색 박스 영역 ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [

                      // X 버튼
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black)),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            if (widget.isForRegistration)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  '등록할 약을 검색하거나, 증상에 맞는 약을 찾아보세요.',
                                  style: TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              ),

                            // ── 검색창 + 검색 버튼 ──────────────
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      onSubmitted: (_) => _onSearchSubmitted(),
                                      decoration: const InputDecoration(
                                        hintText: '약 이름 검색',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _onSearchSubmitted,
                                    child: Container(
                                      height: 60,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: const BoxDecoration(
                                        border: Border(left: BorderSide(color: Colors.black)),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text('검색', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 증상별 약 추천
                            const Text('증상별 약 추천', style: TextStyle(fontSize: 15)),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(child: _symptomBox('🤒', '감기 / 열')),
                                const SizedBox(width: 16),
                                Expanded(child: _symptomBox('🤕', '통증')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _symptomBox('🤢', '소화 / 위장')),
                                const SizedBox(width: 16),
                                Expanded(child: _symptomBox('🤧', '알레르기')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _symptomBox('🌙', '수면 / 피로')),
                                const SizedBox(width: 16),
                                Expanded(child: _symptomBox('🩹', '피부')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _symptomBox('🚨', '응급 증상', fullWidth: true),
                          ],
                        ),
                      ),
                    ],
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

  Widget _symptomBox(String emoji, String label, {bool fullWidth = false}) {
    return GestureDetector(
      onTap: () => _onSymptomBoxTap(label),
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
        ),
        alignment: Alignment.center,
        child: Text(
          '$emoji\n$label',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}