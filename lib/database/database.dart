import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:my_aicoach/database/tables/coaches_table.dart';
import 'package:my_aicoach/database/tables/conversations_table.dart';
import 'package:my_aicoach/database/tables/messages_table.dart';
import 'package:my_aicoach/database/tables/settings_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Coaches, Conversations, Messages, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
