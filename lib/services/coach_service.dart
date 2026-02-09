import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:my_aicoach/database/database.dart';

class CoachService {
  final AppDatabase _db;

  CoachService(this._db);

  // Get all coaches
  Future<List<Coach>> getAllCoaches() async {
    return await _db.select(_db.coaches).get();
  }

  // Get coach by ID
  Future<Coach?> getCoachById(int id) async {
    return await (_db.select(_db.coaches)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // Create custom coach
  Future<int> createCustomCoach({
    required String name,
    required String description,
    required String systemPrompt,
    String? avatarUrl,
  }) async {
    return await _db.into(_db.coaches).insert(
          CoachesCompanion(
            name: Value(name),
            description: Value(description),
            systemPrompt: Value(systemPrompt),
            avatarUrl: Value(avatarUrl),
            isCustom: const Value(true),
            isPremium: const Value(
                false), // Custom coaches are created by user, so not "locked"
          ),
        );
  }

  // Seed default coaches and clean up removed ones
  Future<void> seedCoachesIfNeeded() async {
    try {
      final String response =
          await rootBundle.loadString('assets/seed_coaches.json');
      final List<dynamic> data = json.decode(response);

      // Collect valid seed names for cleanup
      final seedNames = <String>{};

      for (final item in data) {
        final name = (item['name'] as String?)?.trim();
        if (name == null || name.isEmpty) continue;
        seedNames.add(name);

        final existing = await (_db.select(_db.coaches)
              ..where((t) => t.isCustom.equals(false) & t.name.equals(name)))
            .getSingleOrNull();

        final companion = CoachesCompanion(
          name: Value(name),
          description: Value(item['description'] as String? ?? ''),
          systemPrompt: Value(item['systemPrompt'] as String? ?? ''),
          avatarUrl: Value(item['avatarUrl'] as String?),
          isPremium: const Value(false),
          isCustom: const Value(false),
        );

        if (existing == null) {
          await _db.into(_db.coaches).insert(companion);
        } else {
          await (_db.update(_db.coaches)
                ..where((t) => t.id.equals(existing.id)))
              .write(companion);
        }
      }

      // Remove old seed coaches no longer in the seed list
      final allBuiltIn = await (_db.select(_db.coaches)
            ..where((t) => t.isCustom.equals(false)))
          .get();
      for (final coach in allBuiltIn) {
        if (!seedNames.contains(coach.name)) {
          await (_db.delete(_db.coaches)..where((t) => t.id.equals(coach.id)))
              .go();
          debugPrint('Removed old seed coach: ${coach.name}');
        }
      }

      debugPrint('Coaches seeded successfully');
    } catch (e) {
      debugPrint('Error seeding coaches: $e');
    }
  }
}
