import 'dart:async';
import 'dart:html';

import 'package:surrealdb_client/src/emitter.dart';

enum SocketState { opened, closed }

/// WebSocket wrapper with connection persistance
/// mechanism.
class Socket extends Emitter {
  late final WebSocket _ws;
  final String _url;
  bool _closed = false;
  SocketState _status = SocketState.closed;

  late Completer<void> _connectionCompleter;
  Future<void> get ready => _connectionCompleter.future;

  Socket(String url)
      : _url = url
            .replaceFirst('http://', 'ws://')
            .replaceFirst('https://', 'wss://') {
    _init();
  }

  void _init() {
    _connectionCompleter = Completer();
  }

  Future<void> open() async {
    _ws = WebSocket(_url);

    _ws.addEventListener(
        'message', (e) => emit('message', (e as MessageEvent).data));
    _ws.addEventListener('error', (e) => emit('error', e));
    _ws.addEventListener('close', (e) => emit('close', e));
    _ws.addEventListener('open', (e) => emit('open', e));

    _ws.addEventListener('close', (_) {
      if (_status == SocketState.closed) {
        _init();
      }
    });
    _ws.addEventListener('close', (_) => _status = SocketState.closed);
    _ws.addEventListener('open', (_) => _status = SocketState.opened);
    _ws.addEventListener('close', (_) {
      if (!_closed) {
        Timer(const Duration(milliseconds: 2500), () {
          open();
        });
      }
    });

    _ws.addEventListener('open', (_) => _connectionCompleter.complete());
  }

  void send(dynamic data) {
    _ws.send(data);
  }

  Future<void> close({
    int code = 1000,
    String reason = '',
  }) async {
    _closed = true;
    _ws.close(code, reason);
  }
}
