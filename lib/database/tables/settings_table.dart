import 'package:drift/drift.dart';

@DataClassName('Setting')
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}
