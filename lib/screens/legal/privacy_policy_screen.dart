import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Last updated: February 2026',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 24),
            _section(theme, 'Data Storage',
                'myAIcoach stores all your data locally on your device using an encrypted SQLite database. Your conversations, custom coaches, and preferences never leave your phone unless explicitly required by a feature you use.'),
            _section(theme, 'Third-Party Services',
                'We use the following third-party services to provide app functionality:\n\n'
                    'OpenRouter API — processes your messages to generate AI coaching responses. Messages are sent securely and are not stored by OpenRouter beyond the duration of the request.\n\n'
                    'Brave Search API — when web search is enabled on a custom coach, your message is used as a search query. Brave Search does not track users or store personal data.\n\n'
                    'RevenueCat — manages in-app purchases and subscriptions. RevenueCat processes purchase data in accordance with their privacy policy.'),
            _section(theme, 'Data We Do NOT Collect',
                'We do not collect, store, or sell any personal information. We do not use analytics or tracking tools. We do not access your contacts, camera, microphone, or location.'),
            _section(theme, 'Your Rights',
                'You have full control over your data. All data is stored locally on your device. To delete all app data, simply uninstall the application. No account creation is required to use myAIcoach.'),
            _section(theme, 'Children\'s Privacy',
                'myAIcoach is not designed for children under 13. We do not knowingly collect information from children.'),
            _section(theme, 'Changes to This Policy',
                'We may update this privacy policy from time to time. Any changes will be reflected in the app with an updated date. Continued use of the app after changes constitutes acceptance of the revised policy.'),
            _section(theme, 'Contact',
                'If you have questions about this privacy policy, please contact us at support@kayastudio.dev.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
