class Emitter {
  final Map<dynamic, List<Function>> _events = {};

  void on(dynamic event, Function func) {
    _events[event] ??= [];
    _events[event]!.add(func);
  }

  void off(dynamic event, Function func) {
    if (!_events.containsKey(event)) {
      return;
    }
    _events[event]!.remove(func);
  }

  void once(dynamic event, Function func) {
    void handler(arg) {
      off(event, handler);
      func(arg);
    }

    on(event, handler);
  }

  void emit(dynamic event, dynamic arg) {
    if (!_events.containsKey(event)) {
      return;
    }
    for (final listener in _events[event]!) {
      listener(arg);
    }
  }

  void removeAllListeners(List<dynamic> events) {
    for (final event in events) {
      _events[event]?.clear();
    }
  }
}
