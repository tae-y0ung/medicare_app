import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'user_profile.dart';
import 'login_page.dart';

// ──────────────────────────────────────────────────────────────────────────────
class SettingScreen extends StatefulWidget {
  /// 회원가입 때 입력한 데이터를 그대로 전달받습니다.
  final UserProfile profile;

  const SettingScreen({super.key, required this.profile});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // ── 컨트롤러 (초기값 = 전달받은 프로필) ──────────────────────────────────────
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _phoneController;
  final TextEditingController _guardianPhoneController = TextEditingController();

  bool _passwordVisible = false;
  bool _isEditing = false;

  // 편집 가능한 필드들 (수정 취소 시 원복을 위해 별도 관리)
  late String _gender;
  late String _pregnancy;
  late String? _selectedYear;
  late String? _selectedMonth;
  late String? _selectedDay;

  // 수정 시작 시점의 스냅샷 (취소 용도)
  late String _snapGender;
  late String _snapPregnancy;
  late String? _snapYear;
  late String? _snapMonth;
  late String? _snapDay;

  // 보호자 목록
  late List<Map<String, dynamic>> _guardians;

  // 드롭다운 데이터
  final List<String> _years = List.generate(
    DateTime.now().year - 1946 + 1,
    (i) => (1946 + i).toString(),
  );
  final List<String> _months = List.generate(12, (i) => (i + 1).toString());
  final List<String> _days   = List.generate(31, (i) => (i + 1).toString());

  // ── 만 나이 계산 ────────────────────────────────────────────────────────────
  int? get _calculatedAge {
    if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) {
      return null;
    }
    final now   = DateTime.now();
    final birth = DateTime(
      int.parse(_selectedYear!),
      int.parse(_selectedMonth!),
      int.parse(_selectedDay!),
    );
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  String get _todayLabel {
    final now       = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays  = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${formatter.format(now)} ${weekdays[now.weekday - 1]}';
  }

  // ── 초기화 ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');

    final p = widget.profile;
    _nameController  = TextEditingController(text: p.name);
    _emailController = TextEditingController(text: p.email);
    _phoneController = TextEditingController(text: p.phone);

    _gender        = p.gender;
    _pregnancy     = p.pregnancy;
    _selectedYear  = p.birthYear.isNotEmpty  ? p.birthYear  : null;
    _selectedMonth = p.birthMonth.isNotEmpty ? p.birthMonth : null;
    _selectedDay   = p.birthDay.isNotEmpty   ? p.birthDay   : null;

    _guardians = p.guardianPhone.isNotEmpty
        ? [{'phone': p.guardianPhone, 'connected': true}]
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  // ── 수정 모드 진입 (스냅샷 저장) ────────────────────────────────────────────
  void _startEditing() {
    _snapGender    = _gender;
    _snapPregnancy = _pregnancy;
    _snapYear      = _selectedYear;
    _snapMonth     = _selectedMonth;
    _snapDay       = _selectedDay;
    setState(() => _isEditing = true);
  }

