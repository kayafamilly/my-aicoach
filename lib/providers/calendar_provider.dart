import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:my_aicoach/services/calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isLoading = false;
  List<gcal.Event> _todayEvents = [];
  List<gcal.Event> _upcomingEvents = [];
  String? _userEmail;

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  List<gcal.Event> get todayEvents => _todayEvents;
  List<gcal.Event> get upcomingEvents => _upcomingEvents;
  String? get userEmail => _userEmail;
  String? get lastError => CalendarService.lastError;

  CalendarProvider() {
    _trySilentSignIn();
  }

  Future<void> _trySilentSignIn() async {
    final success = await CalendarService.silentSignIn();
    if (success) {
      _isConnected = true;
      _userEmail = CalendarService.userEmail;
      await refreshEvents();
    }
    notifyListeners();
  }

  Future<bool> connect() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await CalendarService.signIn();
      _isConnected = success;
      if (success) {
        _userEmail = CalendarService.userEmail;
        await refreshEvents();
      }
      return success;
    } catch (e) {
      debugPrint('Calendar connect error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await CalendarService.signOut();
    _isConnected = false;
    _userEmail = null;
    _todayEvents = [];
    _upcomingEvents = [];
    notifyListeners();
  }

  Future<void> refreshEvents() async {
    if (!_isConnected) return;

    _isLoading = true;
    notifyListeners();

    try {
      _todayEvents = await CalendarService.getTodayEvents();
      _upcomingEvents = await CalendarService.getUpcomingEvents();
    } catch (e) {
      debugPrint('Error refreshing events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<gcal.Event?> createEvent({
    required String summary,
    String? description,
    required DateTime start,
    required DateTime end,
  }) async {
    final event = await CalendarService.createEvent(
      summary: summary,
      description: description,
      start: start,
      end: end,
    );
    if (event != null) {
      await refreshEvents();
    }
    return event;
  }

  String getCalendarContext() {
    if (!_isConnected || _todayEvents.isEmpty) return '';
    return CalendarService.formatEventsForContext(_todayEvents);
  }
}
