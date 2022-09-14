// import guid from "./utils/guid.js";
// import errors from "./errors/index.js";
// import Live from "./classes/live.js";
// import Socket from "./classes/socket.js";
// import Pinger from "./classes/pinger.js";
// import Emitter from "./classes/emitter.js";

// let singleton = undefined;

// export default class Surreal extends Emitter {

// 	// ------------------------------
// 	// Main singleton
// 	// ------------------------------

// 	static get Instance() {
// 		return singleton ? singleton : singleton = new Surreal();
// 	}

// 	// ------------------------------
// 	// Public types
// 	// ------------------------------

// 	static get AuthenticationError() {
// 		return errors.AuthenticationError;
// 	}

// 	static get PermissionError() {
// 		return errors.PermissionError;
// 	}

// 	static get RecordError() {
// 		return errors.RecordError;
// 	}

// 	static get Live() {
// 		return Live;
// 	}

// 	// ------------------------------
// 	// Properties
// 	// ------------------------------

// 	#ws = undefined;

// 	#url = undefined;

// 	#token = undefined;

// 	#pinger = undefined;

// 	#attempted = undefined;

// 	// ------------------------------
// 	// Accessors
// 	// ------------------------------

// 	get token() {
//     	return this.#token;
// 	}

// 	set token(token) {
//     	this.#token = token;
// 	}

// 	// ------------------------------
// 	// Methods
// 	// ------------------------------

// 	constructor(url, token) {

// 		super();

// 		this.#url = url;

// 		this.#token = token;

// 		if (url) {
// 			this.connect(url);
// 		}

// 	}

// 	connect(url) {

// 		// Next we setup the websocket connection
// 		// and listen for events on the socket,
// 		// specifying whether logging is enabled.

// 		this.#ws = new Socket(url);

// 		// Setup the interval pinger so that the
// 		// connection is kept alive through
// 		// loadbalancers and proxies.

// 		this.#pinger = new Pinger(30000);

// 		// When the connection is opened we
// 		// need to attempt authentication if
// 		// a token has already been applied.

// 		this.#ws.on("open", () => {
// 			this.#init();
// 		});

// 		// When the connection is opened we
// 		// change the relevant properties
// 		// open live queries, and trigger.

// 		this.#ws.on("open", () => {

// 			this.emit("open");
// 			this.emit("opened");

// 			this.#pinger.start( () => {
// 				this.ping();
// 			});

// 		});

// 		// When the connection is closed we
// 		// change the relevant properties
// 		// stop live queries, and trigger.

// 		this.#ws.on("close", () => {

// 			this.emit("close");
// 			this.emit("closed");

// 			this.#pinger.stop();

// 		});

// 		// When we receive a socket message
// 		// we process it. If it has an ID
// 		// then it is a query response.

// 		this.#ws.on("message", (e) => {

// 			let d = JSON.parse(e.data);

// 			if (d.method !== "notify") {
// 				return this.emit(d.id, d);
// 			}

// 			if (d.method === "notify") {
// 				return d.params.forEach(r => {
// 					this.emit("notify", r);
// 				});
// 			}

// 		});

// 		// Open the websocket for the first
// 		// time. This will automatically
// 		// attempt to reconnect on failure.

// 		this.#ws.open();

// 		//
// 		//
// 		//

// 		return this.wait();

// 	}

// 	// --------------------------------------------------
// 	// Public methods
// 	// --------------------------------------------------

// 	sync(query, vars) {
// 		return new Live(this, query, vars);
// 	}

// 	wait() {
// 		return this.#ws.ready.then( () => {
// 			return this.#attempted;
// 		});
// 	}

// 	close() {
// 		this.#ws.removeAllListeners();
// 		this.#ws.close();
// 	}

// 	// --------------------------------------------------

// 	ping() {
// 		let id = guid();
// 		return this.#ws.ready.then( () => {
// 			return new Promise( () => {
// 				this.#send(id, "ping");
// 			});
// 		});
// 	}

