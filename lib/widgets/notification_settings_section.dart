import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationSettingsSection extends StatefulWidget {
  final String userId;

  const NotificationSettingsSection({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  bool _busy = false;

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _run(
    Future<void> Function() action,
  ) async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await action();
    } catch (e) {
      _showMessage('알림 설정 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // 시스템 알림 권한 요청
  Future<void> _allowNotifications() async {
    await _run(() async {
      final granted = await NotificationService.instance
          .requestNotificationPermission();

      if (granted) {
        _showMessage('휴대폰 알림이 허용되었습니다.');
      } else {
        _showMessage(
          '알림 권한이 허용되지 않았습니다. '
          '휴대폰 설정에서 허용해주세요.',
        );
      }
    });
  }

  // Android 정확한 알람 권한
  Future<void> _allowExactAlarms() async {
    await _run(() async {
      final granted = await NotificationService.instance
          .requestExactAlarmPermission();

      _showMessage(
        granted
            ? '정확한 알람을 사용할 수 있습니다.'
            : '정확한 알람이 허용되지 않아 '
              '알림이 지연될 수 있습니다.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE6DFF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '복약 알림 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '등록된 복약 일정에 맞춰 휴대폰에 '
            '알림을 표시합니다.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: _busy ? null : _allowNotifications,
    icon: const Icon(Icons.notifications_outlined),
    label: const Text('휴대폰 알림 허용'),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF6750A4),
      backgroundColor: Colors.transparent,
      elevation: 0,
      minimumSize: const Size(0, 48),
      side: const BorderSide(
        color: Colors.grey,
        width: 1,
      ),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
  ),
),

const SizedBox(height: 8),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: _busy ? null : _allowExactAlarms,
    icon: const Icon(Icons.schedule),
    label: const Text('정확한 알람 허용 (Android)'),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF6750A4),
      backgroundColor: Colors.transparent,
      elevation: 0,
      minimumSize: const Size(0, 48),
      side: const BorderSide(
        color: Colors.grey,
        width: 1,
      ),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
  ),
),


          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
