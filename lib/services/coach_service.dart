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

  // Seed default coaches if none exist
  Future<void> seedCoachesIfNeeded() async {
    final count = await _db.select(_db.coaches).get().then((l) => l.length);
    if (count == 0) {
      try {
        final String response =
            await rootBundle.loadString('assets/seed_coaches.json');
        final List<dynamic> data = json.decode(response);

        for (var item in data) {
          await _db.into(_db.coaches).insert(
                CoachesCompanion(
                  name: Value(item['name']),
                  description: Value(item['description']),
                  systemPrompt: Value(item['systemPrompt']),
                  avatarUrl: Value(item['avatarUrl']),
                  isPremium: Value(item['isPremium'] ?? false),
                  isCustom: const Value(false),
                ),
              );
        }
        debugPrint('Coaches seeded successfully');
      } catch (e) {
        debugPrint('Error seeding coaches: $e');
      }
    }
  }
}
