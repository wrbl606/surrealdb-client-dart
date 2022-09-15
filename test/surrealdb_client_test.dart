import 'package:surrealdb_client/src/id_generator.dart';
import 'package:surrealdb_client/src/pinger.dart';
import 'package:test/test.dart';

void main() {
  test(
    'objectId generates unique ids',
    () {
      final numberOfUniqueIds = 0xFFFF;
      expect(List.generate(numberOfUniqueIds, (_) => objectId()).toSet().length,
          equals(numberOfUniqueIds));
    },
  );

  test(
    'Pinger runs function at the start of each interval',
    () async {
      int callCount = 0;
      void func() {
        callCount++;
      }

      final pinger = Pinger(interval: Duration(milliseconds: 100));

      pinger.start(func);
      await Future.delayed(const Duration(milliseconds: 350));
      expect(callCount, equals(3));
    },
  );
}
