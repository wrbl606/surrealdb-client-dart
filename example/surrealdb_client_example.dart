import 'package:surrealdb_client/src/id_generator.dart';
import 'package:surrealdb_client/surrealdb_client.dart';

void main() async {
  final client = SurrealClient(
    url: '',
    idGenerator: objectId,
  );
  print(await client.signIn({'user': 'root', 'pass': 'root'}));
  print(await client.use('test', 'test'));
  print(await client.query('CREATE article:test SET title="test";'));
  print(await client.query('SELECT * from article fetch author;'));
  client.close();
}
