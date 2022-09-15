import 'package:surrealdb_client/surrealdb_client.dart';

void main() async {
  final client = SurrealClient(url: '');
  print(await client.signIn({'user': 'root', 'pass': 'root'}));
  print(await client.use('test', 'test'));
  print(await client.info());
  final article =
      await client.create('article', {'title': 'test client title'});
  print(
    await client.update(article['id'], {
      'title': 'Updated client title',
      'update': true,
    }),
  );
  print(
    await client.change(article['id'], {
      'title': 'Changed client title',
      'change': true,
    }),
  );
  print(
    await client.modify(article['id'], [
      {
        'op': 'replace',
        'path': '/title',
        'value': 'Modified client title',
      },
      {
        'op': 'add',
        'path': '/modify',
        'value': true,
      },
    ]),
  );
  print(await client.select('article'));
  await client.delete(article['id']);

  client.close();
}
