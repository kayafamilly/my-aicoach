import 'package:drift/drift.dart';
import 'package:my_aicoach/database/database.dart';

class ChatService {
  final AppDatabase _db;

  ChatService(this._db);

  // Get conversation for a coach (or create one if it doesn't exist for now, assuming 1 convo per coach)
  Future<Conversation> getOrCreateConversation(int coachId) async {
    final existing = await (_db.select(_db.conversations)
          ..where((t) => t.coachId.equals(coachId)))
        .getSingleOrNull();

    if (existing != null) {
      return existing;
    } else {
      final id = await _db.into(_db.conversations).insert(
            ConversationsCompanion(
              coachId: Value(coachId),
              lastMessageAt: Value(DateTime.now()),
            ),
          );
      return await (_db.select(_db.conversations)
            ..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }

  // Get messages for a conversation
  Future<List<Message>> getMessages(int conversationId) async {
    return await (_db.select(_db.messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  // Get recent messages for context (e.g. last 20)
  Future<List<Message>> getRecentMessages(int conversationId,
      {int limit = 20}) async {
    // Drift doesn't support easy limit/offset in reverse order with simple select,
    // but we can just get all and take last for now as local DB is fast.
    // Optimization: write custom query if needed.
    final all = await getMessages(conversationId);
    if (all.length > limit) {
      return all.sublist(all.length - limit);
    }
    return all;
  }

  // Add user message
  Future<void> addUserMessage(int conversationId, String content,
      {String? imageUrl}) async {
    await _db.into(_db.messages).insert(
          MessagesCompanion(
            conversationId: Value(conversationId),
            role: const Value('user'),
            content: Value(content),
            imageUrl: imageUrl != null ? Value(imageUrl) : const Value.absent(),
            createdAt: Value(DateTime.now()),
          ),
        );
    await _updateConversationTimestamp(conversationId);
  }

  // Add assistant message
  Future<void> addAssistantMessage(int conversationId, String content) async {
    await _db.into(_db.messages).insert(
          MessagesCompanion(
            conversationId: Value(conversationId),
            role: const Value('assistant'),
            content: Value(content),
            createdAt: Value(DateTime.now()),
          ),
        );
    await _updateConversationTimestamp(conversationId);
  }

  Future<void> _updateConversationTimestamp(int conversationId) async {
    await (_db.update(_db.conversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(
      ConversationsCompanion(
        lastMessageAt: Value(DateTime.now()),
      ),
    );
  }

  // Clear conversation history
  Future<void> clearConversation(int conversationId) async {
    await (_db.delete(_db.messages)
          ..where((t) => t.conversationId.equals(conversationId)))
        .go();
  }
}
