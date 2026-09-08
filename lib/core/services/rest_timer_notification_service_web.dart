import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

import '../logger.dart';
import 'rest_timer_notification_service.dart';

RestTimerNotificationService createRestTimerNotificationService() =>
    WebRestTimerNotificationService();

/// Web implementation of the Rest Timer notification contract using the
/// browser Notification API. Permission is requested lazily, the first time
/// a notification is scheduled, rather than at app start.
///
/// Browsers throttle timers in backgrounded tabs, so a notification driven
/// by [Timer] can fire late while the tab is not focused. The rest timer's
/// own countdown is unaffected since it derives from wall-clock time; only
/// this alert can lag.
class WebRestTimerNotificationService implements RestTimerNotificationService {
  final Map<int, Timer> _pendingTimers = {};
  final Map<int, html.Notification> _activeNotifications = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await cancelNotification(id);

    if (!html.Notification.supported) {
      logger.w('Web notifications are not supported in this browser.');
      return;
    }

    var permission = html.Notification.permission;
    if (permission != 'granted') {
      permission = await html.Notification.requestPermission();
    }
    if (permission != 'granted') {
      logger.w('Web notification permission was not granted.');
      return;
    }

    final delay = scheduledDate.difference(DateTime.now());
    if (delay.isNegative) {
      logger.w('Notification not scheduled: scheduledDate ($scheduledDate) is in the past.');
      return;
    }

    _pendingTimers[id] = Timer(delay, () {
      _pendingTimers.remove(id);
      _activeNotifications[id] = html.Notification(title, body: body);
    });
  }

  @override
  Future<void> cancelNotification(int id) async {
    _pendingTimers.remove(id)?.cancel();
    _activeNotifications.remove(id)?.close();
  }
}
