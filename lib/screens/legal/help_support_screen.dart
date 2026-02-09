import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Help & Support',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // FAQ
            Text('Frequently Asked Questions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _faqItem(theme, 'How do I use a coach?',
                'Simply tap on any coach from the home screen to view their profile, then start a conversation. Each coach is specialized in their domain and will guide you through a professional coaching session.'),

            _faqItem(theme, 'How do I create a custom coach?',
                'Tap the "Create" tab at the bottom of the screen. You will be guided through 3 steps: define your coach\'s identity and tone, set their expertise and boundaries, then review the auto-generated prompt. You can also enable web search for real-time information.'),

            _faqItem(theme, 'What is the 7-day free trial?',
                'The free trial lets you create 1 custom coach for 7 days. After the trial ends or after creating 1 coach, you will need to upgrade to a Monthly or Yearly plan to create more custom coaches. All pre-built coaches remain free forever.'),

            _faqItem(theme, 'How do I manage my subscription?',
                'Go to your device\'s Google Play Store app, tap your profile icon, then "Payments & subscriptions" and "Subscriptions." From there you can change or cancel your myAIcoach subscription.'),

            _faqItem(theme, 'What does "Web Search" do?',
                'When enabled on a custom coach, the app searches the internet for up-to-date information related to your message before generating a response. This allows your coach to reference current data, news, or trends in their answers.'),

            _faqItem(theme, 'How do I delete my data?',
                'All data is stored locally on your device. To delete everything, simply uninstall the app. No data is stored on external servers.'),

            _faqItem(theme, 'Are the AI coaches real professionals?',
                'No. The coaches are powered by artificial intelligence and are designed to simulate professional coaching conversations. They are not licensed professionals. For serious medical, legal, psychological, or financial matters, always consult a qualified human professional.'),

            const SizedBox(height: 32),
            Text('Contact Us',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'If you need further assistance or have feedback, reach out to us at:',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            SelectableText('support@kayastudio.dev',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Center(
              child: Text('We typically respond within 24-48 hours.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(ThemeData theme, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(question,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(answer, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
