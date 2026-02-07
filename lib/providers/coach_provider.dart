import 'package:flutter/material.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/services/coach_service.dart';

class CoachProvider extends ChangeNotifier {
  final CoachService _coachService;

  List<Coach> _coaches = [];
  List<Coach> _filteredCoaches = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<Coach> get coaches => _filteredCoaches;
  bool get isLoading => _isLoading;

  CoachProvider(this._coachService) {
    loadCoaches();
  }

  Future<void> loadCoaches() async {
    _isLoading = true;
    notifyListeners();

    try {
      _coaches = await _coachService.getAllCoaches();
      _applyFilter();
    } catch (e) {
      debugPrint('Error loading coaches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCoaches = List.from(_coaches);
    } else {
      _filteredCoaches = _coaches.where((coach) {
        return coach.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            coach.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> refresh() async {
    await loadCoaches();
  }
}
