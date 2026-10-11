import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'user_profile.dart';
import '../services/api_service.dart';
import 'dart:async';

// ✅ 전화번호 자동 포맷터 (000-0000-0000)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digitsOnly.length > 11
        ? digitsOnly.substring(0, 11)
        : digitsOnly;
    String formatted;
    if (limited.length <= 3) {
      formatted = limited;
    } else if (limited.length <= 7) {
      formatted = '${limited.substring(0, 3)}-${limited.substring(3)}';
    } else {
      formatted =
          '${limited.substring(0, 3)}-${limited.substring(3, 7)}-${limited.substring(7)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
  final allergyController = TextEditingController();
  final List<String> allergyList = [];

  Timer? _ingredientDebounce;

  List<String> _ingredientSuggestions = [];

  bool _isSearchingIngredients = false;

  String? _selectedIngredient;

  String? _ingredientSearchError;

  int _ingredientRequestId = 0;

  String gender = '';
  String pregnancy = '';
  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;
  bool passwordVisible = false;
  bool isSigningUp = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    guardianController.dispose();
    _ingredientDebounce?.cancel();
    allergyController.dispose();
    super.dispose();
  }

  // ✅ 만 나이 계산
  int? get _koreanAge {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) {
      return null;
    }
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

  void _searchIngredient(String value) {
  _ingredientDebounce?.cancel();

  final requestId = ++_ingredientRequestId;
  final keyword = value.trim();

  setState(() {
    _selectedIngredient = null;
    _ingredientSuggestions = [];
    _ingredientSearchError = null;
    _isSearchingIngredients = false;
  });

  if (keyword.length < 2) return;

  _ingredientDebounce = Timer(
    const Duration(milliseconds: 350),
    () async {
      if (!mounted || requestId != _ingredientRequestId) {
        return;
      }

      setState(() {
        _isSearchingIngredients = true;
      });

      try {
        final result =
            await ApiService.searchIngredients(keyword);

        if (!mounted || requestId != _ingredientRequestId) {
          return;
        }

        setState(() {
          _ingredientSuggestions = result
              .where((name) => !allergyList.contains(name))
              .take(3)
              .toList();

          _isSearchingIngredients = false;
        });
      } catch (e) {
        if (!mounted || requestId != _ingredientRequestId) {
          return;
        }

        setState(() {
          _ingredientSuggestions = [];
          _isSearchingIngredients = false;
          _ingredientSearchError = '성분 검색에 실패했습니다.';
        });

        debugPrint('회원가입 성분 검색 실패: $e');
      }
    },
  );
}

