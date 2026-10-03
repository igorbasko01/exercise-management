/// Top-level generic interface for any notification capability.
abstract class NotificationService {
  Future<void> init();
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  Future<void> cancelNotification(int id);
}

/// Domain-specific interface for Rest Timer notifications.
/// This allows ViewModels to depend on a specialized contract.
abstract class RestTimerNotificationService extends NotificationService {}
