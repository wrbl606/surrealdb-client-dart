import 'dart:async';
import 'dart:io';

import 'package:surrealdb_client/src/emitter.dart';

enum SocketState { opened, closed }

class Socket extends Emitter {
  final String _url;
  bool _closed = false;
  SocketState _socketState = SocketState.closed;
  WebSocket? _ws;
  StreamSubscription? _wsSub;

  late Completer _readyCompleter;
  Future<void> get ready => _readyCompleter.future;

  Socket(String url)
      : _url = url
            .replaceFirst('http://', 'ws://')
            .replaceFirst('https://', 'ws://') {
    _init();
  }

  void _init() {
    _readyCompleter = Completer();
  }

  void dispose() {
    _wsSub?.cancel();
  }

  Future<void> open() async {
    _ws = await WebSocket.connect(_url);
    _socketState = SocketState.opened;
    emit('open', null);

    _wsSub = _ws!.listen((event) {
      emit('message', event);
    }, onError: (event) {
      emit('error', event);
    }, onDone: () {
      emit('close', null);

      // If the WebSocket connection with the
      // database was disconnected, then we need
      // to reset the ready promise.
      if (_socketState == SocketState.opened) {
        _init();
      }

      // When the WebSocket is opened or closed
      // then we need to store the connection
      // status within the status property.
      _socketState = SocketState.closed;

      // If the connection is closed, then we
      // need to attempt to reconnect on a
      // regular basis until we are successful.
      if (!_closed) {
        // FIXME: This may be working in JS because browsers
        // do emit "close" event event after unsuccessful connection attempt
        // but here the .connect() method will just fail
        // and the code will not try to reconnect more than once.
        Timer(const Duration(seconds: 2), () => open());
      }
    });

    _readyCompleter.complete();
  }

  void send(dynamic data) {
    _ws?.add(data);
  }

  void close({int code = 1000, String reason = ''}) {
    _closed = true;
    _ws?.close(code, reason);
  }
}
