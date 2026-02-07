import 'package:flutter/material.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/services/chat_service.dart';
import 'package:my_aicoach/services/llm_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final LLMService _llmService;

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get error => _error;

  ChatProvider(this._chatService, this._llmService);

  Future<void> loadMessages(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _chatService.getMessages(conversationId);
    } catch (e) {
      _error = 'Failed to load messages';
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required int conversationId,
    required String content,
    required String systemPrompt,
  }) async {
    if (content.trim().isEmpty) return;

    _error = null;

    // Add user message immediately
    try {
      await _chatService.addUserMessage(conversationId, content);
      await loadMessages(conversationId);
    } catch (e) {
      _error = 'Failed to send message';
      notifyListeners();
      return;
    }

    _isTyping = true;
    notifyListeners();

    try {
      final history = await _chatService.getRecentMessages(conversationId);
      final messagesMap = history
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      final response = await _llmService.sendMessage(
        systemPrompt: systemPrompt,
        messages: messagesMap,
      );

      await _chatService.addAssistantMessage(conversationId, response);
      await loadMessages(conversationId);
    } catch (e) {
      _error = 'Failed to get AI response. Please try again.';
      debugPrint('LLM Error: $e');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory(int conversationId) async {
    _error = null;
    await _chatService.clearConversation(conversationId);
    await loadMessages(conversationId);
  }
}
