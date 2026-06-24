import 'package:flutter/material.dart';
import 'medicine_search_info_page.dart';

class MedicineSearchPage extends StatefulWidget {
  const MedicineSearchPage({super.key});

  @override
  State<MedicineSearchPage> createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final searchController = TextEditingController();
  List<String> searchResults = [];

  // ✅ 다중 선택을 위한 상태 변수 추가
  final Set<String> _selectedMedicines = {};

  final List<String> _allMedicines = [
    '타이레놀', '이부프로펜', '아스피린', '판콜에이', '게보린',
    '지르텍', '부루펜', '베아제', '훼스탈', '우루사',
  ];

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        searchResults = [];
      } else {
        searchResults = _allMedicines
            .where((name) => name.contains(query))
            .toList();
      }
    });
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
                                      onChanged: _onSearchChanged,
                                      decoration: const InputDecoration(
                                        hintText: '약 이름 검색',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _onSearchChanged(searchController.text),
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

                            // ── 검색 결과 + 체크박스 ─────────────
                            if (searchResults.isNotEmpty)
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 60),
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
                                    final isChecked = _selectedMedicines.contains(name);
                                    // ✅ CheckboxListTile로 교체
                                    return CheckboxListTile(
                                      dense: true,
                                      secondary: const Icon(Icons.medication_outlined, size: 20),
                                      title: Text(name, style: const TextStyle(fontSize: 15)),
                                      value: isChecked,
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedMedicines.add(name);
                                          } else {
                                            _selectedMedicines.remove(name);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),

                            // ✅ 선택된 약이 있을 때 선택 완료 버튼 표시
                            if (_selectedMedicines.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                      context,
                                      _selectedMedicines.toList(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(
                                      '선택 완료 (${_selectedMedicines.length}개)',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
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