  // ── 완료 (저장) ─────────────────────────────────────────────────────────────
  void _completeEditing() {
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('개인정보가 저장되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── 취소 (원복) ─────────────────────────────────────────────────────────────  ← 여기 추가
  void _cancelEditing() {
    setState(() {
      _gender        = _snapGender;
      _pregnancy     = _snapPregnancy;
      _selectedYear  = _snapYear;
      _selectedMonth = _snapMonth;
      _selectedDay   = _snapDay;
      _isEditing     = false;
    });
  }

  // ── 공통 다이얼로그 ─────────────────────────────────────────────────────────
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteGuardianDialog(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text('${_guardians[index]['phone']} 보호자를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _guardians.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _addGuardian() {
    final phone = _guardianPhoneController.text.trim();
    if (phone.isEmpty) {
      _showAlert('보호자 전화번호를 입력해주세요.');
      return;
    }
    setState(() {
      _guardians.add({'phone': phone, 'connected': false});
      _guardianPhoneController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('보호자 계정 추가 완료')),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 (홈 화면과 동일 스타일) ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        _todayLabel,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 설정 타이틀 바 ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border.all(color: Colors.black),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '설정',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── 본문 ─────────────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft:  Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── 개인정보 수정 ────────────────────────────────────
                            _sectionTitle('개인정보 수정'),
                            const SizedBox(height: 10),

                      // 이름
                      _infoField(
                        label: '이름',
                        child: _isEditing
                            ? _editTextField(_nameController, '이름 입력')
                            : _readonlyBox(_nameController.text),
                      ),
                      const SizedBox(height: 8),

                      // 생년월일 / 나이
                      _infoField(
                        label: '생년월일',
                        child: _isEditing
                            ? _birthDateSelector()
                            : _readonlyBox(
                                _calculatedAge != null
                                    ? '만 $_calculatedAge세'
                                    : '미입력',
                              ),
                      ),
                      // 수정 모드에서 만 나이 보조 표시
                      if (_isEditing && _calculatedAge != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 2),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '만 $_calculatedAge세',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // 성별
                      _infoField(
                        label: '성별',
                        child: _isEditing
                            ? _genderSelector()
                            : _readonlyBox(_gender),
                      ),
                      const SizedBox(height: 8),

                      // 임신 여부 (여성 + 수정 모드일 때만)
                      if (_gender == '여') ...[
                        _infoField(
                          label: '임신',
                          child: _isEditing
                              ? _pregnancySelector()
                              : _readonlyBox(
                                  _pregnancy.isNotEmpty ? _pregnancy : '-',
                                ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // 메일 주소
                      _infoField(
                        label: '메일 주소',
                        child: _isEditing
                            ? _editTextField(
                                _emailController,
                                'Email@address.com',
                                keyboardType: TextInputType.emailAddress,
                              )
                            : _readonlyBox(_emailController.text),
                      ),
                      const SizedBox(height: 8),

                      // 비밀번호
                      _infoField(
                        label: '비밀번호',
                        child: _isEditing
                            ? _passwordField()
                            : _readonlyBox('••••••••'),
                      ),
                      const SizedBox(height: 8),

                      // 전화번호
                      _infoField(
                        label: '전화번호',
                        child: _isEditing
                            ? _editTextField(
                                _phoneController,
                                '010-0000-0000',
                                keyboardType: TextInputType.phone,
                              )
                            : _readonlyBox(_phoneController.text),
                      ),
                      const SizedBox(height: 12),

                      // 수정 버튼  ↔  완료 버튼
                      Align(
                        alignment: Alignment.centerRight,
                        child: _isEditing
                            ? Row(                          // ← 이 부분 교체
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _outlineButton(
                                    label: '취소',
                                    onPressed: _cancelEditing,
                                  ),
                                  const SizedBox(width: 8),
                                  _outlineButton(
                                    label: '완료',
                                    onPressed: _completeEditing,
                                    bold: true,
                                  ),
                                ],
                              )
                            : _outlineButton(
                                label: '수정',
                                onPressed: _startEditing,
                              ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 12),

                      // ── 보호자 등록/수정 ──────────────────────────────────
                      _sectionTitle('보호자 등록/수정'),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _editTextField(
                              _guardianPhoneController,
                              '보호자 전화번호 입력',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _outlineButton(
                            label: '추가 완료',
                            onPressed: _addGuardian,
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),

                      if (_guardians.isNotEmpty) ...[
                        const Text(
                          '연결된 계정 확인',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        ..._guardians.asMap().entries.map(
                          (e) => _guardianRow(e.key, e.value),
                        ),
                      ] else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: const Text(
                            '연결된 보호자가 없습니다.',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ),

                      const SizedBox(height: 60),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 12),

                      // ── 로그아웃 ─────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _showLogoutDialog,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            '로그아웃',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
             ],
            ),
           ),
          ),
        ],
      ),
     ),
    );
   }

  // ── 생년월일 드롭다운 (회원가입과 동일 스타일) ────────────────────────────────
  Widget _birthDateSelector() {
    final dropDecoration = const InputDecoration(
      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedYear,
            hint: const Text('년도', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            decoration: dropDecoration,
            items: _years
                .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                .toList(),
            onChanged: (v) => setState(() => _selectedYear = v),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedMonth,
            hint: const Text('월', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            decoration: dropDecoration,
            items: _months
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMonth = v),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDay,
            hint: const Text('일', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            decoration: dropDecoration,
            items: _days
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDay = v),
          ),
        ),
      ],
    );
  }

  // ── 헬퍼 위젯들 ────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  Widget _infoField({required String label, required Widget child}) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(child: child),
        ],
      );

  Widget _readonlyBox(String text) => Container(
        width: double.infinity,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
        ),
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 14)),
      );

  Widget _editTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _passwordField() => TextField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          hintText: '새 비밀번호 입력',
          border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.black54,
            ),
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          ),
        ),
      );

  Widget _genderSelector() => Row(
        children: [
          Expanded(
            child: _toggleButton(
              label: '남',
              selected: _gender == '남',
              onTap: () => setState(() {
                _gender = '남';
                _pregnancy = '';
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _toggleButton(
              label: '여',
              selected: _gender == '여',
              onTap: () => setState(() => _gender = '여'),
            ),
          ),
        ],
      );

  Widget _pregnancySelector() => Row(
        children: [
          Expanded(
            child: _toggleButton(
              label: 'O',
              selected: _pregnancy == 'O',
              onTap: () => setState(() => _pregnancy = 'O'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _toggleButton(
              label: 'X',
              selected: _pregnancy == 'X',
              onTap: () => setState(() => _pregnancy = 'X'),
            ),
          ),
        ],
      );

  Widget _toggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
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

  Widget _guardianRow(int index, Map<String, dynamic> guardian) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                guardian['phone'] as String,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Theme(
              data: ThemeData(
                checkboxTheme: CheckboxThemeData(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
              child: Checkbox(
                value: guardian['connected'] as bool,
                onChanged: null,
                activeColor: Colors.green,
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.black54),
              visualDensity: VisualDensity.compact,
              onPressed: () => _showDeleteGuardianDialog(index),
            ),
          ],
        ),
      );

  Widget _outlineButton({
    required String label,
    required VoidCallback onPressed,
    bool bold = false,
  }) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
}