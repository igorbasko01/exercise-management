import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:exercise_management/core/services/rest_timer_notification_service.dart';
import 'package:exercise_management/presentation/view_models/rest_timer_view_model.dart';

class MockRestTimerNotificationService extends Mock implements RestTimerNotificationService {}

void main() {
  late RestTimerViewModel viewModel;
  late MockRestTimerNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockNotificationService = MockRestTimerNotificationService();
    
    when(() => mockNotificationService.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
        )).thenAnswer((_) async {});
        
    when(() => mockNotificationService.cancelNotification(any()))
        .thenAnswer((_) async {});

    viewModel = RestTimerViewModel(notificationService: mockNotificationService);
  });

  test('Initial state is correct', () {
    expect(viewModel.isRunning, isFalse);
    expect(viewModel.selectedDuration, 60);
    expect(viewModel.remainingSeconds, 60);
  });

  test('setSelectedDuration updates the duration and notifies listeners', () {
    bool notified = false;
    viewModel.addListener(() => notified = true);

    viewModel.setSelectedDuration(90);

    expect(viewModel.selectedDuration, 90);
    expect(viewModel.remainingSeconds, 90);
    expect(notified, isTrue);
  });

  test('setSelectedDuration is ignored if timer is running', () {
    viewModel.startTimer();
    viewModel.setSelectedDuration(90);

    expect(viewModel.selectedDuration, 60);
  });

  test('startTimer schedules a notification and sets isRunning to true', () {
    fakeAsync((async) {
      final startTime = clock.now();

      viewModel.startTimer();

      expect(viewModel.isRunning, isTrue);
      
      final expectedEndTime = startTime.add(const Duration(seconds: 60));
      
      verify(() => mockNotificationService.scheduleNotification(
            id: 888,
            title: 'Rest Timer Finished!',
            body: 'Time to get back to your workout.',
            scheduledDate: expectedEndTime,
          )).called(1);
    });
  });

  test('stopTimer cancels timer and notification', () {
    viewModel.startTimer();
    
    bool notified = false;
    viewModel.addListener(() => notified = true);

    viewModel.stopTimer();

    expect(viewModel.isRunning, isFalse);
    verify(() => mockNotificationService.cancelNotification(888)).called(1);
    expect(notified, isTrue);
  });

  test('Timer counts down and stops automatically', () {
    fakeAsync((async) {
      viewModel.setSelectedDuration(30);
      viewModel.startTimer();
      
      expect(viewModel.remainingSeconds, 30);
      expect(viewModel.isRunning, isTrue);

      // Advance 10 seconds
      async.elapse(const Duration(seconds: 10));
      expect(viewModel.remainingSeconds, 20);
      expect(viewModel.isRunning, isTrue);

      // Advance remaining 20 seconds + a tiny bit for the tick (250ms)
      async.elapse(const Duration(seconds: 21));
      
      expect(viewModel.isRunning, isFalse);
      expect(viewModel.remainingSeconds, 30); // Resets to selected duration
      
      // Manual cancel should NOT be called
      verifyNever(() => mockNotificationService.cancelNotification(any()));
    });
  });
}
