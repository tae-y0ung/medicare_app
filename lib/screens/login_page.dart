import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'password_reset_page.dart';
import 'home_page.dart';
import 'user_profile.dart';
import '../services/api_service.dart';
import '../services/login_session_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool passwordVisible = false;
  bool isLoggingIn = false;

  bool keepLoggedIn = false;

  // 홈 화면과 통일한 색상
  static const primaryColor = Color(0xFF6C4EAD);
  static const borderColor = Color(0xFF000000);
  static const textColor = Color(0xFF252329);
  static const hintColor = Color(0xFF85818A);
  static const backgroundColor = Colors.white;
  static const inputBorderColor = Color(0xFF85818A);
  static const buttonColor = Color(0xFFB5B5B5);
  static const decorationColor = Color(0xFFF7F7F7);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      _showAlert('이메일을 입력해주세요.');
      return;
    }

    if (password.isEmpty) {
      _showAlert('비밀번호를 입력해주세요.');
      return;
    }

    if (isLoggingIn) return;

    setState(() {
      isLoggingIn = true;
    });

    try {
      // 1. 로그인
      final loginResult = await ApiService.login(
        email: email,
        password: password,
      );

      // 2. userId 추출
      final loginUser = loginResult['user'];

      final String userId =
          (loginResult['userId'] ??
                  (loginUser is Map<String, dynamic>
                      ? loginUser['userId']
                      : null) ??
                  '')
              .toString();

      if (userId.isEmpty) {
        throw Exception('로그인 결과에서 사용자 ID를 찾을 수 없습니다.');
      }

      debugPrint('로그인 사용자 ID: $userId');

      // 3. 사용자 최신 정보 조회
      final userResult = await ApiService.getUser(userId);

      debugPrint('사용자 정보 조회 결과: $userResult');

      if (userResult['user'] == null) {
        throw Exception('사용자 정보를 불러오지 못했습니다.');
      }

      final user = Map<String, dynamic>.from(userResult['user']);

      user['userId'] ??= userId;

      // 4. UserProfile 생성
      final profile = UserProfile.fromJson(user);

      await LoginSessionService.clear();

if (keepLoggedIn) {
  final token =
      (loginResult['sessionToken'] ?? '')
          .toString();

  await LoginSessionService.save(token);
}

      debugPrint('실제 로그인 프로필: ${profile.userId} / ${profile.name}');
      debugPrint('보호자 전화번호: ${profile.guardianPhone}');

      if (!mounted) return;

      // 5. 홈 화면 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
        (route) => false,
      );
    } catch (e) {
      debugPrint('로그인 실패: $e');

      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      _showAlert(message);
    } finally {
      if (mounted) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 배경 그라데이션: 흰색 계열로 변경
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFCFCFC), Colors.white],
                ),
              ),
            ),
          ),

          // 왼쪽 위 장식: 연보라색 제거
          Positioned(
            top: -65,
            left: -75,
            child: Container(
              width: 230,
              height: 200,
              decoration: BoxDecoration(
                color: decorationColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(150),
                  bottomLeft: Radius.circular(90),
                ),
              ),
            ),
          ),

          // 오른쪽 아래 장식: 연보라색 제거
          Positioned(
            bottom: -100,
            right: -75,
            child: Container(
              width: 240,
              height: 220,
              decoration: BoxDecoration(
                color: decorationColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(160),
                  topRight: Radius.circular(80),
                ),
              ),
            ),
          ),

          // 로그인 화면
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 기존 로고 유지
                            Image.asset(
                              'assets/images/medicare_logo_2.png',
                              width: 280,
                            ),

                            const SizedBox(height: 36),

                            // 로그인 카드: 검정 테두리와 흰색 배경
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // 이메일
                                  TextField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: '이메일 주소',
                                      hintStyle: const TextStyle(
                                        color: hintColor,
                                      ),
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.mail_outline_rounded,
                                          color: textColor,
                                        ),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 20,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: inputBorderColor,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: primaryColor,
                                          width: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // 비밀번호
                                  TextField(
                                    controller: passwordController,
                                    obscureText: !passwordVisible,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (!isLoggingIn) {
                                        _login();
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: '비밀번호',
                                      hintStyle: const TextStyle(
                                        color: hintColor,
                                      ),
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.lock_outline_rounded,
                                          color: textColor,
                                        ),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          passwordVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: textColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            passwordVisible = !passwordVisible;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 20,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: inputBorderColor,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: primaryColor,
                                          width: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Checkbox(
                                        value: keepLoggedIn,
                                        activeColor: const Color(0xFF8F7AE5),
                                        onChanged: isLoggingIn
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  keepLoggedIn = value ?? false;
                                                });
                                              },
                                      ),
                                      const Text(
                                        '로그인 유지',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // 로그인 버튼: 홈 화면의 회색 버튼과 통일
                                  SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: ElevatedButton(
                                      onPressed: isLoggingIn ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: buttonColor,
                                        foregroundColor: Colors.black,
                                        disabledBackgroundColor: const Color(
                                          0xFFD0D0D0,
                                        ),
                                        disabledForegroundColor: Colors.black54,
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.black,
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                      child: isLoggingIn
                                          ? const SizedBox(
                                              width: 23,
                                              height: 23,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '로그인',
                                                  style: TextStyle(
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 회원가입: 기존 기능 유지
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  child: Text(
                                    '계정이 없으신가요? ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    '회원가입',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 17,
                                  color: primaryColor,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 구분선: 연보라색 대신 연회색
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFD6D6D6),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '또는',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hintColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFD6D6D6),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // 비밀번호 찾기: 기존 기능 유지
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PasswordResetPage(
                                      email: emailController.text.trim(),
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '비밀번호를 잊으셨나요?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
