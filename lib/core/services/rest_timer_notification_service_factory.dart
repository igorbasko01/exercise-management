import 'rest_timer_notification_service.dart';
import 'rest_timer_notification_service_stub.dart'
    if (dart.library.io) 'rest_timer_notification_service_io.dart'
    if (dart.library.html) 'rest_timer_notification_service_web.dart' as platform;

/// Creates the [RestTimerNotificationService] implementation for the
/// current platform: local device notifications on Android/iOS, the browser
/// Notification API on web.
RestTimerNotificationService createRestTimerNotificationService() =>
    platform.createRestTimerNotificationService();
