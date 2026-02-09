import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LLMService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    String? webContext,
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
          'HTTP-Referer':
              'https://github.com/Chris/my-aicoach', // Required by OpenRouter
          'X-Title': 'myAIcoach', // Optional
        },
        body: jsonEncode({
          'model': 'openai/gpt-4o-mini',
          'max_tokens': 300,
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content': 'IMPORTANT RULES YOU MUST ALWAYS FOLLOW:\n'
                  '- You are a professional coach in a private one-on-one session.\n'
                  '- NEVER use markdown formatting (no **, no ##, no *).\n'
                  '- NEVER use bullet points, numbered lists, or dashes.\n'
                  '- Write in plain conversational text only.\n'
                  '- Keep every response under 3 short paragraphs.\n'
                  '- Sound like a real human professional, not an AI.\n'
                  '- Be warm, empathetic, and concise.\n'
                  '- Ask one follow-up question at the end.\n\n'
                  '$systemPrompt'
                  '${webContext != null ? "\n\nRELEVANT WEB INFORMATION (use naturally if helpful, do not list sources):\n$webContext" : ""}'
            },
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
        throw Exception(
            'Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('LLM Service Error: $e');
    }
  }
}
