import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:exercise_management/core/services/rest_timer_notification_service.dart';
import 'package:exercise_management/presentation/pages/rest_timer_page.dart';
import 'package:exercise_management/presentation/view_models/rest_timer_view_model.dart';

class MockRestTimerNotificationService extends Mock implements RestTimerNotificationService {}

void main() {
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
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<RestTimerNotificationService>.value(value: mockNotificationService),
          ChangeNotifierProvider<RestTimerViewModel>(
            create: (_) => RestTimerViewModel(notificationService: mockNotificationService),
          ),
        ],
        child: const RestTimerPage(),
      ),
    );
  }

  testWidgets('Initial state shows 60s selected and Start Timer button',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Select Rest Time'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget); // 60s default
    expect(find.text('Start Timer'), findsOneWidget);
  });

  testWidgets('Changing duration updates display', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('90s'));
    await tester.pump();

    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('Starting timer updates UI and schedules notification',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Select 30s to make test shorter
    await tester.tap(find.text('30s'));
    await tester.pump();

    await tester.tap(find.text('Start Timer'));
    await tester.pump(); // trigger setState

    expect(find.text('Time Remaining'), findsOneWidget);
    expect(find.text('Stop Timer'), findsOneWidget);

    verify(() => mockNotificationService.scheduleNotification(
          id: 888,
          title: 'Rest Timer Finished!',
          body: 'Time to get back to your workout.',
          scheduledDate: any(named: 'scheduledDate'),
        )).called(1);
  });

  testWidgets('Timer counts down and stops automatically',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('30s'));
    await tester.pump();

    await tester.tap(find.text('Start Timer'));
    await tester.pump();

    // Advance 10 seconds
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('00:20'), findsOneWidget);

    // Advance remaining 20 seconds + 1 extra second for diff < 0
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    // Timer should be stopped
    expect(find.text('Select Rest Time'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget); // Resets to selected duration
    expect(find.text('Start Timer'), findsOneWidget);

    // Cancel shouldn't be called if it finishes naturally
    verifyNever(() => mockNotificationService.cancelNotification(any()));
  });

  testWidgets('Stopping timer manually cancels notification',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('60s'));
    await tester.pump();

    await tester.tap(find.text('Start Timer'));
    await tester.pump();

    // Advance 10 seconds
    await tester.pump(const Duration(seconds: 10));

    // Tap stop manually
    await tester.tap(find.text('Stop Timer'));
    await tester.pump();

    expect(find.text('Select Rest Time'), findsOneWidget);
    expect(find.text('Start Timer'), findsOneWidget);

    verify(() => mockNotificationService.cancelNotification(888)).called(1);
  });
}
