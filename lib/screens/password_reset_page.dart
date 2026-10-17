import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class PasswordResetPage extends StatefulWidget {
  final String email;

  const PasswordResetPage({super.key, this.email = ''});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  // ── 로그인 화면과 통일한 회색 테마 ──────────────
  static const Color primaryColor = Color(0xFF333333);
  static const Color secondaryColor = Color(0xFFB8B8B8);
  static const Color textColor = Color(0xFF29272F);
  static const Color hintColor = Color(0xFF929292);
  static const Color borderColor = Color(0xFFD8D8DC);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color softGray = Color(0xFFF3F3F3);
  static const Color buttonColor = Color(0xFFB8B8B8);

  late final TextEditingController emailController;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool codeRequested = false;
  bool codeVerified = false;
  bool busy = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  int resendSeconds = 0;
  Timer? _resendTimer;

  String? resetToken;
  String? requestedEmail;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String get _email => emailController.text.trim().toLowerCase();

  // ── 안내 메시지 ──────────────────────────────
  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(value),
          behavior: SnackBarBehavior.floating,
          backgroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ── 이메일 변경 시 인증 초기화 ────────────────
  void _resetVerification() {
    _resendTimer?.cancel();

    setState(() {
      codeRequested = false;
      codeVerified = false;
      resetToken = null;
      requestedEmail = null;
      resendSeconds = 0;

      codeController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      showPassword = false;
      showConfirmPassword = false;
    });
  }

  // ── 재발송 대기시간 ──────────────────────────
  void _startCountdown() {
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

  // ── 인증번호 요청 ────────────────────────────
  Future<void> _requestCode() async {
    if (busy || resendSeconds > 0 || codeVerified) return;

    final email = _email;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _message('올바른 이메일 주소를 입력해주세요.');
      return;
    }

    setState(() {
      busy = true;
    });

    try {
      await ApiService.requestPasswordResetCode(email: email);

      if (!mounted) return;

      if (_email != email) return;

      setState(() {
        requestedEmail = email;
        codeRequested = true;
        codeVerified = false;
        resetToken = null;
        codeController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      });

      _startCountdown();
      _message('인증번호를 발송했습니다. 이메일을 확인해주세요.');
    } catch (e) {
      if (!mounted) return;

      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  // ── 인증번호 확인 ────────────────────────────
  Future<void> _confirmCode() async {
    if (busy || !codeRequested || codeVerified) return;

    final email = _email;
    final code = codeController.text.trim();

    if (requestedEmail != email) {
      _message('이메일이 변경되었습니다. 인증번호를 다시 요청해주세요.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _message('인증번호 6자리를 입력해주세요.');
      return;
    }

    setState(() {
      busy = true;
    });

    try {
      final result = await ApiService.verifyPasswordResetCode(
        email: email,
        code: code,
      );

      if (!mounted) return;

      if (_email != email || requestedEmail != email) {
        _message('이메일이 변경되었습니다. 다시 인증해주세요.');
        return;
      }

      final token = (result['resetToken'] ?? '').toString();

      if (token.isEmpty) {
        throw Exception('인증 토큰을 받지 못했습니다. 다시 인증해주세요.');
      }

      _resendTimer?.cancel();

      setState(() {
        resetToken = token;
        codeVerified = true;
        resendSeconds = 0;
      });

      _message('이메일 인증이 완료되었습니다.');
    } catch (e) {
      if (!mounted) return;

      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  // ── 비밀번호 재설정 ──────────────────────────
  Future<void> _resetPassword() async {
    if (busy) return;

    if (!codeVerified || resetToken == null) {
      _message('이메일 인증을 먼저 완료해주세요.');
      return;
    }

    if (_email != requestedEmail) {
      _message('이메일이 변경되었습니다. 다시 인증해주세요.');
      return;
    }

    final password = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.length < 8) {
      _message('새 비밀번호는 8자 이상 입력해주세요.');
      return;
    }

    if (password != confirmPassword) {
      _message('새 비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      busy = true;
    });

    try {
      await ApiService.resetPassword(
        resetToken: resetToken!,
        newPassword: password,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: primaryColor,
              size: 54,
            ),
            title: const Text(
              '비밀번호 변경 완료',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              '새 비밀번호가 설정되었습니다.\n새 비밀번호로 로그인해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: hintColor, height: 1.6),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    disabledBackgroundColor: buttonColor,

                    // 버튼 글씨와 화살표를 검정색으로 고정
                    foregroundColor: Colors.black,
                    disabledForegroundColor: Colors.black,

                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                      side: const BorderSide(color: Colors.black, width: 1.4),
                    ),
                  ),

                  child: const Text('확인'),
                ),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  // ── 공통 입력창 디자인 ────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
    bool compact = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: hintColor, fontSize: 15),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFF505050), size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 14 : 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: borderColor, width: 1.2),
      ),
    );
  }

  // ── 섹션 카드 ────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: softGray,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ── 공통 라벨 ────────────────────────────────
  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ── 회색 주요 버튼 ───────────────────────────
  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor,

          // 활성화 및 비활성화 상태 모두 검정색
          foregroundColor: Colors.black,
          disabledForegroundColor: Colors.black,

          // 비활성화 상태에서도 색상 변경 방지
          surfaceTintColor: Colors.transparent,
          elevation: 0,

          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Colors.black, width: 1.4),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.black,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 9),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // ── 흰색 배경 ─────────────────────────
          const Positioned.fill(child: ColoredBox(color: backgroundColor)),

          // ── 왼쪽 위 회색 곡선 장식 ────────────
          Positioned(
            top: -115,
            left: -110,
            child: Container(
              width: 300,
              height: 270,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(160),
                  bottomLeft: Radius.circular(130),
                ),
              ),
            ),
          ),

          // ── 오른쪽 아래 회색 곡선 장식 ────────
          Positioned(
            bottom: -140,
            right: -110,
            child: Container(
              width: 310,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(180),
                  topRight: Radius.circular(140),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── 상단 헤더 ────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '뒤로가기',
                        onPressed: busy
                            ? null
                            : () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                          size: 21,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          '비밀번호 찾기',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // ── 화면 크기에 맞춰 스크롤 ──────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 40 > 0
                                ? constraints.maxHeight - 40
                                : 0,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 8),

                                  const Text(
                                    '비밀번호를 잊으셨나요?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  const Text(
                                    '가입한 이메일 주소를 입력해주세요.\n'
                                    '이메일 인증 후 새 비밀번호를 설정할 수 있어요.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: hintColor,
                                      height: 1.65,
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // ── 이메일 인증 카드 ──
                                  _sectionCard(
                                    title: '이메일 인증',
                                    icon: Icons.mark_email_read_outlined,
                                    children: [
                                      _fieldLabel('이메일 주소'),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: emailController,
                                              enabled: !busy && !codeVerified,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.done,
                                              autocorrect: false,
                                              enableSuggestions: false,
                                              onChanged: (_) {
                                                _resetVerification();
                                              },
                                              decoration: _inputDecoration(
                                                hint: '이메일 주소 입력',
                                                icon: Icons.email_outlined,
                                                compact: true,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          SizedBox(
                                            height: 50,
                                            child: OutlinedButton(
                                              onPressed:
                                                  busy ||
                                                      resendSeconds > 0 ||
                                                      codeVerified
                                                  ? null
                                                  : _requestCode,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: textColor,
                                                disabledForegroundColor:
                                                    hintColor,
                                                backgroundColor: Colors.white,
                                                side: const BorderSide(
                                                  color: borderColor,
                                                  width: 1.5,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              child: Text(
                                                codeVerified
                                                    ? '인증 완료'
                                                    : busy
                                                    ? '처리 중'
                                                    : resendSeconds > 0
                                                    ? '${resendSeconds}초'
                                                    : codeRequested
                                                    ? '재발송'
                                                    : '인증번호\n발송',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (codeVerified) ...[
                                        const SizedBox(height: 14),
                                        _statusMessage(
                                          '이메일 인증이 완료되었습니다.',
                                          Icons.check_circle_rounded,
                                          const Color(0xFF39856A),
                                        ),
                                      ],

                                      if (codeRequested && !codeVerified) ...[
                                        const SizedBox(height: 22),

                                        _fieldLabel('인증번호 6자리'),

                                        TextField(
                                          controller: codeController,
                                          enabled: !busy,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(6),
                                          ],
                                          textInputAction: TextInputAction.done,
                                          decoration: _inputDecoration(
                                            hint: '이메일로 받은 인증번호',
                                            icon: Icons.pin_outlined,
                                            compact: true,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        const Text(
                                          '이메일로 전송된 6자리 번호를 입력해주세요.',
                                          style: TextStyle(
                                            color: hintColor,
                                            fontSize: 12,
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        _primaryButton(
                                          label: '인증번호 확인',
                                          icon: Icons.arrow_forward_rounded,
                                          loading: busy,
                                          onPressed: busy ? null : _confirmCode,
                                        ),
                                      ],
                                    ],
                                  ),

                                  // ── 새 비밀번호 설정 ──
                                  if (codeVerified) ...[
                                    const SizedBox(height: 18),

                                    _sectionCard(
                                      title: '새 비밀번호 설정',
                                      icon: Icons.lock_reset_rounded,
                                      children: [
                                        _fieldLabel('새 비밀번호'),

                                        TextField(
                                          controller: newPasswordController,
                                          enabled: !busy,
                                          obscureText: !showPassword,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          decoration: _inputDecoration(
                                            hint: '8자 이상 입력해주세요',
                                            icon: Icons.lock_outline_rounded,
                                            compact: true,
                                            suffixIcon: IconButton(
                                              tooltip: showPassword
                                                  ? '비밀번호 숨기기'
                                                  : '비밀번호 표시',
                                              onPressed: () {
                                                setState(() {
                                                  showPassword = !showPassword;
                                                });
                                              },
                                              icon: Icon(
                                                showPassword
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                                color: hintColor,
                                                size: 21,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        _fieldLabel('새 비밀번호 확인'),

                                        TextField(
                                          controller: confirmPasswordController,
                                          enabled: !busy,
                                          obscureText: !showConfirmPassword,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          textInputAction: TextInputAction.done,
                                          decoration: _inputDecoration(
                                            hint: '새 비밀번호를 다시 입력해주세요',
                                            icon: Icons.verified_user_outlined,
                                            compact: true,
                                            suffixIcon: IconButton(
                                              tooltip: showConfirmPassword
                                                  ? '비밀번호 숨기기'
                                                  : '비밀번호 표시',
                                              onPressed: () {
                                                setState(() {
                                                  showConfirmPassword =
                                                      !showConfirmPassword;
                                                });
                                              },
                                              icon: Icon(
                                                showConfirmPassword
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                                color: hintColor,
                                                size: 21,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        const Text(
                                          '비밀번호는 8자 이상으로 설정해주세요.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hintColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // ── 비밀번호 재설정 버튼 ──
                                  _primaryButton(
                                    label: '비밀번호 재설정',
                                    icon: Icons.arrow_forward_rounded,
                                    loading: busy && codeVerified,
                                    onPressed: busy || !codeVerified
                                        ? null
                                        : _resetPassword,
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
          ),
        ],
      ),
    );
  }

  // ── 상태 안내 문구 ────────────────────────────
  Widget _statusMessage(String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
