import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Last updated: February 2026',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 24),
            _section(theme, 'Acceptance of Terms',
                'By downloading, installing, or using myAIcoach, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, please do not use the application.'),
            _section(theme, 'Description of Service',
                'myAIcoach is an AI-powered coaching application that provides conversational guidance across various domains including business, mental health, relationships, nutrition, finance, parenting, and personal development. The app offers both pre-built expert coaches and the ability to create custom AI coaches.'),
            _section(theme, 'AI Disclaimer',
                'myAIcoach is powered by artificial intelligence and is NOT a substitute for professional advice. The AI coaches are not licensed professionals. For medical, psychological, legal, or financial matters, always consult a qualified human professional. The app is designed for informational and self-improvement purposes only. We are not liable for any decisions made based on AI-generated responses.'),
            _section(theme, 'Subscriptions & Payments',
                'myAIcoach offers a free tier with access to all pre-built coaches and the following premium options:\n\n'
                    '7-Day Free Trial — allows creation of 1 custom coach. After 7 days or 1 coach created, an upgrade is required for additional custom coaches.\n\n'
                    'Monthly Subscription — unlimited custom coach creation and web search features.\n\n'
                    'Yearly Subscription — same benefits as monthly at a discounted rate.\n\n'
                    'Subscriptions are managed through the Google Play Store. You can cancel anytime through your Play Store account settings. Cancellation takes effect at the end of the current billing period.'),
            _section(theme, 'User Conduct',
                'You agree not to use myAIcoach for any unlawful purpose, to generate harmful or abusive content, to attempt to reverse-engineer the application, or to misrepresent AI-generated content as professional advice to others.'),
            _section(theme, 'Intellectual Property',
                'The myAIcoach application, including its design, code, and content, is the intellectual property of KayaStudio. Custom coaches created by users remain their own, but the underlying technology and platform belong to KayaStudio.'),
            _section(theme, 'Limitation of Liability',
                'myAIcoach is provided "as is" without warranties of any kind. KayaStudio shall not be liable for any indirect, incidental, or consequential damages arising from the use of the application. Our total liability is limited to the amount you have paid for the service in the preceding 12 months.'),
            _section(theme, 'Changes to Terms',
                'We reserve the right to modify these terms at any time. Changes will be reflected in the app with an updated date. Continued use of the app after changes constitutes acceptance of the revised terms.'),
            _section(theme, 'Contact',
                'For questions about these terms, please contact us at support@kayastudio.dev.'),
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
