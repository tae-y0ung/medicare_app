import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_page.dart';
import 'user_profile.dart';
import '../services/api_service.dart';

// 전화번호 자동 포맷터: 010-0000-0000
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

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
  // ─────────────────────────────────────────────
  // 입력 컨트롤러
  // ─────────────────────────────────────────────
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final guardianController = TextEditingController();
  final allergyController = TextEditingController();
  final verificationCodeController = TextEditingController();

  // ─────────────────────────────────────────────
  // 알레르기 검색 상태
  // ─────────────────────────────────────────────
  final List<String> allergyList = [];

  Timer? _ingredientDebounce;
  List<String> _ingredientSuggestions = [];

  bool _isSearchingIngredients = false;
  String? _selectedIngredient;
  String? _ingredientSearchError;
  int _ingredientRequestId = 0;

  // ─────────────────────────────────────────────
  // 사용자 정보
  // ─────────────────────────────────────────────
  String gender = '';
  String pregnancy = '';

  String? selectedYear;
  String? selectedMonth;
  String? selectedDay;

  bool passwordVisible = false;
  bool isSigningUp = false;

  // ─────────────────────────────────────────────
  // 이메일 인증 상태
  // ─────────────────────────────────────────────
  bool isSendingVerification = false;
  bool isVerifyingEmail = false;
  bool hasSentVerification = false;
  bool isEmailVerified = false;

  String? verificationToken;
  String? verificationEmail;

  int resendSeconds = 0;
  Timer? _resendTimer;

  // 디자인 색상: 로그인 및 홈 화면과 통일
  static const Color primaryColor = Color(0xFF29272D);
  static const Color borderColor = Color(0xFFD8D5DA);
  static const Color textColor = Color(0xFF29272F);
  static const Color inputColor = Color(0xFFFFFFFF);
  static const Color iconColor = Color(0xFF454149);

  static const Color softPurple = Color(0xFFF3F3F3);
  static const Color backgroundColor = Color(0xFFFFFFFF);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    guardianController.dispose();
    allergyController.dispose();
    verificationCodeController.dispose();

    _ingredientDebounce?.cancel();
    _resendTimer?.cancel();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // 만 나이 계산
  // ─────────────────────────────────────────────
  int? get _koreanAge {
    if (selectedYear == null || selectedMonth == null || selectedDay == null) {
      return null;
    }

    final year = int.tryParse(selectedYear!);
    final month = int.tryParse(selectedMonth!);
    final day = int.tryParse(selectedDay!);

    if (year == null || month == null || day == null) return null;

    final birth = DateTime(year, month, day);

    // DateTime이 잘못된 날짜를 다음 달로 보정하는 경우 방지
    if (birth.year != year || birth.month != month || birth.day != day) {
      return null;
    }

    final now = DateTime.now();
    var age = now.year - birth.year;

    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }

    return age >= 0 ? age : null;
  }

  // ─────────────────────────────────────────────
  // 알레르기 성분 검색
  // ─────────────────────────────────────────────
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

    _ingredientDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || requestId != _ingredientRequestId) return;

      setState(() {
        _isSearchingIngredients = true;
      });

      try {
        final result = await ApiService.searchIngredients(keyword);

        if (!mounted || requestId != _ingredientRequestId) return;

        setState(() {
          _ingredientSuggestions = result
              .where((name) => !allergyList.contains(name))
              .take(3)
              .toList();

          _isSearchingIngredients = false;
        });
      } catch (e) {
        if (!mounted || requestId != _ingredientRequestId) return;

        setState(() {
          _ingredientSuggestions = [];
          _isSearchingIngredients = false;
          _ingredientSearchError = '성분 검색에 실패했습니다.';
        });

        debugPrint('회원가입 성분 검색 실패: $e');
      }
    });
  }

  void _selectIngredient(String ingredient) {
    _ingredientDebounce?.cancel();
    _ingredientRequestId++;

    setState(() {
      allergyController.text = ingredient;
      allergyController.selection = TextSelection.collapsed(
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

    if (allergy.isEmpty) return;

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

  // ─────────────────────────────────────────────
  // 이메일 인증
  // ─────────────────────────────────────────────

  // 이메일 변경 시 이전 인증 결과 초기화
  void _resetEmailVerification() {
    _resendTimer?.cancel();

    setState(() {
      hasSentVerification = false;
      isEmailVerified = false;
      verificationToken = null;
      verificationEmail = null;
      resendSeconds = 0;
      verificationCodeController.clear();
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() {
      resendSeconds = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() {
          resendSeconds = 0;
        });
      } else {
        setState(() {
          resendSeconds--;
        });
      }
    });
  }

  Future<void> _sendVerificationCode() async {
    if (isSendingVerification ||
        isVerifyingEmail ||
        resendSeconds > 0 ||
        isEmailVerified) {
      return;
    }

    final email = emailController.text.trim().toLowerCase();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showAlert('올바른 이메일 주소를 입력해주세요.');
      return;
    }

    setState(() {
      isSendingVerification = true;
    });

    try {
      await ApiService.sendEmailVerification(email);

      if (!mounted) return;

      // 발송 도중 이메일이 변경된 경우 인증 상태를 설정하지 않음
      if (emailController.text.trim().toLowerCase() != email) return;

      setState(() {
        hasSentVerification = true;
        isEmailVerified = false;
        verificationToken = null;
        verificationEmail = email;
        verificationCodeController.clear();
      });

      _startResendTimer();
      _showAlert('인증번호를 이메일로 발송했습니다.');
    } catch (e) {
      if (!mounted) return;
      _showAlert(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSendingVerification = false;
        });
      }
    }
  }

  Future<void> _verifyEmail() async {
    if (isVerifyingEmail || !hasSentVerification) return;

    final email = emailController.text.trim().toLowerCase();
    final code = verificationCodeController.text.trim();

    if (verificationEmail != email) {
      _showAlert('이메일이 변경되었습니다. 인증번호를 다시 발송해주세요.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showAlert('6자리 인증번호를 입력해주세요.');
      return;
    }

    setState(() {
      isVerifyingEmail = true;
    });

    try {
      final result = await ApiService.verifyEmailCode(email: email, code: code);

      if (!mounted) return;

      if (emailController.text.trim().toLowerCase() != email) return;

      final token = (result['verificationToken'] ?? '').toString();

      if (token.isEmpty) {
        throw Exception('이메일 인증 토큰을 받지 못했습니다.');
      }

      _resendTimer?.cancel();

      setState(() {
        verificationToken = token;
        verificationEmail = email;
        isEmailVerified = true;
        resendSeconds = 0;
      });

      _showAlert('이메일 인증이 완료되었습니다.');
    } catch (e) {
      if (!mounted) return;
      _showAlert(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isVerifyingEmail = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // 회원가입 처리
  // ─────────────────────────────────────────────
  Future<void> _signUp() async {
    if (isSigningUp) return;

    if (emailController.text.trim().isEmpty) {
      _showAlert('메일 주소를 입력해주세요.');
      return;
    }

    if (!isEmailVerified ||
        verificationToken == null ||
        verificationEmail != emailController.text.trim().toLowerCase()) {
      _showAlert('이메일 인증을 먼저 완료해주세요.');
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

    if (_koreanAge == null) {
      _showAlert('올바른 생년월일을 선택해주세요.');
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

    setState(() {
      isSigningUp = true;
    });

    try {
      final result = await ApiService.createUser(
        email: emailController.text.trim().toLowerCase(),
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
        verificationToken: verificationToken!,
      );

      debugPrint('회원가입 결과: $result');

      if (!mounted) return;

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

  // ─────────────────────────────────────────────
  // 화면 디자인
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    final years = List.generate(
      currentYear - 1946 + 1,
      (i) => (1946 + i).toString(),
    );

    final months = List.generate(12, (i) => (i + 1).toString());

    final daysInMonth = selectedYear != null && selectedMonth != null
        ? DateTime(
            int.parse(selectedYear!),
            int.parse(selectedMonth!) + 1,
            0,
          ).day
        : 31;

    final days = List.generate(daysInMonth, (i) => (i + 1).toString());

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: backgroundColor),
            ),
          ),

          Positioned(
            top: -125,
            left: -115,
            child: Container(
              width: 300,
              height: 240,
              decoration: BoxDecoration(
                color: softPurple.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(180),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -145,
            right: -120,
            child: Container(
              width: 320,
              height: 260,
              decoration: BoxDecoration(
                color: softPurple.withOpacity(0.75),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(180),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 로고
                      Center(
                        child: Image.asset(
                          'assets/images/medicare_logo.png',
                          width: 220,
                          height: 175,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 메인 카드
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.09),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 43,
                                  height: 43,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F1F1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '회원가입',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        '복약 안전을 위한 정보를 입력해주세요.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            _sectionTitle('로그인 정보', required: true),

                            const SizedBox(height: 14),

                            _fieldLabel('이메일 주소'),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: emailController,
                                    enabled: !isSigningUp,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    onChanged: (_) => _resetEmailVerification(),
                                    decoration: _decoration(
                                      '이메일 주소',
                                      Icons.mail_outline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed:
                                        isSigningUp ||
                                            isEmailVerified ||
                                            isSendingVerification ||
                                            isVerifyingEmail ||
                                            resendSeconds > 0
                                        ? null
                                        : _sendVerificationCode,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: const BorderSide(
                                        color: borderColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      isEmailVerified
                                          ? '인증 완료'
                                          : isSendingVerification
                                          ? '발송 중'
                                          : resendSeconds > 0
                                          ? '${resendSeconds}초'
                                          : hasSentVerification
                                          ? '재발송'
                                          : '인증하기',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (hasSentVerification && !isEmailVerified) ...[
                              const SizedBox(height: 10),
                              _fieldLabel('인증번호'),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: verificationCodeController,
                                      enabled: !isSigningUp,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _decoration(
                                        '인증번호 6자리',
                                        Icons.verified_user_outlined,
                                      ).copyWith(counterText: ''),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed:
                                          isSigningUp ||
                                              isVerifyingEmail ||
                                              isSendingVerification
                                          ? null
                                          : _verifyEmail,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: const BorderSide(
                                          color: borderColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isVerifyingEmail ? '확인 중' : '확인',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '인증번호는 발송 후 5분간 유효합니다.',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],

                            if (isEmailVerified) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F8F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '이메일 인증이 완료되었습니다.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            _fieldLabel('비밀번호'),

                            TextField(
                              controller: passwordController,
                              enabled: !isSigningUp,
                              obscureText: !passwordVisible,
                              decoration:
                                  _decoration(
                                    '비밀번호',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          passwordVisible = !passwordVisible;
                                        });
                                      },
                                      icon: Icon(
                                        passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                            ),

                            const SizedBox(height: 24),

                            _sectionTitle('개인 정보', required: true),

                            const SizedBox(height: 14),

                            _fieldLabel('이름'),

                            TextField(
                              controller: nameController,
                              enabled: !isSigningUp,
                              textCapitalization: TextCapitalization.words,
                              decoration: _decoration(
                                '이름을 입력해주세요',
                                Icons.person_outline,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _fieldLabel('전화번호'),

                            TextField(
                              controller: phoneController,
                              enabled: !isSigningUp,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_PhoneNumberFormatter()],
                              decoration: _decoration(
                                '010-0000-0000',
                                Icons.phone_outlined,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _fieldLabel('생년월일'),

                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _dropdown(
                                    hint: '년도',
                                    value: selectedYear,
                                    values: years,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedYear = value;
                                        selectedDay = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  flex: 3,
                                  child: _dropdown(
                                    hint: '월',
                                    value: selectedMonth,
                                    values: months,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedMonth = value;
                                        selectedDay = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  flex: 3,
                                  child: _dropdown(
                                    hint: '일',
                                    value: selectedDay,
                                    values: days,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedDay = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            if (_koreanAge != null) ...[
                              const SizedBox(height: 7),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '만 $_koreanAge세',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            _fieldLabel('성별'),

                            Row(
                              children: [
                                Expanded(
                                  child: _choiceButton(
                                    label: '남성',
                                    selected: gender == '남',
                                    onTap: () {
                                      setState(() {
                                        gender = '남';
                                        pregnancy = '';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _choiceButton(
                                    label: '여성',
                                    selected: gender == '여',
                                    onTap: () {
                                      setState(() {
                                        gender = '여';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            if (gender == '여') ...[
                              const SizedBox(height: 16),
                              _fieldLabel('임신 여부'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _choiceButton(
                                      label: '아니요',
                                      selected: pregnancy == 'X',
                                      onTap: () {
                                        setState(() {
                                          pregnancy = 'X';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _choiceButton(
                                      label: '예',
                                      selected: pregnancy == 'O',
                                      onTap: () {
                                        setState(() {
                                          pregnancy = 'O';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 26),

                            _sectionTitle('복약 안전 정보', required: false),

                            const SizedBox(height: 10),

                            _fieldLabel('알레르기 성분'),

                            const Text(
                              '알레르기가 있는 약 성분을 검색해 추가해주세요. ',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: textColor,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: allergyController,
                                    enabled: !isSigningUp,
                                    textInputAction: TextInputAction.done,
                                    onChanged: _searchIngredient,
                                    onSubmitted: (_) => _addAllergy(),
                                    decoration:
                                        _decoration(
                                          '알레르기 성분 검색',
                                          Icons.search,
                                        ).copyWith(
                                          suffixIcon: _isSearchingIngredients
                                              ? const Padding(
                                                  padding: EdgeInsets.all(14),
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: isSigningUp ? null : _addAllergy,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: const BorderSide(
                                        color: borderColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text('추가'),
                                  ),
                                ),
                              ],
                            ),

                            if (_ingredientSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: _ingredientSuggestions
                                      .take(3)
                                      .map(
                                        (ingredient) => ListTile(
                                          dense: true,
                                          leading: const Icon(
                                            Icons.medication_outlined,
                                            color: iconColor,
                                          ),
                                          title: Text(
                                            ingredient,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.add_circle_outline,
                                            color: primaryColor,
                                          ),
                                          onTap: () =>
                                              _selectIngredient(ingredient),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],

                            if (_ingredientSearchError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _ingredientSearchError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],

                            if (allergyList.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allergyList.map((allergy) {
                                  return InputChip(
                                    label: Text(
                                      allergy,
                                      style: const TextStyle(
                                        color: Color(0xFF6552A3),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFFF2EEFF),
                                    side: const BorderSide(
                                      color: Color(0xFFDCD1FA),
                                      width: 1,
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF8975D1),
                                    ),
                                    onDeleted: () => _removeAllergy(allergy),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            const SizedBox(height: 8),

                            const Text(
                              '알레르기가 없다면 비워두셔도 됩니다. '
                              '성분은 검색 결과에서 선택해야 추가할 수 있습니다.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: textColor,
                              ),
                            ),

                            const SizedBox(height: 24),

                            _sectionTitle('보호자 연결', required: false),

                            const SizedBox(height: 8),

                            const Text(
                              '보호자 전화번호를 입력하면 보호자 연결에 사용할 수 있습니다.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: textColor,
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: guardianController,
                              enabled: !isSigningUp,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_PhoneNumberFormatter()],
                              decoration: _decoration(
                                '보호자 전화번호 (선택)',
                                Icons.phone_in_talk_outlined,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // 회원가입 버튼
                            SizedBox(
                              height: 62,
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.16),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),

                                child: ElevatedButton(
                                  onPressed: isSigningUp ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                  ),
                                  child: isSigningUp
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '회원가입',
                                              style: TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Icon(Icons.arrow_forward, size: 25),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 로그인 화면으로 돌아가기
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '이미 계정이 있으신가요?',
                            style: TextStyle(color: textColor, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              '로그인하기 →',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 디자인 보조 위젯
  // ─────────────────────────────────────────────

  Widget _sectionTitle(String title, {required bool required}) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
          child: Text(
            title,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(width: 9),
        const Expanded(child: Divider(color: borderColor, thickness: 1.2)),
        if (required) ...[
          const SizedBox(width: 7),
          const Text(
            '* 필수',
            style: TextStyle(color: Color(0xFFD87991), fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9996B7), fontSize: 14),
      prefixIcon: Icon(icon, color: iconColor, size: 21),
      filled: true,
      fillColor: inputColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryColor, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor, width: 1.2),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    // 월 변경 등으로 현재 일자가 유효하지 않으면 선택값을 비움
    final safeValue = value != null && values.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: inputColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      hint: Text(
        hint,
        style: const TextStyle(color: Color(0xFF9996B7), fontSize: 13),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: textColor, fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _choiceButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primaryColor : inputColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? primaryColor : borderColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAlert(String message) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
