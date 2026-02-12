import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WebSearchService {
  static const String _baseUrl =
      'https://api.search.brave.com/res/v1/web/search';

  static String? lastError;

  /// Searches the web using Brave Search API and returns a context string
  /// with the top results (title + snippet + url) ready to inject into an LLM prompt.
  /// Returns null if search fails or no API key is configured.
  static Future<String?> search(String query, {int count = 5}) async {
    lastError = null;
    try {
      final apiKey = dotenv.env['BRAVE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        lastError = 'BRAVE_API_KEY not configured';
        debugPrint('WebSearch: $lastError');
        return null;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'count': count.toString(),
        'extra_snippets': 'true',
      });

      debugPrint('WebSearch: querying "$query"...');

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'X-Subscription-Token': apiKey,
      });

      debugPrint(
          'WebSearch: status=${response.statusCode}, bodyLen=${response.body.length}');

      if (response.statusCode != 200) {
        lastError = 'Brave API error ${response.statusCode}';
        debugPrint(
            'WebSearch: $lastError — ${response.body.substring(0, response.body.length.clamp(0, 200))}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final webResults = data['web']?['results'] as List<dynamic>?;

      if (webResults == null || webResults.isEmpty) {
        lastError = 'No results found';
        debugPrint('WebSearch: $lastError');
        return null;
      }

      debugPrint('WebSearch: got ${webResults.length} results');

      final buffer = StringBuffer();
      for (int i = 0; i < webResults.length && i < count; i++) {
        final result = webResults[i] as Map<String, dynamic>;
        final title = result['title'] as String? ?? '';
        final url = result['url'] as String? ?? '';
        final description = result['description'] as String? ?? '';
        buffer.writeln('${i + 1}. $title');
        buffer.writeln('   URL: $url');
        buffer.writeln('   $description');
        // Include extra snippets if available
        final extras = result['extra_snippets'] as List<dynamic>?;
        if (extras != null) {
          for (final snippet in extras) {
            buffer.writeln('   $snippet');
          }
        }
        buffer.writeln();
      }

      return buffer.toString().trim();
    } catch (e) {
      lastError = 'Search failed: $e';
      debugPrint('WebSearch: $lastError');
      return null;
    }
  }
}
