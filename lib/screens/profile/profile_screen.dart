import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aicoach/providers/subscription_provider.dart';
import 'package:my_aicoach/providers/theme_provider.dart';
import 'package:my_aicoach/providers/calendar_provider.dart';
import 'package:my_aicoach/config/routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        subscriptionProvider.isPremium
                            ? Icons.workspace_premium
                            : Icons.person,
                        color: subscriptionProvider.isPremium
                            ? Colors.amber
                            : theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscriptionProvider.isPremium
                                  ? 'Premium Member'
                                  : 'Free Plan',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              subscriptionProvider.isPremium
                                  ? 'You have access to all features'
                                  : subscriptionProvider.tier ==
                                          SubscriptionTier.trial
                                      ? 'Trial active — ${subscriptionProvider.trialDaysRemaining} days left'
                                      : 'Upgrade to create custom coaches',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!subscriptionProvider.isPremium) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.paywall),
                        child: const Text('Upgrade to Premium'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Integrations Section
          Text('Integrations',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Consumer<CalendarProvider>(
            builder: (context, calProvider, _) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.calendar_month,
                        color: calProvider.isConnected
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                      title: Text(calProvider.isConnected
                          ? 'Google Calendar Connected'
                          : 'Connect Google Calendar'),
                      subtitle: Text(calProvider.isConnected
                          ? calProvider.userEmail ?? 'Connected'
                          : 'Sync your schedule with your coach'),
                      trailing: calProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : calProvider.isConnected
                              ? TextButton(
                                  onPressed: () => calProvider.disconnect(),
                                  child: const Text('Disconnect'),
                                )
                              : const Icon(Icons.chevron_right),
                      onTap: calProvider.isConnected || calProvider.isLoading
                          ? null
                          : () async {
                              final ok = await calProvider.connect();
                              if (!ok && context.mounted) {
                                final err = calProvider.lastError ??
                                    'Connection failed.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            },
                    ),
                    if (calProvider.lastError != null &&
                        !calProvider.isConnected)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                calProvider.lastError!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Settings Section
          Text('Settings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text('Appearance'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (selection) {
                          themeProvider.setThemeMode(selection.first);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          Text('About',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  trailing: Text('1.0.0',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.termsOfService),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Made with ❤️ by KayaStudio',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
