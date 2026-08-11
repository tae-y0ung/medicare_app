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

  try {
    final result = await ApiService.login(
      email: email,
      password: password,
    );

    debugPrint('로그인 결과: $result');

    if (!mounted) return;

    final user = result['user'];

    final profile = UserProfile(
      name: user['name'] ?? '',
      email: user['email'] ?? '',
      phone: user['phone'] ?? '',
      gender: user['gender'] ?? '',
      pregnancy: user['pregnancy'] ?? '',
      birthYear: user['birthYear'] ?? '',
      birthMonth: user['birthMonth'] ?? '',
      birthDay: user['birthDay'] ?? '',
      guardianPhone: user['guardianPhone'] ?? '',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          profile: profile,
        ),
      ),
    );
  } catch (e) {
    debugPrint('로그인 실패: $e');

    if (!mounted) return;

    _showAlert(
      '이메일 또는 비밀번호가 올바르지 않습니다.',
    );
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

              Image.asset(
                "assets/images/medicare_logo_2.png",
                width: 300,
              ),

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
                        onPressed: _login,
                        child: const Text(
                          "로그인",
                          style: TextStyle(fontSize: 20),
                        ),
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
                          builder: (context) =>
                              const SignUpScreen(),
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