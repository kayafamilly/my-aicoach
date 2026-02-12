import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LLMService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  String _buildSystemPrompt({
    required String systemPrompt,
    String? webContext,
    String? calendarContext,
  }) {
    final buffer = StringBuffer();

    buffer.write('CORE IDENTITY:\n'
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
        '- Never repeat the same advice in different words to fill space.\n\n');

    if (webContext != null && webContext.isNotEmpty) {
      buffer.write('WEB SEARCH MODE — RULES:\n'
          '1. I have searched the web for you. The results are provided below.\n'
          '2. Answer the user\'s question using ONLY the information from the search results.\n'
          '3. Cite your sources naturally: mention the source name and include the URL.\n'
          '4. Synthesize information from multiple results when possible for a complete answer.\n'
          '5. Do NOT invent or hallucinate information that is not in the results.\n'
          '6. Do NOT say "I can\'t browse the web" or "I searched but could not find" — you HAVE results, use them.\n'
          '7. If the results are only partially relevant, still share what you found and explain what is missing.\n\n');
    }

    if (calendarContext != null && calendarContext.isNotEmpty) {
      buffer.write('CALENDAR CONTEXT (the client\'s schedule today):\n'
          '$calendarContext\n'
          'Use this context naturally if relevant to the conversation. You can suggest scheduling, remind them of upcoming commitments, or help them plan around their calendar.\n\n');
    }

    buffer.write('YOUR SPECIALTY:\n$systemPrompt');

    if (webContext != null) {
      buffer.write(
          '\n\n=== WEB SEARCH RESULTS (mandatory: base your answer on these, cite titles and URLs) ===\n$webContext\n=== END OF RESULTS ===');
    }

    return buffer.toString();
  }

  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    String? webContext,
    String? imageBase64,
    String? fileContext,
    String? calendarContext,
  }) async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OPENROUTER_API_KEY not found in .env');
      }

      final systemContent = _buildSystemPrompt(
        systemPrompt: systemPrompt,
        webContext: webContext,
        calendarContext: calendarContext,
      );

      // Build messages list, converting the last user message to multimodal if image attached
      final apiMessages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemContent},
      ];

      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final isLastUser = i == messages.length - 1 && msg['role'] == 'user';

        if (isLastUser && (imageBase64 != null || fileContext != null)) {
          // Build multimodal content for the last user message
          final parts = <Map<String, dynamic>>[];

          if (imageBase64 != null) {
            parts.add({
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$imageBase64',
              },
            });
          }

          // Combine user text + file content directly in the message
          String userText = msg['content'] ?? '';
          if (fileContext != null) {
            userText +=
                '\n\n--- ATTACHED DOCUMENT CONTENT (read and analyze this) ---\n$fileContext\n--- END OF DOCUMENT ---';
          }
          parts.add({'type': 'text', 'text': userText});

          apiMessages.add({'role': 'user', 'content': parts});
        } else {
          apiMessages.add({'role': msg['role'], 'content': msg['content']});
        }
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Chris/my-aicoach',
          'X-Title': 'myAIcoach',
        },
        body: jsonEncode({
          'model': 'openai/gpt-4o-mini',
          'max_tokens': 800,
          'temperature': 0.85,
          'messages': apiMessages,
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

  static Future<String> imageToBase64(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    return base64Encode(bytes);
  }
}
