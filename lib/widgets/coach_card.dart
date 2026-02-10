import 'package:flutter/material.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/widgets/premium_badge.dart';
import 'package:my_aicoach/widgets/coach_avatar.dart';

class CoachCard extends StatelessWidget {
  final Coach coach;
  final VoidCallback onTap;

  const CoachCard({
    super.key,
    required this.coach,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: CoachAvatar(
                      name: coach.name,
                      size: 64,
                      avatarUrl: coach.avatarUrl,
                    ),
                  ),
                  if (coach.isPremium)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: PremiumBadge(),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coach.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
