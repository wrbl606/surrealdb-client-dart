**Experimental** Dart support for [SurrealDB](https://surrealdb.com).
This package is a port of [surreal.js](https://github.com/surrealdb/surrealdb.js).

## Features

- `connect(url)` - Connects to a local or remote database endpoint
- `wait()` - Waits for the connection to the database to succeed
- `close()` - Closes the persistent connection to the database
- `use(ns, db)` - Switch to a specific namespace and database
- `signup(vars)` - Signs this connection up to a specific authentication scope
- `signin(vars)` - Signs this connection in to a specific authentication scope
- `invalidate()` - Invalidates the authentication for the current connection
- `authenticate(token)` - Authenticates the current connection with a JWT token
- `let(key, val)` - Assigns a value as a parameter for this connection
- `query(sql, vars)` - Runs a set of SurrealQL statements against the database
- `select(thing)` - Selects all records in a table, or a specific record
- `create(thing, data)` - Creates a record in the database
- `update(thing, data)` - Updates all records in a table, or a specific record
- `change(thing, data)` - Modifies all records in a table, or a specific record
- `modify(thing, data)` - Applies JSON Patch changes to all records in a table, or a specific record
- `delete(thing)` - Deletes all records, or a specific record

## Getting started

For installation instructions and SurrealQL introduction visit [SurrealDB docs](https://surrealdb.com/docs).

## Usage

```dart
  // Tell the client where to find your Surreal instance on the network.
  final client = SurrealClient(url: '...');
  
  // Sign in and specify which namespace and database client should be referring to.
  await client.signIn({'user': 'root', 'pass': 'root'});
  await client.use('test', 'test');

  // Create and read an article.
  await client.create('article', {'title': 'SurrealDB for Dart'});
  print(await client.select('article'));
  
  // Close the connection.
  client.close();
```

## Additional information

This is a 3rd-party integration which happens to also be an experimental one.
Keep that in mind when considering this package as a foundation of your project.

Contributions are welcome.

Planned improvements:

- [x] Add web support
- [ ] Add types to outputs
- [ ] Provide streams for client events
