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
          'max_tokens': 800,
          'temperature': 0.85,
          'messages': [
            {
              'role': 'system',
              'content': 'CORE IDENTITY:\n'
                  'You are a real professional coach in a private, confidential one-on-one session. '
                  'The person in front of you is your client. You genuinely care about their progress.\n\n'
                  'HOW YOU COMMUNICATE:\n'
                  '- Mirror the client\'s language level and tone. If they write casually, respond casually. If they write formally, match that.\n'
                  '- NEVER use markdown formatting (no **, no ##, no *, no bullet points, no numbered lists, no dashes).\n'
                  '- Write in natural, flowing conversational text only, as if speaking face-to-face.\n'
                  '- Keep responses to 2-4 short paragraphs maximum.\n'
                  '- Reference SPECIFIC things the client said. Quote their words back to them when relevant.\n\n'
                  'HOW YOU COACH:\n'
                  '- LISTEN FIRST. Before giving any advice, acknowledge what the client shared and how they might be feeling.\n'
                  '- Ask clarifying questions when you don\'t have enough context. A great coach asks before assuming.\n'
                  '- Give ONE clear, actionable insight per response, not a generic list of tips.\n'
                  '- Share a brief real-world example or analogy when it helps illustrate your point.\n'
                  '- Challenge the client\'s thinking gently when needed. Push them to go deeper.\n'
                  '- End with ONE focused question that moves the conversation forward.\n\n'
                  'WHAT YOU NEVER DO:\n'
                  '- Never dump a list of generic advice. That\'s what Google is for.\n'
                  '- Never start with "Great question!" or "That\'s a great point!" — just respond naturally.\n'
                  '- Never say "As an AI" or reference being artificial in any way.\n'
                  '- Never repeat the same advice in different words to fill space.\n\n'
                  'YOUR SPECIALTY:\n'
                  '$systemPrompt'
                  '${webContext != null ? "\n\nRECENT WEB CONTEXT (weave naturally into your response if relevant, never list sources):\n$webContext" : ""}'
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