void _selectIngredient(String ingredient) {
  _ingredientDebounce?.cancel();
  _ingredientRequestId++;

  setState(() {
    allergyController.text = ingredient;
    allergyController.selection =
        TextSelection.collapsed(
      offset: ingredient.length,
    );

    _selectedIngredient = ingredient;
    _ingredientSuggestions = [];
    _ingredientSearchError = null;
    _isSearchingIngredients = false;
  });
}

  void _addAllergy() {
  final allergy = allergyController.text.trim();

  if (allergy.isEmpty) {
    return;
  }

  if (_selectedIngredient != allergy) {
    _showAlert('검색 결과에서 정확한 성분명을 선택해주세요.');
    return;
  }

  if (allergyList.contains(allergy)) {
    _showAlert('이미 등록된 알레르기입니다.');
    return;
  }

  _ingredientDebounce?.cancel();
  _ingredientRequestId++;

  setState(() {
    allergyList.add(allergy);
    allergyController.clear();

    _selectedIngredient = null;
    _ingredientSuggestions = [];
    _ingredientSearchError = null;
    _isSearchingIngredients = false;
  });
}

  void _removeAllergy(String allergy) {
    setState(() {
      allergyList.remove(allergy);
    });
  }

  Future<void> _signUp() async {
    // 1. 입력값 검사
    if (emailController.text.trim().isEmpty) {
      _showAlert('메일 주소를 입력해주세요.');
      return;
    }

    if (passwordController.text.isEmpty) {
      _showAlert('비밀번호를 입력해주세요.');
      return;
    }

    if (nameController.text.trim().isEmpty) {
      _showAlert('이름을 입력해주세요.');
      return;
    }

    if (phoneController.text.trim().isEmpty) {
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

    try {
      setState(() {
        isSigningUp = true;
      });

      // 2. FastAPI 회원가입 API 호출
      final result = await ApiService.createUser(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        gender: gender,
        pregnancy: gender == '여' ? pregnancy : '',
        birthYear: selectedYear!,
        birthMonth: selectedMonth!,
        birthDay: selectedDay!,
        allergyList: List<String>.from(allergyList),
        guardianPhone: guardianController.text.trim(),
      );

      debugPrint('회원가입 결과: $result');

      if (!mounted) return;

      // 3. 서버에서 회원가입 실패를 반환한 경우
      if (result['success'] == false) {
        _showAlert(result['message']?.toString() ?? '회원가입에 실패했습니다.');
        return;
      }

      final createdUser = Map<String, dynamic>.from(result['user'] ?? {});

      final profile = UserProfile(
        userId: (result['userId'] ?? createdUser['userId'] ?? '').toString(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        gender: gender,
        pregnancy: gender == '여' ? pregnancy : '',
        birthYear: selectedYear!,
        birthMonth: selectedMonth!,
        birthDay: selectedDay!,
        guardianPhone: guardianController.text.trim(),
      );

      // 5. 회원가입 성공 후 홈으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
      );
    } catch (e) {
      debugPrint('회원가입 중 오류: $e');

      if (!mounted) return;

      _showAlert('회원가입 중 오류가 발생했습니다.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          isSigningUp = false;
        });
      }
    }
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
            Image.asset('assets/images/medicare_logo.png', width: 120),

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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ 전화번호 추가 (자동 포맷 000-0000-0000)
                _labeledField(
                  label: '전화번호',
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_PhoneNumberFormatter()],
                    decoration: const InputDecoration(
                      hintText: '010-0000-0000',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                          items: years
                              .map(
                                (y) =>
                                    DropdownMenuItem(value: y, child: Text(y)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedYear = v),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedMonth,
                          hint: const Text('월'),
                          items: months
                              .map(
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedMonth = v),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDay,
                          hint: const Text('일'),
                          items: days
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedDay = v),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
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

            // ── 복약 안전 정보 ─────────────────
            _sectionContainer(
              title: '복약 안전 정보',
              required: false,
              children: [
                const Text(
                  '알레르기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 6),

                const Text(
                  '약 성분 알레르기가 있다면 '
                  '등록해주세요. '
                  '의약품 추천 및 안전 검사에 '
                  '사용됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 12),

                // =================================
// 알레르기 성분 입력 + API 자동완성
// =================================
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: allergyController,
              textInputAction: TextInputAction.done,
              onChanged: _searchIngredient,
              onSubmitted: (_) => _addAllergy(),
              decoration: InputDecoration(
                hintText: '알레르기 성분명 입력',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _isSearchingIngredients
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 8),

          OutlinedButton(
            onPressed: _addAllergy,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    ),

    // API 검색 결과 최대 3개
    if (_ingredientSuggestions.isNotEmpty)
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: _ingredientSuggestions.take(3).map((ingredient) {
            return ListTile(
              dense: true,
              title: Text(
                ingredient,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(
                Icons.north_west,
                size: 16,
                color: Colors.black54,
              ),
              onTap: () => _selectIngredient(ingredient),
            );
          }).toList(),
        ),
      ),

    if (_ingredientSearchError != null)
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          _ingredientSearchError!,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.redAccent,
          ),
        ),
      ),

    const Padding(
      padding: EdgeInsets.only(left: 12, top: 6),
      child: Text(
        '2글자 이상 입력하면 성분명이 추천됩니다.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    ),
  ],
),


                if (allergyList.isNotEmpty) ...[
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allergyList.map((allergy) {
                      return InputChip(
                        label: Text(allergy),
                        onDeleted: () => _removeAllergy(allergy),
                        deleteIcon: const Icon(Icons.close, size: 17),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 6),

                const Text(
                  '알레르기가 없다면 '
                  '입력하지 않아도 됩니다.',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
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
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    _PhoneNumberFormatter(),
                  ], // ✅ 보호자 번호도 동일하게 포맷
                  decoration: const InputDecoration(
                    hintText: '보호자 전화번호 입력 (선택)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: isSigningUp ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: isSigningUp
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
