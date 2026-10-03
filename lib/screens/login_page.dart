import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'user_profile.dart';
import '../services/api_service.dart';

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

    if (isLoggingIn) {
      return;
    }

    setState(() {
      isLoggingIn = true;
    });

    try {
      // --------------------------------
      // 1. 로그인
      // --------------------------------

      final loginResult = await ApiService.login(
        email: email,
        password: password,
      );

      debugPrint('로그인 결과: $loginResult');

      // --------------------------------
      // 2. userId 추출
      // --------------------------------

      final loginUser = loginResult['user'];

      String userId =
          (loginResult['userId'] ??
                  (loginUser is Map<String, dynamic>
                      ? loginUser['userId']
                      : null) ??
                  '')
              .toString();

      if (userId.isEmpty) {
        throw Exception(
          '로그인 결과에서 '
          '사용자 ID를 찾을 수 없습니다.',
        );
      }

      debugPrint('로그인 사용자 ID: $userId');

      // --------------------------------
      // 3. 사용자 최신 정보 조회
      // --------------------------------

      final userResult = await ApiService.getUser(userId);

      debugPrint(
        '사용자 정보 조회 결과: '
        '$userResult',
      );

      if (userResult['user'] == null) {
        throw Exception(
          '사용자 정보를 '
          '불러오지 못했습니다.',
        );
      }

      final user = Map<String, dynamic>.from(userResult['user']);

      // 백엔드 응답에 혹시
      // userId가 빠진 경우를 대비
      user['userId'] ??= userId;

      // --------------------------------
      // 4. UserProfile 생성
      // --------------------------------

      final profile = UserProfile.fromJson(user);

      debugPrint(
        '실제 로그인 프로필: '
        '${profile.userId} / '
        '${profile.name}',
      );

      debugPrint(
        '보호자 전화번호: '
        '${profile.guardianPhone}',
      );

      if (!mounted) {
        return;
      }

      // --------------------------------
      // 5. 홈 화면 이동
      // --------------------------------

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
        (route) => false,
      );
    } catch (e) {
      debugPrint('로그인 실패: $e');

      if (!mounted) {
        return;
      }

      String message = e.toString();

      message = message.replaceFirst('Exception: ', '');

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              Image.asset("assets/images/medicare_logo_2.png", width: 300),

              const SizedBox(height: 40),

              Container(
                width: 335,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "이메일 주소",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        hintText: "비밀번호",
                        border: const OutlineInputBorder(),
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

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isLoggingIn ? null : _login,

                        child: isLoggingIn
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('로그인', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("계정이 없으신가요? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        color: Colors.blue,
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
