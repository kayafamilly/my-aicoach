import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WebSearchService {
  static const String _baseUrl =
      'https://api.search.brave.com/res/v1/web/search';

  /// Searches the web using Brave Search API and returns a context string
  /// with the top results (title + snippet) ready to inject into an LLM prompt.
  /// Returns null if search fails or no API key is configured.
  static Future<String?> search(String query, {int count = 3}) async {
    try {
      final apiKey = dotenv.env['BRAVE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('BRAVE_API_KEY not found in .env');
        return null;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'count': count.toString(),
      });

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip',
        'X-Subscription-Token': apiKey,
      });

      if (response.statusCode != 200) {
        debugPrint('Brave Search error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final webResults = data['web']?['results'] as List<dynamic>?;

      if (webResults == null || webResults.isEmpty) return null;

      final buffer = StringBuffer();
      for (int i = 0; i < webResults.length && i < count; i++) {
        final result = webResults[i] as Map<String, dynamic>;
        final title = result['title'] as String? ?? '';
        final description = result['description'] as String? ?? '';
        buffer.writeln('${i + 1}. $title: $description');
      }

      return buffer.toString().trim();
    } catch (e) {
      debugPrint('Web search error: $e');
      return null;
    }
  }
}
