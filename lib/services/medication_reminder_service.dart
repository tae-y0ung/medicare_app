import 'dart:convert';

import 'api_service.dart';
import 'notification_service.dart';

class MedicationReminderService {
  MedicationReminderService._();

  static final MedicationReminderService instance =
      MedicationReminderService._();

  Future<void>? _runningSync;

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  DateTime? _parseDate(dynamic value) {
    final text = (value ?? '').toString().trim();

    if (text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);

    if (parsed == null) return null;

    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
    );
  }

  // 복약 건별로 일정한 알림 ID 생성
  int _notificationId(String key) {
    var hash = 2166136261;

    for (final byte in utf8.encode(key)) {
      hash ^= byte;
      hash = (hash * 16777619) & 0x7fffffff;
    }

    return hash == 0 ? 1 : hash;
  }

  // 아침/점심/저녁 또는 HH:mm 형태를
  // 실제 복약 시간으로 변환
  String? _resolveClock(
    String value,
    Map<String, String> userTimes,
  ) {
    final raw = value.trim();

    final clock = switch (raw) {
      '아침' => userTimes['morning'] ?? '08:30',
      '점심' => userTimes['lunch'] ?? '13:30',
      '저녁' => userTimes['dinner'] ?? '19:30',
      _ => raw,
    };

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})$',
    ).firstMatch(clock);

    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);

    if (hour > 23 || minute > 59) {
      return null;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  Future<void> sync(String userId) {
    // 동시에 여러 화면에서 호출하더라도
    // 중복 예약 작업을 실행하지 않음
    if (_runningSync != null) {
      return _runningSync!;
    }

    final future = _syncInternal(userId);
    _runningSync = future;

    return future.whenComplete(() {
      _runningSync = null;
    });
  }

  Future<void> _syncInternal(String userId) async {
    // 1. 서버에서 실제 일정 및 복용 기록 조회
    final scheduleResult =
        await ApiService.getSchedules(userId);

    final logResult =
        await ApiService.getLogs(userId);

    final userTimes =
        await ApiService.getMedicationTimes(userId);

    if (scheduleResult['success'] != true ||
        logResult['success'] != true) {
      throw Exception('복약 일정 조회에 실패했습니다.');
    }

    final schedules =
        (scheduleResult['schedules'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final logs =
        (logResult['logs'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    // 2. 이미 복용 완료한 일정 목록
    final completed = <String>{};

    for (final log in logs) {
      if (log['taken'] != true) continue;

      final scheduleId =
          (log['scheduleId'] ?? '').toString();

      final date = (log['date'] ?? '').toString();

      final rawTime =
          (log['scheduledTime'] ?? log['time'] ?? '')
              .toString();

      final clock = _resolveClock(
        rawTime,
        userTimes,
      );

      if (clock == null) continue;

      completed.add(
        '$scheduleId|$date|$clock',
      );
    }

    // 3. 향후 7일간의 실제 복약 시간 계산
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final reminders = <({
      int id,
      String occurrenceId,
      DateTime scheduledAt,
    })>[];

    final usedIds = <int>{};

    for (final schedule in schedules) {
      if (schedule['active'] == false) continue;
      if (schedule['isStock'] == true) continue;
      if (schedule['asNeeded'] == true) continue;

      final scheduleId =
          (schedule['scheduleId'] ?? '').toString();

      if (scheduleId.isEmpty) continue;

      final startDate =
          _parseDate(schedule['startDate']);

      final endDate =
          _parseDate(schedule['endDate']);

      // 기간을 확인할 수 없는 일정은
      // 임의로 알림을 예약하지 않음
      if (startDate == null || endDate == null) {
        continue;
      }

      final rawTimes = schedule['times'];

      List<String> times = [];

      if (rawTimes is List && rawTimes.isNotEmpty) {
        times = rawTimes.map((e) => e.toString()).toList();
      } else {
        // 오래된 일정의 복용 횟수 기반 보완
        final count = int.tryParse(
              (schedule['dailyCount'] ?? '').toString(),
            ) ??
            0;

        times = switch (count) {
          1 => ['아침'],
          2 => ['아침', '저녁'],
          3 => ['아침', '점심', '저녁'],
          _ => [],
        };
      }

      for (var dayOffset = 0;
          dayOffset < 7;
          dayOffset++) {
        final day = today.add(
          Duration(days: dayOffset),
        );

        if (day.isBefore(startDate) ||
            day.isAfter(endDate)) {
          continue;
        }

        for (final value in times) {
          final clock = _resolveClock(
            value,
            userTimes,
          );

          if (clock == null) continue;

          final parts = clock.split(':');

          final scheduledAt = DateTime(
            day.year,
            day.month,
            day.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          // 이미 지난 복용 시간 제외
          if (!scheduledAt.isAfter(now)) {
            continue;
          }

          final occurrenceId =
              '$scheduleId|${_dateKey(day)}|$clock';

          // 이미 완료한 복약 제외
          if (completed.contains(occurrenceId)) {
            continue;
          }

          final id = _notificationId(
            '$userId|$occurrenceId',
          );

          // 드문 알림 ID 충돌 방어
          if (!usedIds.add(id)) {
            continue;
          }

          reminders.add((
            id: id,
            occurrenceId: occurrenceId,
            scheduledAt: scheduledAt,
          ));
        }
      }
    }

    reminders.sort(
      (a, b) =>
          a.scheduledAt.compareTo(b.scheduledAt),
    );

    // 4. 기존 복약 알림 예약만 제거
    await NotificationService.instance
        .cancelDoseReminders();

    // 5. 실제 일정에 따라 다시 예약
    // iOS 예약 개수 제한을 고려하여 60건까지만
    for (final reminder in reminders.take(60)) {
      await NotificationService.instance
          .scheduleDoseReminder(
        notificationId: reminder.id,
        occurrenceId: reminder.occurrenceId,
        scheduledAt: reminder.scheduledAt,
      );
    }

    print(
      '[MEDICATION REMINDER] '
      '예약 완료: ${reminders.take(60).length}건',
    );
  }
}
