import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // 앱 실행 후 처리할 알림 탭 정보.
  String? pendingPayload;

  // 앱이 실행 중일 때 알림을 탭한 경우.
  void Function(String? payload)? onTap;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'medication_alerts_v1',
    '복약 알림',
    description: '복약 시간 및 복약 상태를 알려드려요.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // 국내 사용을 기준으로 작성.
    // 해외에서도 현지 시간 기준으로 동작해야 한다면
    // 기기의 실제 시간대 조회 및 시간대 변경 시 재예약이 필요함.
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(
        'ic_stat_medication',
      ),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        pendingPayload = response.payload;
        onTap?.call(response.payload);
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(_channel);

    final launchDetails =
        await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      pendingPayload =
          launchDetails?.notificationResponse?.payload;
    }

    _initialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  // Android 전용.
  // 복약 알림 설정 화면에서 필요성을 설명한 뒤 호출.
  Future<bool> requestExactAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return true;

    return await android.requestExactAlarmsPermission() ?? false;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final canUseExact =
        await android.canScheduleExactNotifications() ?? false;

    return canUseExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_alerts_v1',
          '복약 알림',
          channelDescription: '복약 시간 및 복약 상태를 알려드려요.',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
          icon: 'ic_stat_medication',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      );

  Future<void> scheduleDoseReminder({
    required int notificationId,
    required String occurrenceId,
    required DateTime scheduledAt,
  }) async {
    if (!_initialized) {
      throw StateError('NotificationService.initialize()가 필요합니다.');
    }

    if (!scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    await _plugin.zonedSchedule(
      id: notificationId,
      title: '복약 시간이에요',
      body: '예정된 복약을 확인하고, 복용 후 완료를 눌러주세요.',
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: _details,
      androidScheduleMode: await _scheduleMode(),
      payload: jsonEncode({
        'type': 'dose_due',
        'occurrenceId': occurrenceId,
      }),
    );
  }

  // FCM을 포그라운드에서 수신했을 때도 활용 가능.
  Future<void> showNow({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  }

  Future<void> cancel(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  // ========================================
// 실제 복약 시간 알림만 취소
// ========================================

Future<void> cancelDoseReminders() async {
  final pending =
      await _plugin.pendingNotificationRequests();

  for (final notification in pending) {
    final payload = notification.payload ?? '';

    try {
      final data = jsonDecode(payload);

      if (data is Map &&
          data['type'] == 'dose_due') {
        await _plugin.cancel(
          id: notification.id,
        );
      }
    } catch (_) {
      // 다른 종류의 알림은 유지
    }
  }
}

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> showTestNotification() async {
    await showNow(
      notificationId: 2000000000,
      title: '알림 테스트',
      body: '휴대폰 시스템 알림이 정상적으로 표시됐어요.',
    );
  }
}
