import 'package:drift/drift.dart';
import 'package:my_aicoach/database/tables/coaches_table.dart';

@DataClassName('Conversation')
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get coachId => integer().references(Coaches, #id)();
  TextColumn get title => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime()();
}
