import 'dart:async';
import 'dart:convert';

import 'package:surrealdb_client/src/emitter.dart';
import 'package:surrealdb_client/src/id_generator.dart';
import 'package:surrealdb_client/src/live.dart';
import 'package:surrealdb_client/src/pinger.dart';
import 'package:surrealdb_client/src/socket.dart';

/// Client for a SurrealDB instance.
///
/// Connects to a specific database endpoint.
class SurrealClient extends Emitter {
  late final Socket _ws;
  final String _url;
  final IdGenerator _generateId;
  Pinger? _pinger;
  Completer? _initCompleter;
  String _token = '';

  /// Requires [url] for target SurrealDB instance.
  /// [url] have to be a full path to the RPC endpoint
  /// so provide it like eg. https://your.instance/rpc.
  ///
  /// If provided, [token] will be used to authenticate
  /// the connection.
  ///
  /// [idGenerator] allows you to override default ObjectId's
  /// assigned to each RPC with custom id solution.
  /// Ids generated with [idGenerator] regards only RPC,
  /// random ids for newly created objects will be handled
  /// by the target instance.
  SurrealClient({
    required String url,
    String token = '',
    IdGenerator? idGenerator,
  })  : _url = url,
        _token = token,
        _generateId = idGenerator ?? objectId {
    connect(_url);
  }

  /// Connects to a local or remote database endpoint.
  ///
  /// ```
  /// await client.connect('https://cloud.surrealdb.com/rpc');
  /// ```
  Future<void> connect(String url) {
    _ws = Socket(url);

    // Setup the interval pinger so that the
    // connection is kept alive through
    // loadbalancers and proxies.
    _pinger = Pinger();

    _ws.on('open', (_) {
      // When the connection is opened we
      // need to attempt authentication if
      // a token has already been applied.
      _init();

      // When the connection is opened we
      // change the relevant properties
      // open live queries, and trigger.
      emit('open', null);
      emit('opened', null);
      _pinger?.start(() => ping());
    });

    _ws.on('close', (_) {
      // When the connection is closed we
      // change the relevant properties
      // stop live queries, and trigger.
      emit('close', null);
      emit('closed', null);
      print('close');
      _pinger?.stop();
    });

    // When we receive a socket message
    // we process it. If it has an ID
    // then it is a query response.
    _ws.on('message', (e) {
      print(e);
      final event = jsonDecode(e);

      if (event['method'] != 'notify') {
        return emit(event['id'], event);
      } else {
        for (final param in event['params']) {
          emit('notify', param);
        }
      }
    });

    // Open the websocket for the first
    // time. This will automatically
    // attempt to reconnect on failure.
    _ws.open();
    return wait();
  }

  /// Waits for the connection to the database to succeed.
  Future<void> wait() => _ws.ready;

  Live sync(String query, [Map<String, dynamic> vars = const {}]) =>
      Live(db: this, sql: query, vars: vars);

  /// Closes the persistent connection to the database.
  void close() {
    _pinger?.stop();
    _ws.removeAllListeners();
    _ws.close();
  }

