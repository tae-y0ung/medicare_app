import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_search_page.dart';

class GuardianAccountPage extends StatefulWidget {
  final String initialGuardianEmail; // 회원가입 때 입력한 보호자 이메일

  const GuardianAccountPage({
    super.key,
    this.initialGuardianEmail = '', // 기본값은 빈 문자열
  });

  @override
  State<GuardianAccountPage> createState() => _GuardianAccountPageState();
}

class _GuardianAccountPageState extends State<GuardianAccountPage> {
  final emailController = TextEditingController();
  late List<Map<String, dynamic>> connectedAccounts;

  String get _todayLabel {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[now.weekday - 1];
    return '${formatter.format(now)} $weekday';
  }

  @override
  void initState() {
    super.initState();
    // ✅ 회원가입 때 입력한 보호자 이메일이 있으면 초기 목록에 추가
    connectedAccounts = [];
    if (widget.initialGuardianEmail.isNotEmpty) {
      connectedAccounts.add({
        'email': widget.initialGuardianEmail,
        'checked': true,
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // ── 상단 영역 (홈과 동일) ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [

                  // 로고 + 날짜 + 아이콘
                  Row(
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
                            _todayLabel,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.black),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 약 검색 바
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicineSearchPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 12),
                          Icon(Icons.search, color: Colors.black, size: 22),
                          SizedBox(width: 8),
                          Text('약 검색', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── 보호자 계정 연결 영역 ──────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0x4CD9D9D9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [

                    const SizedBox(height: 10),

                    const Text(
                      '보호자 계정 연결',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 10),

                    // 이메일 입력 + 완료 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: Row(
                          children: [

                            // 이메일 입력
                            Expanded(
                              child: TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  hintText: '보호자 계정 Email 입력',
                                  border: InputBorder.none,
                                  isDense: true,
                                  fillColor: Color(0xFFF5F5F5),
                                  filled: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),

                            // 완료 버튼
                            GestureDetector(
                              onTap: () {
                                if (emailController.text.isNotEmpty) {
                                  setState(() {
                                    connectedAccounts.add({
                                      'email': emailController.text,
                                      'checked': true,
                                    });
                                    emailController.clear();
                                  });
                                }
                              },
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  border: Border(
                                    left: BorderSide(color: Colors.black),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text('완료', style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // 연결된 계정 목록
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 0, 5),
                                child: Text(
                                  '연결된 계정 확인',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),

                              // 계정 목록
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  itemCount: connectedAccounts.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final account = connectedAccounts[index];
                                    return Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD5D5D5),
                                        border: Border.all(color: Colors.black),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              account['email'],
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          Checkbox(
                                            value: account['checked'],
                                            onChanged: (v) {
                                              setState(() {
                                                connectedAccounts[index]['checked'] = v!;
                                              });
                                            },
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── 보호자 계정 삭제 버튼 ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  onPressed: () {
                    // 체크된 계정 삭제
                    setState(() {
                      connectedAccounts.removeWhere((a) => a['checked'] == true);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text('보호자 계정 삭제', style: TextStyle(fontSize: 17)),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── 보호자 계정 추가 완료 버튼 ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ 홈으로 돌아가기
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text('보호자 계정 추가 완료', style: TextStyle(fontSize: 17)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 처방전 등록 버튼 ───────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: 250,
                height: 60,
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
                  child: const Text('+ 처방전 등록', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}