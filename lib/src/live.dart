import 'package:surrealdb_client/src/emitter.dart';
import 'package:surrealdb_client/src/surreal.dart';

class Live extends Emitter {
  String? _id;
  final Surreal _db;
  final String _sql;
  final List<String> _vars;

  Live({
    required Surreal db,
    required String sql,
    List<String> vars = const [],
  })  : _db = db,
        _sql = sql,
        _vars = vars {
    _db.on('opened', (_) => open());
    _db.on('closed', (_) => _id = null);
    _db.on('notify', (e) {
      if (e.query != _id) {
        return;
      }

      emit(e.action.toLowerCase(), e.result);
    });
  }

  // If we want to kill the live query
  // then we can kill it. Once a query
  // has been killed it can be opened
  // again by calling the open() method.
  Future kill() async {
    if (_id == null) {
      return Future.value();
    }

    final res = await _db.kill(_id!);
    _id = null;
    return res;
  }

  // If the live query has been manually
  // killed, then calling the open()
  // method will re-enable the query.
  Future open() async {
    if (_id != null) {
      return Future.value();
    }

    final result = await _db.query(_sql, _vars);
    _id = result?[0]?['result']?[0];
  }
}
