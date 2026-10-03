import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결 코드를 입력해주세요.')));

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보호 대상과 연결되었습니다.')));

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
        builder: (_) => AlertDialog(
          title: Text(
            '${ward['wardName'] ?? '보호 대상'} '
            '오늘 복약 현황',
          ),
          content: Text(
            '전체 복약: $total회\n'
            '복용 완료: $taken회\n'
            '남은 복약: $remaining회\n'
            '복용률: $completionRate%',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('복약 현황 조회 실패: $e')));
    }
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
                  const Text(
                    '보호받는 사용자로 연결',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text('보호자에게 아래 연결 코드를 전달해주세요.'),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isActionLoading ? null : _createConnectionCode,
                      child: const Text('연결 코드 생성'),
                    ),
                  ),

                  if (generatedCode != null) ...[
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              generatedCode!,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: generatedCode!),
                              );
                            },
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ),

                    if (expiresInMinutes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$expiresInMinutes분 동안 유효합니다.',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                  ],

                  const SizedBox(height: 28),

                  const Divider(),

                  const SizedBox(height: 20),

                  const Text(
                    '보호자로 연결',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: connectionCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6자리 연결 코드',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isActionLoading ? null : _connectWithCode,
                      child: const Text('연결'),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Divider(),

                  const SizedBox(height: 20),

                  const Text(
                    '나와 연결된 보호자',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  if (guardians.isEmpty)
                    const Text('연결된 보호자가 없습니다.')
                  else
                    ...guardians.map(
                      (guardian) => ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(guardian['guardianName'] ?? '보호자'),
                        subtitle: Text(guardian['guardianPhone'] ?? ''),
                        trailing: Text(guardian['status'] ?? ''),
                      ),
                    ),

                  const SizedBox(height: 28),

                  const Divider(),

                  const SizedBox(height: 20),

                  const Text(
                    '내가 보호 중인 사용자',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  if (wards.isEmpty)
                    const Text('연결된 보호 대상이 없습니다.')
                  else
                    ...wards.map(
                      (ward) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.health_and_safety_outlined),

                          title: Text(ward['wardName'] ?? '보호 대상'),

                          subtitle: Text(ward['status'] ?? ''),

                          trailing: TextButton(
                            onPressed: () => _showTodayStatus(ward),
                            child: const Text('오늘 현황'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
