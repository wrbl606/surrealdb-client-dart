import 'package:surrealdb_client/src/emitter.dart';

abstract class Surreal extends Emitter {
  Future kill(String query);
  Future query(String query, Map<String, dynamic> vars);
}
