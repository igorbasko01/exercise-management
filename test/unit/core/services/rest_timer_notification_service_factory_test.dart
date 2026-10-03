import 'package:flutter_test/flutter_test.dart';
import 'package:exercise_management/core/services/rest_timer_notification_service.dart';
import 'package:exercise_management/core/services/rest_timer_notification_service_factory.dart';
import 'package:exercise_management/core/services/rest_timer_notification_service_io.dart'
    show LocalRestTimerNotificationService;

void main() {
  test(
      'createRestTimerNotificationService selects the IO implementation on '
      'this (VM) test platform', () {
    final service = createRestTimerNotificationService();

    expect(service, isA<RestTimerNotificationService>());
    expect(service, isA<LocalRestTimerNotificationService>());
  });
}
