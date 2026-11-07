import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  bool _busy = false;

  // 테스트 전용 ID.
  // 실제 복약 알림에서는 이 번호를 사용하지 않도록 구분해 둡니다.
  static const int _testReminderId = 1999999999;

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  // 중복 클릭 방지와 오류 안내를 공통 처리합니다.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await action();
    } catch (e) {
      _showMessage('알림 처리에 실패했어요: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // 1. 시스템 알림 표시 권한 요청
  Future<void> _requestNotificationPermission() async {
    await _run(() async {
      final granted = await NotificationService.instance
          .requestNotificationPermission();

      _showMessage(
        granted
            ? '알림이 허용됐어요.'
            : '알림이 허용되지 않았어요. 휴대폰 설정을 확인해주세요.',
      );
    });
  }

  // 2. Android 정확한 알람 권한 요청
  Future<void> _requestExactAlarmPermission() async {
    await _run(() async {
      final granted = await NotificationService.instance
          .requestExactAlarmPermission();

      _showMessage(
        granted
            ? 'Android에서는 정확한 알람 사용이 가능해요. '
                'iOS에는 이 권한이 필요하지 않아요.'
            : '정확한 알람이 허용되지 않았어요. '
                '예약 알림이 늦게 표시될 수 있어요.',
      );
    });
  }

  // 3. 즉시 시스템 알림 표시
  Future<void> _showImmediateTest() async {
    await _run(() async {
      final granted = await NotificationService.instance
          .requestNotificationPermission();

      if (!granted) {
        _showMessage('먼저 휴대폰 설정에서 알림을 허용해주세요.');
        return;
      }

      await NotificationService.instance.showTestNotification();

      _showMessage(
        '테스트 알림 표시를 요청했어요. 휴대폰 알림창을 확인해주세요.',
      );
    });
  }

  // 4. 1분 뒤 시스템 알림 예약
  Future<void> _scheduleOneMinuteTest() async {
    await _run(() async {
      final granted = await NotificationService.instance
          .requestNotificationPermission();

      if (!granted) {
        _showMessage('먼저 휴대폰 설정에서 알림을 허용해주세요.');
        return;
      }

      await NotificationService.instance.scheduleDoseReminder(
        notificationId: _testReminderId,
        occurrenceId: 'settings_test_occurrence',
        scheduledAt: DateTime.now().add(
          const Duration(minutes: 1),
        ),
      );

      _showMessage(
        '1분 뒤 테스트 알림을 예약했어요. '
        '홈 화면으로 나간 뒤 확인해주세요. '
        '정확한 알람 권한이 없으면 늦게 표시될 수 있어요.',
      );
    });
  }

  // 예약한 테스트 알림만 취소
  Future<void> _cancelTestReminder() async {
    await _run(() async {
      await NotificationService.instance.cancel(_testReminderId);

      _showMessage('예약된 테스트 알림을 취소했어요.');
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
            '휴대폰 알림 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '잠금화면과 휴대폰 알림창에 표시되는 '
            '시스템 알림을 설정하고 테스트해요.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _busy ? null : _requestNotificationPermission,
              child: const Text('1. 알림 표시 허용'),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  _busy ? null : _requestExactAlarmPermission,
              child: const Text('2. 정확한 알람 허용 · Android'),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _busy ? null : _showImmediateTest,
              child: const Text('3. 즉시 알림 테스트'),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _busy ? null : _scheduleOneMinuteTest,
              child: const Text('4. 1분 뒤 알림 테스트'),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _cancelTestReminder,
              child: const Text('예약 테스트 취소'),
            ),
          ),

          if (_busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],

          const SizedBox(height: 8),
          const Text(
            '※ 테스트 버튼은 개발 확인용이에요. '
            '실제 복약 일정 연동이 끝나면 제거해도 돼요.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
