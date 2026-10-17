
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '알림').toString(),
      body: (json['body'] ?? '').toString(),
      date: DateTime.tryParse(
            (json['createdAt'] ?? '').toString(),
          )?.toLocal() ??
          DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }
}

class NotifyPage extends StatefulWidget {
  final String userId;

  const NotifyPage({super.key, required this.userId});

  @override
  State<NotifyPage> createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage> {
  static const Color purple = Color(0xFF8F7AE5);
  static const Color unreadBackground = Color(0xFFF5F0FC);
  static const Color borderColor = Color(0xFFE6DFF0);
  static const Color titleColor = Color(0xFF29252F);
  static const Color bodyColor = Color(0xFF514B59);
  static const Color subTextColor = Color(0xFF9992A3);

  List<NotificationItem> _items = [];
  bool _loading = true;
  bool _updating = false;
  String? _error;

  int get _unreadCount =>
      _items.where((item) => !item.isRead).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data =
          await ApiService.getNotifications(widget.userId);

      if (!mounted) return;

      setState(() {
        _items = data.map(NotificationItem.fromJson).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirm(NotificationItem item) async {
    if (_updating || item.isRead) return;

    setState(() => _updating = true);

    try {
      await ApiService.markNotificationRead(
        userId: widget.userId,
        notificationId: item.id,
      );

      if (!mounted) return;

      setState(() => item.isRead = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 읽음 처리에 실패했어요.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Future<void> _confirmAll() async {
    if (_updating || _unreadCount == 0) return;

    setState(() => _updating = true);

    try {
      await ApiService.markAllNotificationsRead(widget.userId);

      if (!mounted) return;

      setState(() {
        for (final item in _items) {
          item.isRead = true;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('전체 읽음 처리에 실패했어요.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  String get _todayLabel {
    final now = DateTime.now();
    const weekdays = [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
    ];

    return '${now.year}년 ${now.month}월 ${now.day}일 '
        '${weekdays[now.weekday - 1]}';
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$month/$day $hour:$minute';
  }

  Widget _buildItem(NotificationItem item) {
    final unread = !item.isRead;

    return Material(
      color: unread ? unreadBackground : Colors.white,
      child: InkWell(
        onTap: unread && !_updating ? () => _confirm(item) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: unread ? unreadBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: borderColor.withValues(alpha: 0.8),
                width: 0.7,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: purple,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            unread ? FontWeight.w600 : FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: bodyColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dateLabel(item.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: subTextColor,
                            ),
                          ),
                        ),
                        if (unread)
                          TextButton(
                            onPressed: _updating
                                ? null
                                : () => _confirm(item),
                            style: TextButton.styleFrom(
                              foregroundColor: purple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '확인',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 12,
                                color: subTextColor,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '읽음',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Icon(
          Icons.notifications_none_rounded,
          size: 40,
          color: purple,
        ),
        SizedBox(height: 14),
        Center(
          child: Text(
            '새로운 알림이 없어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            '복약 알림이 도착하면 여기에 표시돼요.',
            style: TextStyle(
              fontSize: 12,
              color: subTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: subTextColor,
            ),
            const SizedBox(height: 12),
            const Text(
              '알림을 불러오지 못했어요.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '네트워크 연결을 확인한 후 다시 시도해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: purple,
                side: const BorderSide(color: purple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 설정 화면과 동일한 로고 및 날짜 헤더
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        _todayLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
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

            // 설정 화면과 동일한 제목 바
            Container(
              width: double.infinity,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.only(left: 16, right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '알림',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: purple,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _updating ? null : _confirmAll,
                      style: TextButton.styleFrom(
                        foregroundColor: purple,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '모두 읽음',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),

            // 설정 화면과 동일한 본문 테두리
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: purple,
                          strokeWidth: 2,
                        ),
                      )
                    : _error != null
                        ? _buildErrorView()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: purple,
                            child: _items.isEmpty
                                ? _buildEmptyView()
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      bottom: 12,
                                    ),
                                    itemCount: _items.length,
                                    itemBuilder: (context, index) {
                                      final item = _items[index];

                                      return _buildItem(item);
                                    },
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
