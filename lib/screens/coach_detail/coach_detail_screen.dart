import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/config/routes.dart';
import 'package:my_aicoach/services/chat_service.dart';
import 'package:my_aicoach/widgets/premium_badge.dart';

class CoachDetailScreen extends StatelessWidget {
  const CoachDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coach = ModalRoute.of(context)!.settings.arguments as Coach;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                coach.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  coach.avatarUrl != null
                      ? Image.asset(
                          coach.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.person,
                                size: 80,
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.person,
                              size: 80,
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7)
                        ],
                      ),
                    ),
                  ),
                  if (coach.isPremium)
                    const Positioned(
                        top: 100, right: 16, child: PremiumBadge(size: 32)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.name,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (coach.isCustom)
                    Chip(
                      label: const Text('Custom'),
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      labelStyle: TextStyle(
                          color: theme.colorScheme.onTertiaryContainer),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coach.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color
                          ?.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final chatService =
                            Provider.of<ChatService>(context, listen: false);
                        final conversation =
                            await chatService.getOrCreateConversation(coach.id);
                        if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: {
                              'coach': coach,
                              'conversationId': conversation.id
                            },
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Start Coaching Session'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
