import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'user_profile.dart';
import '../services/api_service.dart';

class GuardianAccountPage extends StatefulWidget {
  final UserProfile profile;

  const GuardianAccountPage({super.key, required this.profile});

  @override
  State<GuardianAccountPage> createState() => _GuardianAccountPageState();
}

class _GuardianAccountPageState extends State<GuardianAccountPage> {
  final connectionCodeController = TextEditingController();

  bool isLoading = false;
  bool isActionLoading = false;

  String? generatedCode;
  int? expiresInMinutes;

  List<Map<String, dynamic>> guardians = [];
  List<Map<String, dynamic>> wards = [];

  static const Color _accent = Color(0xFF7650B5);
  static const Color _textColor = Color(0xFF252329);
  static const Color _secondaryText = Color(0xFF514B57);
  static const Color _sectionBorder = Color(0xFF292929);
  static const Color _softPurple = Color(0xFFF7F2FA);

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  @override
  void dispose() {
    connectionCodeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _loadConnections() async {
    if (widget.profile.userId.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final wardResult = await ApiService.getGuardiansForWard(
        widget.profile.userId,
      );
      final guardianResult = await ApiService.getWardsForGuardian(
        widget.profile.userId,
      );

      if (!mounted) return;

      setState(() {
        guardians = _toMapList(wardResult['guardians']);
        wards = _toMapList(guardianResult['wards']);
      });
    } catch (e) {
      debugPrint('보호자 연결 목록 조회 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _createConnectionCode() async {
    setState(() {
      isActionLoading = true;
    });

    try {
      final result = await ApiService.createGuardianCode(
        wardUserId: widget.profile.userId,
      );

      if (!mounted) return;

      setState(() {
        generatedCode = result['connectionCode']?.toString();
        expiresInMinutes = (result['expiresInMinutes'] as num?)?.toInt();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isActionLoading = false;
        });
      }
    }
  }

  Future<void> _connectWithCode() async {
    final code = connectionCodeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결 코드를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    try {
      final result = await ApiService.connectGuardian(
        guardianUserId: widget.profile.userId,
        connectionCode: code,
      );

      debugPrint('보호자 연결 결과: $result');

      if (!mounted) return;

      connectionCodeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보호 대상과 연결되었습니다.')),
      );

      await _loadConnections();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isActionLoading = false;
        });
      }
    }
  }

  // 현재 화면의 목록에서만 제거합니다. 서버 연결 해제 API 호출은 하지 않습니다.
    // 보호자 연결 해제
  Future<void> _removeGuardian(
    Map<String, dynamic> guardian,
  ) async {
    if (isActionLoading) return;

    final guardianName =
        (guardian['guardianName'] ?? '보호자').toString();

    final guardianUserId =
        (guardian['guardianUserId'] ?? '').toString().trim();

    if (guardianUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보호자 계정 ID를 찾을 수 없습니다.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('보호자 연결 해제'),
        content: Text(
          '$guardianName 님과의 보호자 연결을 해제하시겠습니까?\n\n'
          '연결 해제 후에는 해당 보호자가 '
          '내 복약 정보를 조회할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              '연결 해제',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      isActionLoading = true;
    });

    try {
      final result = await ApiService.disconnectGuardian(
        wardUserId: widget.profile.userId,
        guardianUserId: guardianUserId,
      );

      debugPrint('보호자 연결 해제 결과: $result');

      if (!mounted) return;

      // Firestore 변경 후 서버에서 최신 목록 조회
      await _loadConnections();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보호자 연결이 해제되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '연결 해제 실패: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isActionLoading = false;
        });
      }
    }
  }


  Future<void> _showTodayStatus(Map<String, dynamic> ward) async {
    final wardUserId = (ward['wardUserId'] ?? '').toString();

    if (wardUserId.isEmpty) {
      return;
    }

    try {
      final result = await ApiService.getGuardianTodayStatus(
        guardianUserId: widget.profile.userId,
        wardUserId: wardUserId,
      );

      if (!mounted) return;

      final summary = Map<String, dynamic>.from(result['summary'] ?? {});
      final total = summary['total'] ?? 0;
      final taken = summary['taken'] ?? 0;
      final remaining = summary['remaining'] ?? 0;
      final completionRate = summary['completionRate'] ?? 0;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            '${ward['wardName'] ?? '보호 대상'} 오늘 복약 현황',
          ),
          content: Text(
            '전체 복약: $total회\n'
            '복용 완료: $taken회\n'
            '남은 복약: $remaining회\n'
            '복용률: $completionRate%',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복약 현황 조회 실패: $e')),
      );
    }
  }

  // 아래 위젯 함수들은 화면 디자인만 담당합니다.
  Widget _sectionBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _sectionBorder, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _textColor,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          backgroundColor: _softPurple,
          side: const BorderSide(color: _sectionBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(fontSize: 16),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _guardianTile(Map<String, dynamic> guardian) {
    final guardianName = (guardian['guardianName'] ?? '보호자').toString();
    final guardianPhone = (guardian['guardianPhone'] ?? '').toString();
    final status = (guardian['status'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Slidable(
          key: ValueKey('${guardian['guardianPhone']}_${guardian['guardianName']}'),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.18,
            children: [
              CustomSlidableAction(
                onPressed: (_) => _removeGuardian(guardian),
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(8),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(height: 3),
                    Text(
                      '삭제',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            color: const Color(0xFFFAFAFA),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.person,
                  color: _secondaryText,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guardianName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guardianPhone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wardTile(Map<String, dynamic> ward) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFD6D0DA)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.health_and_safety_outlined,
          color: _secondaryText,
        ),
        title: Text(
          (ward['wardName'] ?? '보호 대상').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text((ward['status'] ?? '').toString()),
        trailing: TextButton(
          onPressed: () => _showTodayStatus(ward),
          child: const Text('오늘 현황'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('보호자 계정'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConnections,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 보호받는 사용자로 연결
                  _sectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('보호받는 사용자로 연결'),
                        const SizedBox(height: 10),
                        const Text(
                          '보호자에게 아래 연결 코드를 전달해주세요.',
                          style: TextStyle(fontSize: 14, color: _textColor),
                        ),
                        const SizedBox(height: 14),
                        _primaryButton(
                          label: isActionLoading ? '처리 중...' : '연결 코드 생성',
                          onPressed: isActionLoading
                              ? null
                              : _createConnectionCode,
                        ),
                        if (generatedCode != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: _sectionBorder),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    generatedCode!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: '연결 코드 복사',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: generatedCode!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('연결 코드를 복사했습니다.'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy),
                                ),
                              ],
                            ),
                          ),
                          if (expiresInMinutes != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '$expiresInMinutes분 동안 유효합니다.',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 보호자로 연결
                  _sectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('보호자로 연결'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: connectionCodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            hintText: '6자리 연결 코드',
                            counterText: '',
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF77717D),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _accent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _primaryButton(
                          label: isActionLoading ? '연결 중...' : '연결',
                          onPressed: isActionLoading ? null : _connectWithCode,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 나와 연결된 보호자
                  _sectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('나와 연결된 보호자'),
                        const SizedBox(height: 12),
                        if (guardians.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '연결된 보호자가 없습니다.',
                              style: TextStyle(color: _secondaryText),
                            ),
                          )
                        else
                          ...guardians.map(_guardianTile),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 내가 보호 중인 사용자
                  _sectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('내가 보호 중인 사용자'),
                        const SizedBox(height: 12),
                        if (wards.isEmpty)
                          const Text(
                            '연결된 보호 대상이 없습니다.',
                            style: TextStyle(color: _secondaryText),
                          )
                        else
                          ...wards.map(_wardTile),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