  /// Pings the instance to maintain proxy connection.
  ///
  /// Will be called periodically by internal [Pinger].
  Future<void> ping() {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      _send(id, 'ping');
      completer.complete();
    });
    return completer.future;
  }

  /// Switch to a specific namespace and database.
  Future use(String ns, String db) {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _result(res, completer));
      _send(id, 'use', [ns, db]);
    });
    return completer.future;
  }

  Future info() {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _result(res, completer));
      _send(id, 'info');
    });
    return completer.future;
  }

  /// Signs this connection up to a specific authentication scope.
  Future signUp(Map<String, dynamic> vars) {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _signUp(res, completer));
      _send(id, 'signup', [vars]);
    });
    return completer.future;
  }

  /// Signs this connection in to a specific authentication scope.
  Future signIn(Map<String, dynamic> vars) {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _signIn(res, completer));
      _send(id, 'signin', [vars]);
    });
    return completer.future;
  }

  /// Invalidates the authentication for the current connection.
  Future invalidate() {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _auth(res, completer));
      _send(id, 'invalidate');
    });
    return completer.future;
  }

  /// Authenticates the current connection with a JWT token.
  Future<void> authenticate(String token) {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      _ws.once(id, (res) {
        _auth(res, completer);
        _send(id, 'authenticate', [token]);
      });
    });
    return completer.future;
  }

  Future live(String table) {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _result(res, completer));
      _send(id, 'live', [table]);
    });
    return completer.future;
  }

  @override
  Future kill(String query) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _result(res, completer));
      _send(id, 'kill', [query]);
    });
    return completer.future;
  }

  /// Assigns a value as a parameter for this connection.
  Future let(String key, Map<String, dynamic> val) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _result(res, completer));
      _send(id, 'let', [key, val]);
    });
    return completer.future;
  }

  /// Runs a set of SurrealQL statements against the database.
  @override
  Future<dynamic> query(String query, [Map<String, dynamic> vars = const {}]) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _result(res, completer));
      _send(id, 'query', [query, vars]);
    });
    return completer.future;
  }

  /// Selects all records in a table, or a specific record.
  Future<dynamic> select(String thing) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _output(res, 'select', thing, completer));
      _send(id, 'select', [thing]);
    });
    return completer.future;
  }

  /// Creates a record in the database.
  Future<dynamic> create(String thing, Map<String, dynamic> data) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _output(res, 'create', thing, completer));
      _send(id, 'create', [thing, data]);
    });
    return completer.future;
  }

  /// Updates all records in a table, or a specific record.
  Future<dynamic> update(String thing, Map<String, dynamic> data) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _output(res, 'update', thing, completer));
      _send(id, 'update', [thing, data]);
    });
    return completer.future;
  }

  /// Modifies all records in a table, or a specific record.
  Future<dynamic> change(String thing, Map<String, dynamic> data) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _output(res, 'change', thing, completer));
      _send(id, 'change', [thing, data]);
    });
    return completer.future;
  }

  /// Applies [JSON Patch](https://jsonpatch.com/) changes
  /// to all records in a table, or a specific record.
  Future<dynamic> modify(String thing, List<Map<String, dynamic>> data) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _output(res, 'modify', thing, completer));
      _send(id, 'modify', [thing, data]);
    });
    return completer.future;
  }

  /// Deletes all records, or a specific record.
  Future<dynamic> delete(String thing) {
    final id = _generateId();
    final completer = Completer();
    wait().then((_) {
      once(id, (res) => _output(res, 'delete', thing, completer));
      _send(id, 'delete', [thing]);
    });
    return completer.future;
  }

  Future<void> _init() {
    _initCompleter = Completer();
    if (_token.isNotEmpty) {
      authenticate(_token).then(_initCompleter!.complete);
    } else {
      _initCompleter!.complete();
    }
    return _initCompleter!.future;
  }

  void _send(String id, String method, [List<dynamic> params = const []]) {
    _ws.send(jsonEncode({
      'id': id,
      'method': method,
      'params': params,
    }));
  }

  void _auth(dynamic res, Completer completer) {
    if (res['error'] != null) {
      completer.completeError(AuthenticationException(res['error']['message']));
    } else {
      completer.complete(res['result']);
    }
  }

  void _result(dynamic res, Completer completer) {
    if (res['error'] != null) {
      return completer.completeError(Exception(res['error']['message']));
    } else if (res['result'] != null) {
      return completer.complete(res['result']);
    }
    completer.complete(null);
  }

  void _signUp(dynamic res, Completer completer) {
    print(res);
    if (res['error'] != null) {
      completer.completeError(AuthenticationException(res['error']['message']));
    } else {
      _token = res['result'];
      completer.complete(_token);
    }
  }

  void _signIn(dynamic res, Completer completer) {
    print(res);
    if (res['error'] != null) {
      completer.completeError(AuthenticationException(res['error']['message']));
    } else {
      _token = res['result'];
      completer.complete(_token);
    }
  }

  void _output(dynamic res, String type, String id, Completer completer) {
    if (res['error'] != null) {
      return completer.completeError(SurrealException(res['error']['message']));
    } else if (res['result'] != null) {
      switch (type) {
        case 'delete':
          return completer.complete();
        case 'create':
          return (res['result']?.length ?? 0) != 0
              ? completer.complete(res['result'].first)
              : completer.completeError(
                  PermissionException('Unable to create record: $id'));
        case 'update':
        case 'change':
          if (id.contains(':')) {
            return (res['result']?.length ?? 0) != 0
                ? completer.complete(res['result'].first)
                : completer.completeError(
                    PermissionException('Unable to $type record: $id'));
          }
          return completer.complete(res['result']);
        default:
          if (id.contains(':')) {
            return (res['result']?.length ?? 0) != 0
                ? completer.complete(res['result'].first)
                : completer
                    .completeError(RecordException('Record not found: $id'));
          }
          return completer.complete(res['result']);
      }
    }
    completer.complete();
  }
}

/// Will be thrown on authentication exceptions during
/// sign in or sign up.
class AuthenticationException implements Exception {
  final String cause;
  const AuthenticationException(this.cause);

  @override
  String toString() => 'AuthenticationException(cause: $cause)';
}

/// Will be thrown on permission exceptions during
/// table modifications.
class PermissionException implements Exception {
  final String cause;
  const PermissionException(this.cause);

  @override
  String toString() => 'PermissionException(cause: $cause)';
}

/// Will be thrown on permission exceptions during
/// table modifications.
class RecordException implements Exception {
  final String cause;
  const RecordException(this.cause);

  @override
  String toString() => 'RecordException(cause: $cause)';
}

/// General Surreal-related exception.
class SurrealException implements Exception {
  final String cause;
  const SurrealException(this.cause);

  @override
  String toString() => 'SurrealException(cause: $cause)';
}
