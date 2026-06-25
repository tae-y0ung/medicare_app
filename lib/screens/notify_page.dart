import 'package:flutter/material.dart';

// ── 알림 데이터 모델 ──────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String title;
  final String? body;
  final DateTime date;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    this.body,
    required this.date,
    this.isRead = false,
  });
}

// ── 알림 페이지 ───────────────────────────────────────────────────────────────

class NotifyPage extends StatefulWidget {
  const NotifyPage({super.key});

  @override
  State<NotifyPage> createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage> {
  // 더미 알림 데이터 (나중에 DB/API로 교체)
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: '주의사항 안내',
      body: '타이레놀 복용 후 4시간이 지났습니다. 다음 복용 시간을 확인하세요.',
      date: DateTime(2026, 6, 25),
    ),
    NotificationItem(
      id: '2',
      title: '복약 알림',
      body: '오후 2시 복약 시간입니다. 이부프로펜 1정을 복용해 주세요.',
      date: DateTime(2026, 6, 25),
    ),
    NotificationItem(
      id: '3',
      title: '주의사항 안내',
      body: '게보린은 공복에 복용하지 마세요. 식후 30분 후 복용을 권장합니다.',
      date: DateTime(2026, 6, 24),
    ),
    NotificationItem(
      id: '4',
      title: '복약 알림',
      body: '오전 9시 복약 시간입니다. 우루사 1정을 복용해 주세요.',
      date: DateTime(2026, 6, 24),
    ),
    NotificationItem(
      id: '5',
      title: '주의사항 안내',
      body: '지르텍 복용 후 졸음이 유발될 수 있습니다. 운전에 주의하세요.',
      date: DateTime(2026, 6, 23),
    ),
  ];

  // 날짜 포맷 (XX월 XX일)
  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  // 오늘 날짜 포맷 (헤더)
  String _formatFullDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일 $weekday요일';
  }

  // 읽지 않은 알림만 필터
  List<NotificationItem> get _unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // 날짜별로 그룹핑
  Map<String, List<NotificationItem>> get _groupedNotifications {
    final Map<String, List<NotificationItem>> grouped = {};
    for (final n in _unreadNotifications) {
      final key = _formatDate(n.date);
      grouped.putIfAbsent(key, () => []).add(n);
    }
    return grouped;
  }

  // 날짜 키 정렬 (최신 순)
  List<String> get _sortedDateKeys {
    final keys = _groupedNotifications.keys.toList();
    keys.sort((a, b) {
      final aDate = _unreadNotifications
          .firstWhere((n) => _formatDate(n.date) == a)
          .date;
      final bDate = _unreadNotifications
          .firstWhere((n) => _formatDate(n.date) == b)
          .date;
      return bDate.compareTo(aDate);
    });
    return keys;
  }

  // 개별 알림 확인
  void _markAsRead(String id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.isRead = true;
    });
  }

  // 전체 읽음
  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final grouped = _groupedNotifications;
    final dateKeys = _sortedDateKeys;
    final hasNotifications = _unreadNotifications.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── 날짜 헤더 + 로고 행 ──────────────────────────────────────
                SizedBox(
                  height: 100,
                  child: Stack(
                    children: [
                      // 로고
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Image.asset(
                          'assets/images/medicare_logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // 날짜
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _formatFullDate(today),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 알림 박스 ─────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        children: [
                          // ── 박스 헤더 ───────────────────────────────────────
                          Container(
                            height: 44,
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.black)),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('알림',
                                      style: TextStyle(fontSize: 15)),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 20, color: Colors.black),
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── 알림 목록 ───────────────────────────────────────
                          Expanded(
                            child: hasNotifications
                                ? ListView.builder(
                                    padding: const EdgeInsets.only(
                                        top: 12, bottom: 60),
                                    itemCount: dateKeys.length,
                                    itemBuilder: (context, groupIndex) {
                                      final dateKey = dateKeys[groupIndex];
                                      final items = grouped[dateKey]!;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 날짜 레이블
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                20, 8, 0, 8),
                                            child: Text(
                                              dateKey,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54),
                                            ),
                                          ),

                                          // 해당 날짜 알림들
                                          ...items.map((item) => Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20, 0, 20, 10),
                                                child: _NotificationCard(
                                                  item: item,
                                                  onConfirm: () =>
                                                      _markAsRead(item.id),
                                                ),
                                              )),

                                          // 날짜 그룹 구분선 (마지막 제외)
                                          if (groupIndex <
                                              dateKeys.length - 1)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 4),
                                              child: Divider(
                                                thickness: 1.5,
                                                color: Colors.grey[300],
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  )
                                : _buildEmptyState(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),

            // ── 전체 읽음 버튼 (우하단 고정) ───────────────────────────────────
            if (hasNotifications)
              Positioned(
                right: 24,
                bottom: 24,
                child: GestureDetector(
                  onTap: _markAllAsRead,
                  child: const Text(
                    '전체 읽음',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF666666),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 알림 없을 때
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            '새로운 알림이 없어요',
            style: TextStyle(fontSize: 15, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ── 알림 카드 위젯 ────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onConfirm;

  const _NotificationCard({
    required this.item,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x4CD9D9D9),
        border: Border.all(color: Colors.black),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          // 내용 (있을 때만)
          if (item.body != null && item.body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.body!,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],

          const SizedBox(height: 10),

          // 확인 버튼 (우측 정렬)
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onConfirm,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0x4CD9D9D9),
                foregroundColor: Colors.black,
                elevation: 0,
                side: const BorderSide(color: Colors.black),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '확인',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}