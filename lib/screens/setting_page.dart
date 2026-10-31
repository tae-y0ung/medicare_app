import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'user_profile.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import 'dart:async';
import '../services/login_session_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 전화번호 자동 하이픈 포맷터 (000-0000-0000)
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

// ──────────────────────────────────────────────────────────────────────────────
class SettingScreen extends StatefulWidget {
  /// 회원가입 때 입력한 데이터를 그대로 전달받습니다.
  final UserProfile profile;

  const SettingScreen({super.key, required this.profile});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _phoneController;
  final TextEditingController _guardianPhoneController =
      TextEditingController();

  String _morningTime = '08:30';
  String _lunchTime = '13:30';
  String _dinnerTime = '19:30';

  bool _isLoadingMedicationTimes = false;
  bool _isSavingMedicationTimes = false;

  Timer? _ingredientDebounce;
  List<String> _ingredientSuggestions = [];
  bool _isSearchingIngredients = false;
  int _ingredientRequestId = 0;

  final TextEditingController _allergyController = TextEditingController();

  List<String> _allergyList = [];
  bool _isLoadingAllergies = false;
  bool _isSavingAllergies = false;

  bool _passwordVisible = false;
  bool _isEditing = false;

  String? _verifiedPassword;
  bool _isSavingProfile = false;

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

  // 드롭다운 데이터
  final List<String> _years = List.generate(
    DateTime.now().year - 1946 + 1,
    (i) => (1946 + i).toString(),
  );
  final List<String> _months = List.generate(12, (i) => (i + 1).toString());
  final List<String> _days = List.generate(31, (i) => (i + 1).toString());

  // ── 만 나이 계산 ────────────────────────────────────────────────────────────
  int? get _calculatedAge {
    if (_selectedYear == null ||
        _selectedMonth == null ||
        _selectedDay == null) {
      return null;
    }
    final now = DateTime.now();
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
    final now = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일', 'ko');
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${formatter.format(now)} ${weekdays[now.weekday - 1]}';
  }

  // ── 초기화 ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');

    final p = widget.profile;
    _nameController = TextEditingController(text: p.name);
    _emailController = TextEditingController(text: p.email);
    _phoneController = TextEditingController(text: p.phone);

    _gender = p.gender;
    _pregnancy = p.pregnancy;
    _selectedYear = p.birthYear.isNotEmpty ? p.birthYear : null;
    _selectedMonth = p.birthMonth.isNotEmpty ? p.birthMonth : null;
    _selectedDay = p.birthDay.isNotEmpty ? p.birthDay : null;

