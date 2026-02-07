import 'package:drift/drift.dart';

@DataClassName('Coach')
class Coaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text()();
  TextColumn get systemPrompt => text()();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
