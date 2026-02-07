import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LLMService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OPENROUTER_API_KEY not found in .env');
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Chris/my-aicoach', // Required by OpenRouter
          'X-Title': 'myAIcoach', // Optional
        },
        body: jsonEncode({
          'model': 'openai/gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages,
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return content;
        } else {
          throw Exception('Empty response from LLM');
        }
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('LLM Service Error: $e');
    }
  }
}
