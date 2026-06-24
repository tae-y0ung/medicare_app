import 'package:flutter/material.dart';
import 'medicine_search_info_page.dart';
import 'medicine_search_result_page.dart';

class MedicineSearchPage extends StatefulWidget {
  const MedicineSearchPage({super.key});

  @override
  State<MedicineSearchPage> createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final searchController = TextEditingController();
  List<String> searchResults = [];

  final List<String> _allMedicines = [
    '타이레놀', '이부프로펜', '아스피린', '판콜에이', '게보린',
    '지르텍', '부루펜', '베아제', '훼스탈', '우루사',
  ];

  void _onSearchChanged(String query) {
    setState(() {
      searchResults = query.isEmpty
          ? []
          : _allMedicines.where((name) => name.contains(query)).toList();
    });
  }

  // 검색 실행 → info 모드로 결과 페이지 이동
  void _goToResult(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineSearchResultPage(
          query: query.trim(),
          mode: MedicineSearchMode.info, // ✅ 정보 확인 모드
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

                            // ── 검색창 ────────────────────────────
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
                                      onChanged: _onSearchChanged,
                                      onSubmitted: _goToResult, // 키보드 검색 키
                                      textInputAction: TextInputAction.search,
                                      decoration: const InputDecoration(
                                        hintText: '약 이름 검색',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _goToResult(searchController.text),
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

                            // ── 자동완성 드롭다운 (체크박스 없음) ──
                            if (searchResults.isNotEmpty)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                  color: Colors.grey[50],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: searchResults.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final name = searchResults[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.medication_outlined, size: 20),
                                      title: Text(name, style: const TextStyle(fontSize: 15)),
                                      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                                      onTap: () => _goToResult(name), // ✅ 탭하면 바로 결과 페이지
                                    );
                                  },
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineSearchInfoPage(symptomLabel: label),
          ),
        );
      },
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