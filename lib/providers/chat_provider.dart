import 'package:flutter/material.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/services/chat_service.dart';
import 'package:my_aicoach/services/llm_service.dart';
import 'package:my_aicoach/services/web_search_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final LLMService _llmService;

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isSearching = false;
  String? _error;
  String? _searchWarning;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String? get searchWarning => _searchWarning;

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
    bool enableWebSearch = false,
    String? imagePath,
    String? fileContext,
    String? calendarContext,
  }) async {
    if (content.trim().isEmpty && imagePath == null && fileContext == null)
      return;

    _error = null;

    // Add user message immediately (with optional image)
    try {
      await _chatService.addUserMessage(
        conversationId,
        content,
        imageUrl: imagePath,
      );
      await loadMessages(conversationId);
    } catch (e) {
      _error = 'Failed to send message';
      notifyListeners();
      return;
    }

    _isTyping = true;
    _searchWarning = null;
    notifyListeners();

    try {
      // Perform web search if enabled
      String? webContext;
      if (enableWebSearch) {
        _isSearching = true;
        notifyListeners();
        webContext = await WebSearchService.search(content);
        _isSearching = false;
        notifyListeners();
        if (webContext == null) {
          _searchWarning = WebSearchService.lastError ?? 'Web search failed';
          debugPrint('ChatProvider: search warning: $_searchWarning');
        }
      }

      // Encode image if provided
      String? imageBase64;
      if (imagePath != null) {
        imageBase64 = await LLMService.imageToBase64(imagePath);
      }

      final history = await _chatService.getRecentMessages(conversationId);
      final messagesMap = history
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      debugPrint(
          'ChatProvider: fileContext=${fileContext != null ? '${fileContext.length} chars' : 'null'}, webContext=${webContext != null ? '${webContext.length} chars' : 'null'}');

      final response = await _llmService.sendMessage(
        systemPrompt: systemPrompt,
        messages: messagesMap,
        webContext: webContext,
        imageBase64: imageBase64,
        fileContext: fileContext,
        calendarContext: calendarContext,
      );

      await _chatService.addAssistantMessage(conversationId, response);
      await loadMessages(conversationId);
    } catch (e) {
      _error = 'Failed to get AI response. Please try again.';
      debugPrint('LLM Error: $e');
    } finally {
      _isTyping = false;
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearchWarning() {
    _searchWarning = null;
    notifyListeners();
  }

  Future<void> clearHistory(int conversationId) async {
    _error = null;
    await _chatService.clearConversation(conversationId);
    await loadMessages(conversationId);
  }
}