// 	use(ns, db) {
// 		let id = guid();
// 		return this.#ws.ready.then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#result(res, resolve, reject) );
// 				this.#send(id, "use", [ns, db]);
// 			});
// 		});
// 	}

// 	info() {
// 		let id = guid();
// 		return this.#ws.ready.then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#result(res, resolve, reject) );
// 				this.#send(id, "info");
// 			});
// 		});
// 	}

// 	signup(vars) {
// 		let id = guid();
// 		return this.#ws.ready.then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#signup(res, resolve, reject) );
// 				this.#send(id, "signup", [vars]);
// 			});
// 		});
// 	}

// 	signin(vars) {
// 		let id = guid();
// 		return this.#ws.ready.then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#signin(res, resolve, reject) );
// 				this.#send(id, "signin", [vars]);
// 			});
// 		});
// 	}

// 	invalidate() {
// 		let id = guid();
// 		return this.#ws.ready.then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#auth(res, resolve, reject) );
// 				this.#send(id, "invalidate");
// 			});
// 		});
// 	}

// 	authenticate(token) {
// 		let id = guid();
// 		return this.#ws.ready.then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#auth(res, resolve, reject) );
// 				this.#send(id, "authenticate", [token]);
// 			});
// 		});
// 	}

// 	// --------------------------------------------------

// 	live(table) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#result(res, resolve, reject) );
// 				this.#send(id, "live", [table]);
// 			});
// 		});
// 	}

// 	kill(query) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#result(res, resolve, reject) );
// 				this.#send(id, "kill", [query]);
// 			});
// 		});
// 	}

// 	let(key, val) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#result(res, resolve, reject) );
// 				this.#send(id, "let", [key, val]);
// 			});
// 		});
// 	}

// 	query(query, vars) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#result(res, resolve, reject) );
// 				this.#send(id, "query", [query, vars]);
// 			});
// 		});
// 	}

// 	select(thing) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#output(res, "select", thing, resolve, reject) );
// 				this.#send(id, "select", [thing]);
// 			});
// 		});
// 	}

// 	create(thing, data) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#output(res, "create", thing, resolve, reject) );
// 				this.#send(id, "create", [thing, data]);
// 			});
// 		});
// 	}

// 	update(thing, data) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#output(res, "update", thing, resolve, reject) );
// 				this.#send(id, "update", [thing, data]);
// 			});
// 		});
// 	}

// 	change(thing, data) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#output(res, "change", thing, resolve, reject) );
// 				this.#send(id, "change", [thing, data]);
// 			});
// 		});
// 	}

// 	modify(thing, data) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#output(res, "modify", thing, resolve, reject) );
// 				this.#send(id, "modify", [thing, data]);
// 			});
// 		});
// 	}

// 	delete(thing) {
// 		let id = guid();
// 		return this.wait().then( () => {
// 			return new Promise( (resolve, reject) => {
// 				this.once(id, res => this.#output(res, "delete", thing, resolve, reject) );
// 				this.#send(id, "delete", [thing]);
// 			});
// 		});
// 	}

// 	// --------------------------------------------------
// 	// Private methods
// 	// --------------------------------------------------

// 	#init() {
// 		this.#attempted = new Promise( (res, rej) => {
// 			this.#token ? this.authenticate(this.#token).then(res).catch(res) : res();
// 		});
// 	}

// 	#send(id, method, params=[]) {
// 		this.#ws.send(JSON.stringify({
// 			id: id,
// 			method: method,
// 			params: params,
// 		}));
// 	}

// 	#auth(res, resolve, reject) {
// 		if (res.error) {
// 			return reject( new Surreal.AuthenticationError(res.error.message) );
// 		} else {
// 			return resolve(res.result);
// 		}
// 	}

// 	#signin(res, resolve, reject) {
// 		if (res.error) {
// 			return reject( new Surreal.AuthenticationError(res.error.message) );
// 		} else {
// 			this.#token = res.result;
// 			return resolve(res.result);
// 		}
// 	}

// 	#signup(res, resolve, reject) {
// 		if (res.error) {
// 			return reject( new Surreal.AuthenticationError(res.error.message) );
// 		} else if (res.result) {
// 			this.#token = res.result;
// 			return resolve(res.result);
// 		}
// 	}

