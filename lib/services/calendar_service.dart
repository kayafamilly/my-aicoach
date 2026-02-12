import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class CalendarService {
  static GoogleSignIn? _googleSignIn;
  static GoogleSignInAccount? _currentUser;
  static gcal.CalendarApi? _calendarApi;
  static String? _lastError;

  static bool get isConnected => _currentUser != null && _calendarApi != null;
  static String? get userEmail => _currentUser?.email;
  static String? get lastError => _lastError;

  static GoogleSignIn _getSignIn() {
    if (_googleSignIn == null) {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      _googleSignIn = GoogleSignIn(
        scopes: [gcal.CalendarApi.calendarScope],
        serverClientId: (webClientId != null && webClientId.isNotEmpty)
            ? webClientId
            : null,
      );
    }
    return _googleSignIn!;
  }

  static Future<bool> signIn() async {
    _lastError = null;
    try {
      final gsi = _getSignIn();
      _currentUser = await gsi.signIn();
      if (_currentUser == null) {
        _lastError = 'Sign-in cancelled.';
        return false;
      }

      final httpClient = await gsi.authenticatedClient();
      if (httpClient == null) {
        _lastError = 'Could not get authenticated client.';
        return false;
      }

      _calendarApi = gcal.CalendarApi(httpClient);
      return true;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _lastError = _parseError(e);
      return false;
    }
  }

  static Future<void> signOut() async {
    await _getSignIn().signOut();
    _currentUser = null;
    _calendarApi = null;
    _lastError = null;
  }

  static Future<bool> silentSignIn() async {
    try {
      final gsi = _getSignIn();
      _currentUser = await gsi.signInSilently();
      if (_currentUser == null) return false;

      final httpClient = await gsi.authenticatedClient();
      if (httpClient == null) return false;

      _calendarApi = gcal.CalendarApi(httpClient);
      return true;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return false;
    }
  }

  static String _parseError(dynamic e) {
    final msg = e.toString();
    // ApiException 10 = DEVELOPER_ERROR (SHA-1 / package mismatch)
    if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
      return 'OAuth config error: check SHA-1 fingerprint and package name '
          'in Google Cloud Console.';
    }
    // ApiException 12 = SIGN_IN_REQUIRED
    if (msg.contains('ApiException: 12')) {
      return 'Sign-in required. Please try again.';
    }
    // ApiException 7 = NETWORK_ERROR
    if (msg.contains('ApiException: 7') || msg.contains('NETWORK_ERROR')) {
      return 'Network error. Check your internet connection.';
    }
    // Generic PlatformException
    if (msg.contains('PlatformException')) {
      return 'Google Sign-In failed. Verify your Google Cloud Console setup.';
    }
    return 'Sign-in failed: $msg';
  }

  static Future<List<gcal.Event>> getUpcomingEvents(
      {int maxResults = 10}) async {
    if (_calendarApi == null) return [];

    try {
      final now = DateTime.now();
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: now.add(const Duration(days: 7)).toUtc(),
        maxResults: maxResults,
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  static Future<List<gcal.Event>> getTodayEvents() async {
    if (_calendarApi == null) return [];

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startOfDay.toUtc(),
        timeMax: endOfDay.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      debugPrint('Error fetching today events: $e');
      return [];
    }
  }

  static Future<gcal.Event?> createEvent({
    required String summary,
    String? description,
    required DateTime start,
    required DateTime end,
  }) async {
    if (_calendarApi == null) return null;

    try {
      final event = gcal.Event()
        ..summary = summary
        ..description = description
        ..start = (gcal.EventDateTime()..dateTime = start.toUtc())
        ..end = (gcal.EventDateTime()..dateTime = end.toUtc());

      return await _calendarApi!.events.insert(event, 'primary');
    } catch (e) {
      debugPrint('Error creating event: $e');
      return null;
    }
  }

  static Future<bool> deleteEvent(String eventId) async {
    if (_calendarApi == null) return false;

    try {
      await _calendarApi!.events.delete('primary', eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  static String formatEventsForContext(List<gcal.Event> events) {
    if (events.isEmpty) return 'No upcoming events.';

    final buffer = StringBuffer();
    for (final event in events) {
      final start = event.start?.dateTime ?? event.start?.date;
      final summary = event.summary ?? 'Untitled';
      if (start != null) {
        buffer.writeln('- $summary at $start');
      } else {
        buffer.writeln('- $summary');
      }
    }
    return buffer.toString();
  }
}
