import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:clock/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/rest_timer_notification_service.dart';

class RestTimerViewModel extends ChangeNotifier {
  final RestTimerNotificationService _notificationService;
  final SharedPreferences _prefs;
  static const int _notificationId = 888;
  static const String _durationPrefsKey = 'rest_timer_duration';

  RestTimerViewModel({
    required RestTimerNotificationService notificationService,
    required SharedPreferences prefs,
  })  : _notificationService = notificationService,
        _prefs = prefs {
    _selectedDuration = _prefs.getInt(_durationPrefsKey) ?? 60;
  }

  late int _selectedDuration;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _endTime;

  int get selectedDuration => _selectedDuration;
  bool get isRunning => _isRunning;
  
  int get remainingSeconds {
    if (!_isRunning || _endTime == null) return _selectedDuration;
    final diff = _endTime!.difference(clock.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void setSelectedDuration(int duration) {
    if (_isRunning) return;
    _selectedDuration = duration;
    _prefs.setInt(_durationPrefsKey, duration);
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) {
      stopTimer();
    }

    _isRunning = true;
    _endTime = clock.now().add(Duration(seconds: _selectedDuration));
    
    _scheduleNotification(_endTime!);
    
    int lastSecond = remainingSeconds;
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_endTime == null) return;

      if (clock.now().isAfter(_endTime!)) {
        _stopInternal();
      } else {
        final currentSecond = remainingSeconds;
        if (currentSecond != lastSecond) {
          lastSecond = currentSecond;
          notifyListeners();
        }
      }
    });
    
    notifyListeners();
  }

  void stopTimer() {
    _stopInternal();
    _notificationService.cancelNotification(_notificationId);
  }

  void _stopInternal() {
    _timer?.cancel();
    _isRunning = false;
    _endTime = null;
    notifyListeners();
  }

  Future<void> _scheduleNotification(DateTime scheduledDate) async {
    await _notificationService.scheduleNotification(
      id: _notificationId,
      title: 'Rest Timer Finished!',
      body: 'Time to get back to your workout.',
      scheduledDate: scheduledDate,
    );
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