// 	#result(res, resolve, reject) {
// 		if (res.error) {
// 			return reject( new Error(res.error.message) );
// 		} else if (res.result) {
// 			return resolve(res.result);
// 		}
// 		return resolve();
// 	}

// 	#output(res, type, id, resolve, reject) {
// 		if (res.error) {
// 			return reject( new Error(res.error.message) );
// 		} else if (res.result) {
// 			switch (type) {
// 			case "delete":
// 				return resolve();
// 			case "create":
// 				return res.result && res.result.length ? resolve(res.result[0]) : reject(
// 					new Surreal.PermissionError(`Unable to create record: ${id}`)
// 				);
// 			case "update":
// 				if ( typeof id === "string" && id.includes(":") ) {
// 					return res.result && res.result.length ? resolve(res.result[0]) : reject(
// 						new Surreal.PermissionError(`Unable to update record: ${id}`)
// 					);
// 				} else {
// 					return resolve(res.result);
// 				}
// 			case "change":
// 				if ( typeof id === "string" && id.includes(":") ) {
// 					return res.result && res.result.length ? resolve(res.result[0]) : reject(
// 						new Surreal.PermissionError(`Unable to update record: ${id}`)
// 					);
// 				} else {
// 					return resolve(res.result);
// 				}
// 			case "modify":
// 				if ( typeof id === "string" && id.includes(":") ) {
// 					return res.result && res.result.length ? resolve(res.result[0]) : reject(
// 						new Surreal.PermissionError(`Unable to update record: ${id}`)
// 					);
// 				} else {
// 					return resolve(res.result);
// 				}
// 			default:
// 				if ( typeof id === "string" && id.includes(":") ) {
// 					return res.result && res.result.length ? resolve(res.result) : reject(
// 						new Surreal.RecordError(`Record not found: ${id}`)
// 					);
// 				} else {
// 					return resolve(res.result);
// 				}
// 			}
// 		}
// 		return resolve();
// 	}

// }

import 'dart:async';
import 'dart:convert';

import 'package:surrealdb_client/src/emitter.dart';
import 'package:surrealdb_client/src/id_generator.dart';
import 'package:surrealdb_client/src/live.dart';
import 'package:surrealdb_client/src/pinger.dart';
import 'package:surrealdb_client/src/socket.dart';
import 'package:surrealdb_client/src/surreal.dart';

class SurrealClient extends Emitter implements Surreal {
  late final Socket _ws;
  final String _url;
  final IdGenerator _generateId;
  Pinger? _pinger;
  Completer? _initCompleter;
  String _token = '';

  SurrealClient({
    required String url,
    String token = '',
    required IdGenerator idGenerator,
  })  : _url = url,
        _token = token,
        _generateId = idGenerator {
    connect(_url);
  }

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
      final event = jsonDecode(e);
      print('message: $e');

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

  Live synch(String query, Map<String, dynamic> vars) =>
      Live(db: this, sql: query, vars: vars);

  Future<void> wait() => _ws.ready;

  void close() {
    _ws.removeAllListeners(const []);
    _ws.close();
  }

  Future<void> ping() {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) async {
      _send(id, 'ping');
      completer.complete();
    });
    return completer.future;
  }

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

  Future use(String ns, String db) {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _result(res, completer));
      _send(id, 'use', [ns, db]);
    });
    return completer.future;
  }

  Future signIn(Map<String, dynamic> vars) {
    final id = _generateId();
    final completer = Completer();
    _ws.ready.then((_) {
      once(id, (res) => _signIn(res, completer));
      _send(id, 'signin', [vars]);
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
      // FIXME: Create SurrealAuthenticationException
      completer.completeError(Exception(res['error']['message']));
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

  void _signIn(dynamic res, Completer completer) {
    if (res['error'] != null) {
      // FIXME: Create SurrealAuthenticationException
      completer.completeError(Exception(res['error']['message']));
    } else {
      _token = res['result'];
      completer.complete(_token);
    }
  }
}
