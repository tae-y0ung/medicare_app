import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController(); // ✅ 전화번호 추가
  final guardianController = TextEditingController();

  String gender = '';
  String pregnancy = '';
  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;
  bool passwordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    guardianController.dispose();
    super.dispose();
  }

  // ✅ 만 나이 계산
  int? get _koreanAge {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) return null;
    final now = DateTime.now();
    final birth = DateTime(
      int.parse(selectedYear!),
      int.parse(selectedMonth!),
      int.parse(selectedDay!),
    );
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1946년부터 올해까지
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1946 + 1,
      (i) => (1946 + i).toString(),
    );
    final months = List.generate(12, (i) => (i + 1).toString());
    final days = List.generate(31, (i) => (i + 1).toString());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Image.asset(
              'assets/images/medicare_logo.png',
              width: 120,
            ),

            const SizedBox(height: 24),

            // ── 로그인 정보 섹션 ───────────────────────
            _sectionContainer(
              title: '로그인 정보',
              required: true,
              children: [
                _labeledField(
                  label: '메일 주소',
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email@address.com',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _labeledField(
                  label: '비밀번호',
                  child: TextField(
                    controller: passwordController,
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 개인 정보 섹션 ─────────────────────────
            _sectionContainer(
              title: '개인 정보',
              required: true,
              children: [
                _labeledField(
                  label: '이름',
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: '이름 입력',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ 전화번호 추가
                _labeledField(
                  label: '전화번호',
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '010-0000-0000',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 생년월일
                _labeledField(
                  label: '생년월일',
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedYear,
                          hint: const Text('년도'),
                          items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setState(() => selectedYear = v),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedMonth,
                          hint: const Text('월'),
                          items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setState(() => selectedMonth = v),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDay,
                          hint: const Text('일'),
                          items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => selectedDay = v),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ 만 나이 표시
                if (_koreanAge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '만 $_koreanAge세',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // 성별
                _labeledField(
                  label: '성별',
                  child: Row(
                    children: [
                      Expanded(
                        child: _selectButton(
                          label: '남',
                          selected: gender == '남',
                          onTap: () => setState(() {
                            gender = '남';
                            pregnancy = '';
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _selectButton(
                          label: '여',
                          selected: gender == '여',
                          onTap: () => setState(() => gender = '여'),
                        ),
                      ),
                    ],
                  ),
                ),

                // 여성 선택 시에만 임신 여부 표시
                if (gender == '여') ...[
                  const SizedBox(height: 10),
                  _labeledField(
                    label: '임신',
                    child: Row(
                      children: [
                        Expanded(
                          child: _selectButton(
                            label: 'O',
                            selected: pregnancy == 'O',
                            onTap: () => setState(() => pregnancy = 'O'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _selectButton(
                            label: 'X',
                            selected: pregnancy == 'X',
                            onTap: () => setState(() => pregnancy = 'X'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // ── 보호자 연결 섹션 ──────────────────
            _sectionContainer(
              title: '보호자 연결',
              required: false,
              children: [
                TextField(
                  controller: guardianController,
                  decoration: const InputDecoration(
                    hintText: '보호자 전화번호 (선택)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  if (emailController.text.isEmpty) {
                    _showAlert('메일 주소를 입력해주세요.');
                    return;
                  }
                  if (passwordController.text.isEmpty) {
                    _showAlert('비밀번호를 입력해주세요.');
                    return;
                  }
                  if (nameController.text.isEmpty) {
                    _showAlert('이름을 입력해주세요.');
                    return;
                  }
                  if (phoneController.text.isEmpty) {
                    _showAlert('전화번호를 입력해주세요.');
                    return;
                  }
                  if (selectedYear == null || selectedMonth == null || selectedDay == null) {
                    _showAlert('생년월일을 선택해주세요.');
                    return;
                  }
                  if (gender.isEmpty) {
                    _showAlert('성별을 선택해주세요.');
                    return;
                  }
                  if (gender == '여' && pregnancy.isEmpty) {
                    _showAlert('임신 여부를 선택해주세요.');
                    return;
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '회원가입',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionContainer({
    required String title,
    required bool required,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (required)
                const Text(
                  '* 필수',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _selectButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}