import 'package:objectid/objectid.dart';

typedef IdGenerator = String Function();
String objectId() => ObjectId().toString();