    _loadMedicationTimes();
    _loadAllergies();
  }

  Future<void> _loadMedicationTimes() async {
    try {
      setState(() {
        _isLoadingMedicationTimes = true;
      });

      final result = await ApiService.getMedicationTimes(widget.profile.userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _morningTime = result['morning'] ?? '08:30';

        _lunchTime = result['lunch'] ?? '13:30';

        _dinnerTime = result['dinner'] ?? '19:30';

        _isLoadingMedicationTimes = false;
      });
    } catch (e) {
      debugPrint('복약 시간 조회 실패: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMedicationTimes = false;
      });
    }
  }

  Future<void> _loadAllergies() async {
    try {
      final result = await ApiService.getUser(widget.profile.userId);

      Map<String, dynamic> user = {};

      if (result['user'] is Map) {
        user = Map<String, dynamic>.from(result['user']);
      } else {
        user = Map<String, dynamic>.from(result);
      }

      final raw = user['allergyList'];

      final allergies = raw is List
          ? raw
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _allergyList = allergies;
      });
    } catch (e) {
      debugPrint('알레르기 목록 조회 실패: $e');
    }
  }

  Future<void> _saveAllergies() async {
    if (_isSavingAllergies) {
      return;
    }

    try {
      setState(() {
        _isSavingAllergies = true;
      });

      final result = await ApiService.updateAllergies(
        userId: widget.profile.userId,

        allergyList: _allergyList,
      );

      debugPrint(
        '알레르기 저장 결과: '
        '$result',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '알레르기 정보가 '
            '저장되었습니다.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAllergies = false;
        });
      }
    }
  }

  void _searchIngredient(String value) {
    _ingredientDebounce?.cancel();

    final requestId = ++_ingredientRequestId;
    final keyword = value.trim();

    setState(() {
      _ingredientSuggestions = [];
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
              .where((name) => !_allergyList.contains(name))
              .take(3)
              .toList();

          _isSearchingIngredients = false;
        });
      } catch (e) {
        if (!mounted || requestId != _ingredientRequestId) return;

        setState(() {
          _ingredientSuggestions = [];
          _isSearchingIngredients = false;
        });

        debugPrint('성분 검색 실패: $e');
      }
    });
  }

  void _addAllergy() {
    final value = _allergyController.text.trim();

    if (value.isEmpty) {
      return;
    }

    if (_allergyList.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '이미 등록된 '
            '알레르기입니다.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _allergyList.add(value);

      _allergyController.clear();
    });
  }

  Future<void> _removeAllergy(String allergy) async {
    try {
      final newList = List<String>.from(_allergyList);

      newList.remove(allergy);

      // 기존에 사용하던 저장/삭제 API
      await ApiService.updateAllergies(
        userId: widget.profile.userId,

        allergyList: newList,
      );

      // 서버의 최신 allergyList 다시 조회
      await _loadAllergies();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('알레르기 정보가 삭제되었습니다.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('알레르기 삭제 실패: $e')));
    }
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return const TimeOfDay(hour: 8, minute: 30);
    }

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,

      minute: int.tryParse(parts[1]) ?? 30,
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<String?> _pickMedicationTime(String current) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _parseTime(current),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selected == null) {
      return null;
    }

    return _formatTimeOfDay(selected);
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');

    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _saveMedicationTimes() async {
    if (_isSavingMedicationTimes) {
      return;
    }

    final morning = _timeToMinutes(_morningTime);

    final lunch = _timeToMinutes(_lunchTime);

    final dinner = _timeToMinutes(_dinnerTime);

    if (!(morning < lunch && lunch < dinner)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '복약 시간은 '
            '아침 < 점심 < 저녁 '
            '순서로 설정해주세요.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        _isSavingMedicationTimes = true;
      });

      final result = await ApiService.updateMedicationTimes(
        userId: widget.profile.userId,

        morning: _morningTime,

        lunch: _lunchTime,

        dinner: _dinnerTime,
      );

      debugPrint(
        '복약 시간 저장 결과: '
        '$result',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('복약 시간이 저장되었습니다.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMedicationTimes = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _guardianPhoneController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  // ── 수정 모드 진입 (스냅샷 저장) ────────────────────────────────────────────
// ── 본인 확인 후 개인정보 수정 모드 진입 ──
Future<void> _startEditing() async {
  final passwordController = TextEditingController();

  bool checking = false;
  bool passwordVisible = false;
  String? errorText;

  try {
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> verify() async {
              if (checking) return;

              final password = passwordController.text;

              if (password.isEmpty) {
                setDialogState(() {
                  errorText = '현재 비밀번호를 입력해주세요.';
                });
                return;
              }

              setDialogState(() {
                checking = true;
                errorText = null;
              });

              try {
                await ApiService.verifyCurrentPassword(
                  userId: widget.profile.userId,
                  password: password,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext, true);
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  checking = false;
                  errorText = '비밀번호를 확인하지 못했습니다. 다시 입력해주세요.';
                });
              }
            }

            return AlertDialog(
              // 흰색 배경 + 보라색 색상 효과 제거
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,

              // 각진 팝업
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(
                  color: Color(0xFFE0E0E0),
                ),
              ),

              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),

              title: const Text(
                '본인 확인',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '개인정보를 수정하려면 현재 비밀번호를 입력해주세요.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        '현재 비밀번호',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: passwordController,
                        obscureText: !passwordVisible,
                        enabled: !checking,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        cursorColor: Colors.black,

                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                        ),

                        onSubmitted: (_) => verify(),

                        onChanged: (_) {
                          if (errorText != null) {
                            setDialogState(() {
                              errorText = null;
                            });
                          }
                        },

                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력해주세요',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                          ),

                          filled: true,
                          fillColor: Colors.white,

                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),

                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Color(0xFFD0D0D0),
                            ),
                          ),

                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Color(0xFFD0D0D0),
                            ),
                          ),

                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                          ),

                          // 비밀번호 보기 / 숨기기
                          suffixIcon: IconButton(
                            tooltip: passwordVisible
                                ? '비밀번호 숨기기'
                                : '비밀번호 보기',
                            onPressed: checking
                                ? null
                                : () {
                                    setDialogState(() {
                                      passwordVisible = !passwordVisible;
                                    });
                                  },
                            icon: Icon(
                              passwordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.black54,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 같은 크기의 각진 버튼
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: checking
                                    ? null
                                    : () {
                                        Navigator.pop(
                                          dialogContext,
                                          false,
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFD0D0D0),
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                child: const Text('취소'),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: FilledButton(
                                onPressed: checking ? null : verify,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.black26,
                                  disabledForegroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                child: checking
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        '확인',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
          },
        );
      },
    );

    if (verified != true || !mounted) return;

    // 수정 취소 시 복원할 값 저장
    _snapGender = _gender;
    _snapPregnancy = _pregnancy;
    _snapYear = _selectedYear;
    _snapMonth = _selectedMonth;
    _snapDay = _selectedDay;

    setState(() {
      _verifiedPassword = passwordController.text;
      _isEditing = true;
    });
  } finally {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      passwordController.dispose();
    });
  }
}

  // ── 완료 (저장) ─────────────────────────────────────────────────────────────
  Future<void> _completeEditing() async {
  if (_isSavingProfile) return;

  final password = _verifiedPassword;
  final newPassword = _passwordController.text;

  if (password == null || password.isEmpty) {
    _showAlert('본인 확인을 다시 진행해주세요.');
    return;
  }

  final name = _nameController.text.trim();
  final phone = _phoneController.text.trim();

  if (name.isEmpty) {
    _showAlert('이름을 입력해주세요.');
    return;
  }

  setState(() {
    _isSavingProfile = true;
  });

  try {
    await ApiService.updateProfileSecure(
      userId: widget.profile.userId,
      currentPassword: password,
      newPassword: _passwordController.text.isEmpty
    ? null
    : _passwordController.text,
      name: name,
      phone: phone,
      gender: _gender,
      pregnancy: _pregnancy == '예',
      birthYear: int.tryParse(_selectedYear ?? ''),
      birthMonth: int.tryParse(_selectedMonth ?? ''),
      birthDay: int.tryParse(_selectedDay ?? ''),
    );

    // 서버 응답 성공 시에만 수정 완료
    if (!mounted) return;

    setState(() {
      _isEditing = false;
      _verifiedPassword = null;
      _passwordController.clear();
    });
  } finally {
    if (mounted) {
      setState(() {
        _isSavingProfile = false;
      });
    }
  }
}

  // ── 취소 (원복) ─────────────────────────────────────────────────────────────
  void _cancelEditing() {
    setState(() {
      _gender = _snapGender;
      _pregnancy = _snapPregnancy;
      _selectedYear = _snapYear;
      _selectedMonth = _snapMonth;
      _selectedDay = _snapDay;
      _isEditing = false;
      _verifiedPassword = null;
      _passwordController.clear();
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
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      content: const Text(
        '로그아웃 하시겠습니까?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
          },
          child: const Text('취소'),
        ),

        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);

            await LoginSessionService.logout();

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
              (route) => false,
            );
          },
          child: const Text(
            '로그아웃',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _showDeleteAccountDialog() async {
  final passwordController = TextEditingController();
  bool deleting = false;

  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> deleteAccount() async {
              if (deleting) return;

              final password = passwordController.text;

              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('현재 비밀번호를 입력해주세요.'),
                  ),
                );
                return;
              }

              setDialogState(() => deleting = true);

              try {
                await ApiService.deleteMyAccount(
                  userId: widget.profile.userId,
                  password: password,
                );

                await LoginSessionService.logout();

                if (!mounted || !dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (route) => false,
                );
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() => deleting = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '회원 탈퇴 실패: '
                      '${e.toString().replaceFirst('Exception: ', '')}',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text(
                '회원 탈퇴',
                style: TextStyle(color: Colors.redAccent),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '회원 탈퇴 시 계정과 복약 관련 데이터가 '
                    '삭제될 수 있으며 복구가 어렵습니다.\n\n'
                    '탈퇴하려면 현재 비밀번호를 입력해주세요.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !deleting,
                    decoration: const InputDecoration(
                      labelText: '현재 비밀번호',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: deleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: deleting ? null : deleteAccount,
                  child: Text(
                    deleting ? '탈퇴 처리 중...' : '탈퇴하기',
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      passwordController.dispose();
    });
  }
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
              child: SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 날짜는 로고 너비와 무관하게 화면 정중앙에 고정
                    Center(
                      child: Text(
                        _todayLabel,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          child: Image.asset(
                            'assets/images/medicare_logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  topLeft: Radius.circular(10),
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
                    bottomLeft: Radius.circular(10),
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
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  right: 2,
                                ),
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
                                        _pregnancy.isNotEmpty
                                            ? _pregnancy
                                            : '-',
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
                                      inputFormatters: [
                                        _PhoneNumberFormatter(),
                                      ],
                                    )
                                  : _readonlyBox(_phoneController.text),
                            ),
                            const SizedBox(height: 12),

                            // 수정 버튼  ↔  완료 버튼
                            Align(
                              alignment: Alignment.centerRight,
                              child: _isEditing
                                  ? Row(
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

                            // ========================================
                            // 복약 안전 정보
                            // ========================================
                            _sectionTitle('복약 안전 정보'),

                            const SizedBox(height: 6),

                            const Text(
                              '등록된 알레르기 성분은 '
                              '의약품 추천 및 복약 안전 '
                              '검사에 사용됩니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (_isLoadingAllergies)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              // =================================
                              // 등록된 알레르기
                              // =================================
                              if (_allergyList.isEmpty)
                                Container(
                                  width: double.infinity,

                                  padding: const EdgeInsets.all(14),

                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7F7),

                                    borderRadius: BorderRadius.circular(8),

                                    border: Border.all(color: Colors.black12),
                                  ),

                                  child: const Text(
                                    '등록된 알레르기가 '
                                    '없습니다.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,

                                  children: _allergyList
                                      .map(
                                        (allergy) => Container(
                                          padding: const EdgeInsets.fromLTRB(
                                            10,
                                            7,
                                            5,
                                            7,
                                          ),

                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF3F3),

                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),

                                            border: Border.all(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),

                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,

                                            children: [
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                size: 16,
                                                color: Colors.redAccent,
                                              ),

                                              const SizedBox(width: 5),

                                              Text(
                                                allergy,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.redAccent,
                                                ),
                                              ),

                                              const SizedBox(width: 2),

                                              InkWell(
                                                onTap: () =>
                                                    _removeAllergy(allergy),

                                                child: const Padding(
                                                  padding: EdgeInsets.all(3),

                                                  child: Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),

                              const SizedBox(height: 14),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _allergyController,
                                            textInputAction:
                                                TextInputAction.done,

                                            // 입력할 때 FastAPI 성분 검색
                                            onChanged: _searchIngredient,

                                            onSubmitted: (_) => _addAllergy(),
                                            decoration: InputDecoration(
                                              hintText: '알레르기 성분명 입력',
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 14,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),

                                              // 검색 중 로딩 표시
                                              suffixIcon:
                                                  _isSearchingIngredients
                                                  ? const Padding(
                                                      padding: EdgeInsets.all(
                                                        12,
                                                      ),
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

                                        OutlinedButton(
                                          onPressed: _addAllergy,
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('추가'),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // =================================
                                  // API 자동완성 추천 목록 (최대 3개)
                                  // =================================
                                  if (_ingredientSuggestions.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: _ingredientSuggestions
                                            .take(3)
                                            .map((ingredient) {
                                              return ListTile(
                                                dense: true,
                                                title: Text(
                                                  ingredient,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                trailing: const Icon(
                                                  Icons.north_west,
                                                  size: 16,
                                                  color: Colors.black54,
                                                ),
                                                onTap: () {
                                                  _ingredientDebounce?.cancel();
                                                  _ingredientRequestId++;

                                                  setState(() {
                                                    _allergyController.text =
                                                        ingredient;
                                                    _allergyController
                                                            .selection =
                                                        TextSelection.collapsed(
                                                          offset:
                                                              ingredient.length,
                                                        );

                                                    // 선택 후 목록 닫기
                                                    _ingredientSuggestions = [];
                                                    _isSearchingIngredients =
                                                        false;
                                                  });
                                                },
                                              );
                                            })
                                            .toList(),
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

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,

                                height: 44,

                                child: ElevatedButton(
                                  onPressed: _isSavingAllergies
                                      ? null
                                      : _saveAllergies,

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,

                                    foregroundColor: Colors.white,

                                    elevation: 0,
                                  ),

                                  child: _isSavingAllergies
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,

                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,

                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('알레르기 정보 저장'),
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            const Divider(color: Colors.black12),

                            const SizedBox(height: 12),

                            // 기존 복약 시간 설정
                            _sectionTitle('복약 시간 설정'),

                            const SizedBox(height: 6),

                            const Text(
                              '아침·점심·저녁 복약 기준 시간을 설정합니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (_isLoadingMedicationTimes)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              _medicationTimeRow(
                                label: '아침',
                                icon: Icons.wb_sunny_outlined,
                                value: _morningTime,
                                onTap: () async {
                                  final result = await _pickMedicationTime(
                                    _morningTime,
                                  );

                                  if (result != null) {
                                    setState(() {
                                      _morningTime = result;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 8),

                              _medicationTimeRow(
                                label: '점심',
                                icon: Icons.light_mode_outlined,
                                value: _lunchTime,
                                onTap: () async {
                                  final result = await _pickMedicationTime(
                                    _lunchTime,
                                  );

                                  if (result != null) {
                                    setState(() {
                                      _lunchTime = result;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 8),

                              _medicationTimeRow(
                                label: '저녁',
                                icon: Icons.nightlight_outlined,
                                value: _dinnerTime,
                                onTap: () async {
                                  final result = await _pickMedicationTime(
                                    _dinnerTime,
                                  );

                                  if (result != null) {
                                    setState(() {
                                      _dinnerTime = result;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isSavingMedicationTimes
                                      ? null
                                      : _saveMedicationTimes,

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,

                                    foregroundColor: Colors.white,
                                  ),

                                  child: _isSavingMedicationTimes
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('복약 시간 저장'),
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
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
                            const SizedBox(height: 12),

SizedBox(
  width: double.infinity,
  height: 48,
  child: OutlinedButton(
    onPressed: _showDeleteAccountDialog,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color.fromARGB(255, 184, 43, 43),
      side: const BorderSide(
        color: const Color.fromARGB(255, 184, 43, 43),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    child: const Text(
      '회원 탈퇴',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
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
            ),
          ],
        ),
      ),
    );
  }

  // ── 생년월일 드롭다운 (회원가입과 동일 스타일) ────────────────────────────────
  Widget _birthDateSelector() {
    const dropDecoration = InputDecoration.collapsed(
      hintText: null,
      hintStyle: TextStyle(fontSize: 13),
    );

    return Row(
      children: [
        Expanded(
          child: _fieldShell(
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
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _fieldShell(
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
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _fieldShell(
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
        ),
      ],
    );
  }

  Widget _medicationTimeRow({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),

        Expanded(
          child: InkWell(
            onTap: onTap,

            child: Container(
              height: 46,

              padding: const EdgeInsets.symmetric(horizontal: 12),

              decoration: BoxDecoration(
                color: Colors.white,

                border: Border.all(color: Colors.black),

                borderRadius: BorderRadius.circular(6),
              ),

              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.black87),

                  const Spacer(),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
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

  // 모든 입력형 필드가 공유하는 테두리 박스 셸.
  // 편집 모드(TextField)와 읽기 모드(Text)가 동일한 Container를 그대로 재사용하므로
  // 두 모드의 높이가 절대 달라질 수 없습니다.
  Widget _fieldShell({required Widget child}) => Container(
    width: double.infinity,
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black),
    ),
    alignment: Alignment.centerLeft,
    child: child,
  );

  // 읽기 전용 박스: _fieldShell을 그대로 사용
  Widget _readonlyBox(String text) => _fieldShell(
    child: Text(
      text,
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _editTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) => _fieldShell(
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration.collapsed(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14),
      ),
    ),
  );

  Widget _passwordField() => _fieldShell(
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration.collapsed(
              hintText: '새 비밀번호 입력',
              hintStyle: TextStyle(fontSize: 14),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _passwordVisible = !_passwordVisible),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              size: 20,
              color: Colors.black54,
            ),
          ),
        ),
      ],
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
  }) => GestureDetector(
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

  Widget _outlineButton({
    required String label,
    required VoidCallback onPressed,
    bool bold = false,
    double? height,
  }) {
    final button = OutlinedButton(
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

    if (height == null) return button;
    return SizedBox(height: height, child: button);
  }
}
