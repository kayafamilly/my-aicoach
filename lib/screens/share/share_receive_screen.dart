import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/providers/coach_provider.dart';
import 'package:my_aicoach/services/chat_service.dart';
import 'package:my_aicoach/config/routes.dart';

class ShareReceiveScreen extends StatelessWidget {
  final String? sharedText;
  final String? sharedImagePath;

  const ShareReceiveScreen({
    super.key,
    this.sharedText,
    this.sharedImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coachProvider = Provider.of<CoachProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share with Coach'),
      ),
      body: Column(
        children: [
          // Preview of shared content
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shared content',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 8),
                if (sharedText != null)
                  Text(
                    sharedText!.length > 200
                        ? '${sharedText!.substring(0, 200)}...'
                        : sharedText!,
                    style: theme.textTheme.bodyMedium,
                  ),
                if (sharedImagePath != null)
                  const Row(
                    children: [
                      Icon(Icons.image, size: 20),
                      SizedBox(width: 8),
                      Text('Image attached'),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Choose a coach',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: coachProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: coachProvider.coaches.length,
                    itemBuilder: (context, index) {
                      final coach = coachProvider.coaches[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(Icons.person,
                                color:
                                    theme.colorScheme.onPrimaryContainer),
                          ),
                          title: Text(coach.name),
                          subtitle: Text(
                            coach.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _openChatWithCoach(context, coach),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithCoach(BuildContext context, Coach coach) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final conversation = await chatService.getOrCreateConversation(coach.id);

    if (context.mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.chat,
        arguments: {
          'coach': coach,
          'conversationId': conversation.id,
          'sharedText': sharedText,
          'sharedImagePath': sharedImagePath,
        },
      );
    }
  }
}
