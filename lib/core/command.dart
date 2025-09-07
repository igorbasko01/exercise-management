import 'package:exercise_management/core/result.dart';
import 'package:flutter/material.dart';

typedef CommandAction0<R> = Future<Result<R>> Function();
typedef CommandAction1<R, A> = Future<Result<R>> Function(A);
typedef CommandAction2<R, A1, A2> = Future<Result<R>> Function(A1, A2);

abstract class Command<R> extends ChangeNotifier {
  Command();

  bool _running = false;

  // True when the action is running.
  bool get running => _running;

  Result<R>? _result;

  // True if action completed with error
  bool get error => _result is Error;

  // True if action completed successfully
  bool get completed => _result is Ok;

  /// Get last action result
  Result? get result => _result;

  /// Clear last action result
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(CommandAction0<R> action) async {
    // Ensure the action can't launch multiple times.
    // e.g. avoid multiple taps on button
    if (_running) return;

    // Notify listeners.
    // e.g. button shows loading state
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// [Command] without arguments
/// Takes a [CommandAction0] as action.
class Command0<R> extends Command<R> {
  Command0(this._action);

  final CommandAction0<R> _action;

  Future<void> execute() async {
    await _execute(_action);
  }
}

/// [Command] with 1 argument
/// Takes a [CommandAction1] as action.
class Command1<R, A> extends Command<R> {
  Command1(this._action);

  final CommandAction1<R, A> _action;

  Future<void> execute(A arg) async {
    await _execute(() => _action(arg));
  }
}

class Command2<R, A1, A2> extends Command<R> {
  Command2(this._action);

  final CommandAction2<R, A1, A2> _action;

  Future<void> execute(A1 arg1, A2 arg2) async {
    await _execute(() => _action(arg1, arg2));
  }
}