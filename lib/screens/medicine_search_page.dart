import 'package:flutter/material.dart';

class MedicineSearchPage extends StatefulWidget {
  const MedicineSearchPage({super.key});

  @override
  State<MedicineSearchPage> createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final searchController = TextEditingController();

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
                  const SizedBox(width: 80), // 로고 너비만큼 여백
                ],
              ),

              const SizedBox(height: 0),

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

                            // 검색창 + 검색 버튼
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
                                      decoration: const InputDecoration(
                                        hintText: '약 이름 검색',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // 검색 기능
                                    },
                                    child: Container(
                                      height: 60,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(color: Colors.black),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '검색',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 증상별 약 추천
                            const Text(
                              '증상별 약 추천',
                              style: TextStyle(fontSize: 15),
                            ),

                            const SizedBox(height: 16),

                            // 감기/열, 통증
                            Row(
                              children: [
                                Expanded(child: _symptomBox('🤒', '감기 / 열')),
                                const SizedBox(width: 16),
                                Expanded(child: _symptomBox('🤕', '통증')),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 소화/위장, 알레르기
                            Row(
                              children: [
                                Expanded(child: _symptomBox('🤢', '소화 / 위장')),
                                const SizedBox(width: 16),
                                Expanded(child: _symptomBox('🤧', '알레르기')),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 수면/피로, 피부
                            Row(
                              children: [
                                Expanded(child: _symptomBox('🌙', '수면 / 피로')),
                                const SizedBox(width: 16),
                                Expanded(child: _symptomBox('🩹', '피부')),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 응급 증상 (전체 너비)
                            _symptomBox('🚨', '응급 증상', fullWidth: true),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 등록하기 버튼 ──────────────────────
              SizedBox(
                width: 280,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {},
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
                    style: TextStyle(fontSize: 20),
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

  // 증상 버튼 위젯
  Widget _symptomBox(String emoji, String label, {bool fullWidth = false}) {
    return GestureDetector(
      onTap: () {
        // 증상 선택 기능
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