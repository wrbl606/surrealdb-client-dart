import 'dart:async';

class Pinger {
  final Duration _interval;
  Timer? _timer;

  Pinger({Duration interval = const Duration(seconds: 30)})
      : _interval = interval;

  void start(Function() func) =>
      _timer = Timer.periodic(_interval, (_) => func());

  void stop() => _timer?.cancel();
}
