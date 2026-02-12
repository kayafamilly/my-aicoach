import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TypingIndicator extends StatelessWidget {
  final bool isSearching;

  const TypingIndicator({super.key, this.isSearching = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSearching) ...[
                  Icon(Icons.travel_explore,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Searching...',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(width: 6),
                ],
                SpinKitThreeBounce(
                  color: theme.colorScheme.primary,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
