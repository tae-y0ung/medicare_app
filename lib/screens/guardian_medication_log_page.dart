import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user_profile.dart';

class GuardianMedicationLogPage extends StatefulWidget {
  final UserProfile profile;

  const GuardianMedicationLogPage({super.key, required this.profile});

  @override
  State<GuardianMedicationLogPage> createState() =>
      _GuardianMedicationLogPageState();
}

class _GuardianMedicationLogPageState extends State<GuardianMedicationLogPage> {
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _wards = [];
  final Map<String, Map<String, dynamic>> _statuses = {};
  final Map<String, List<Map<String, dynamic>>> _history = {};
  final Map<String, String> _historyErrors = {};
  final Set<String> _historyLoadingIds = {};

  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _errors = {};
  final Set<String> _loadingIds = {};

  bool _isLoading = true;
  String? _loadError;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadWards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _wardId(Map<String, dynamic> ward) =>
      (ward['wardUserId'] ?? '').toString().trim();

  String _wardName(Map<String, dynamic> ward) =>
      (ward['wardName'] ?? '피보호자').toString();

  Future<void> _loadWards() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _wards = [];
      _statuses.clear();
      _errors.clear();
      _loadingIds.clear();
      _currentIndex = 0;
    });

    try {
      final result = await ApiService.getWardsForGuardian(
        widget.profile.userId,
      );

      if (result['success'] == false) {
        throw Exception(result['message'] ?? '목록 조회 실패');
      }

      final raw = result['wards'];

      final wards = raw is List
          ? raw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .where((ward) => _wardId(ward).isNotEmpty)
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _wards = wards;
        _isLoading = false;
      });

      if (wards.isNotEmpty) {
        await Future.wait([
          _loadWardStatus(wards.first),
          _loadWardHistory(wards.first),
        ]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWardStatus(
    Map<String, dynamic> ward, {
    bool force = false,
  }) async {
    final id = _wardId(ward);

    if (id.isEmpty || _loadingIds.contains(id)) return;

    if (!force && _statuses.containsKey(id)) return;

    setState(() {
      _loadingIds.add(id);
      _errors.remove(id);
    });

    try {
      final result = await ApiService.getGuardianTodayStatus(
        guardianUserId: widget.profile.userId,
        wardUserId: id,
      );

      if (result['success'] == false) {
        throw Exception(result['message'] ?? '복약 조회 실패');
      }

      if (!mounted) return;

      setState(() {
        _statuses[id] = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[id] = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingIds.remove(id);
        });
      }
    }
  }

  String _dateString(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadWardHistory(Map<String, dynamic> ward) async {
    final wardId = _wardId(ward);

    if (wardId.isEmpty) return;
    if (_historyLoadingIds.contains(wardId)) return;

    setState(() {
      _historyLoadingIds.add(wardId);
      _historyErrors.remove(wardId);
    });

    try {
      final result = await ApiService.getGuardianMedicationHistory(
        guardianUserId: widget.profile.userId,
        wardUserId: wardId,
        date: _dateString(_selectedDate),
      );

      debugPrint(
        '[GUARDIAN HISTORY] wardId=$wardId '
        'date=${_dateString(_selectedDate)} '
        'response=$result',
      );

      final dynamic rawHistory = result['medications'];

      final records = rawHistory is List
          ? rawHistory
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _history[wardId] = records;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _historyErrors[wardId] = e.toString();
        _history.remove(wardId);
      });
    } finally {
      if (mounted) {
        setState(() {
          _historyLoadingIds.remove(wardId);
        });
      }
    }
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF635C85)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wardPage(Map<String, dynamic> ward) {
    final id = _wardId(ward);
    final name = _wardName(ward);
    final status = _statuses[id];
    final loading = _loadingIds.contains(id);
    final error = _errors[id];

    if (loading && status == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && status == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('복약 현황을 불러오지 못했습니다.'),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            TextButton(
              onPressed: () => _loadWardStatus(ward, force: true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (status == null) {
      return const SizedBox.shrink();
    }

    final summary = status['summary'] is Map
        ? Map<String, dynamic>.from(status['summary'])
        : <String, dynamic>{};

    final total = summary['total'] ?? 0;
    final taken = summary['taken'] ?? 0;
    final remaining = summary['remaining'] ?? 0;
    final rate = summary['completionRate'] ?? 0;

    // 백엔드가 상세 로그를 반환하는 경우에만 표시
    final logs = _history[id] ?? <Map<String, dynamic>>[];
    final isHistoryLoading = _historyLoadingIds.contains(id);
    final historyError = _historyErrors[id];

    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final medicine in logs) {
      final groupId = (medicine['prescriptionGroupId'] ?? '').toString().trim();

      final category = (medicine['prescriptionCategory'] ?? '')
          .toString()
          .trim();

      final key = groupId.isNotEmpty
          ? groupId
          : 'ungrouped_${medicine['scheduleId']}';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(medicine);
    }

    return RefreshIndicator(
      onRefresh: () => _loadWardStatus(ward, force: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '$name 님의 복약 현황',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('오늘 복약 현황', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard('전체', '$total회', Icons.medication_outlined),
              const SizedBox(width: 8),
              _statCard('완료', '$taken회', Icons.check_circle_outline),
              const SizedBox(width: 8),
              _statCard('남음', '$remaining회', Icons.schedule),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '복약 달성률 $rate%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ((num.tryParse(rate.toString()) ?? 0).toDouble() / 100)
                .clamp(0.0, 1.0),
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 28),
          const Text(
            '복약 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // 날짜 선택
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(_dateString(_selectedDate)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (picked == null || !mounted) return;

              setState(() {
                _selectedDate = picked;
                _history.clear();
                _historyErrors.clear();
              });

              await _loadWardHistory(ward);
            },
          ),

          const SizedBox(height: 12),

          if (isHistoryLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (historyError != null)
            Column(
              children: [
                Text('복약 기록 조회 실패: $historyError'),
                TextButton(
                  onPressed: () => _loadWardHistory(ward),
                  child: const Text('다시 시도'),
                ),
              ],
            )
          else if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '선택한 날짜의 복약 기록이 없습니다.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              final medicines = entry.value;

              final category = (medicines.first['prescriptionCategory'] ?? '')
                  .toString()
                  .trim();

              final categoryName = category.isEmpty ? '미분류 처방전' : category;

              int total = 0;
              int taken = 0;

              for (final medicine in medicines) {
                final rawDoses = medicine['doses'];

                if (rawDoses is List) {
                  for (final dose in rawDoses) {
                    if (dose is! Map) continue;
                    total++;

                    if (dose['taken'] == true) {
                      taken++;
                    }
                  }
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text('$taken/$total회 복용 완료'),
                  children: medicines.map((medicine) {
                    final medicineName = (medicine['medicineName'] ?? '약 이름 없음')
                        .toString();

                    final rawDoses = medicine['doses'];

                    final doses = rawDoses is List
                        ? rawDoses.whereType<Map>().toList()
                        : <Map>[];

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicineName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          ...doses.map((dose) {
                            final time = (dose['time'] ?? '').toString();

                            final isTaken = dose['taken'] == true;

                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isTaken
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isTaken
                                    ? const Color(0xFF6D53A3)
                                    : Colors.grey,
                              ),
                              title: Text(time),
                              trailing: Text(isTaken ? '복용 완료' : '미복용'),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('피보호자 복약 기록'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: '새로고침',
              onPressed: _loadWards,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),

      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('목록 조회 실패: $_loadError'),
                  TextButton(onPressed: _loadWards, child: const Text('다시 시도')),
                ],
              ),
            )
          : _wards.isEmpty
          ? const Center(
              child: Text(
                '등록된 피보호자가 없습니다.\n'
                '프로필 메뉴에서 먼저 피보호자를 연결해 주세요.',
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _currentIndex > 0
                            ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              )
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${_wards.length}명 중 '
                        '${_currentIndex + 1}번째',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: _currentIndex < _wards.length - 1
                            ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              )
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _wards.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });

                      _loadWardStatus(_wards[index]);
                      _loadWardHistory(_wards[index]);
                    },
                    itemBuilder: (context, index) {
                      return _wardPage(_wards[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
