import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:my_aicoach/services/purchase_service.dart';
import 'package:my_aicoach/providers/subscription_provider.dart';
import 'package:my_aicoach/config/routes.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    try {
      _offerings = await PurchaseService.getOfferings();
    } catch (e) {
      debugPrint('Error loading offerings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isPurchasing = true);
    try {
      final completed = await PurchaseService.purchasePackage(package);
      if (!mounted) return;
      if (!completed) return;
      final subProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      await subProvider.checkStatus();
      if (!subProvider.isPremium) {
        subProvider.setTestPremium(true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Purchase successful! Welcome to Premium.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong. Please try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _startTrial() async {
    final subProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    await subProvider.startTrial();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Free trial started! You can create 1 custom coach.')),
    );
    Navigator.pop(context);
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      await Provider.of<SubscriptionProvider>(context, listen: false)
          .restorePurchases();
      if (mounted) {
        final isPremium =
            Provider.of<SubscriptionProvider>(context, listen: false).isPremium;
        if (isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No previous purchases found.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not restore purchases. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final hasTrialStarted = subProvider.tier == SubscriptionTier.trial;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.workspace_premium,
                      size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Create Your Own AI Coaches',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Design custom coaches with your own expertise, personality, and even web search capabilities.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color
                            ?.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureItem(theme, Icons.add_circle,
                      'Create unlimited custom AI coaches'),
                  _buildFeatureItem(
                      theme, Icons.tune, 'Fine-tune expertise & personality'),
                  _buildFeatureItem(
                      theme, Icons.language, 'Web search-enhanced responses'),
                  _buildFeatureItem(
                      theme, Icons.support_agent, 'Priority support'),
                  const SizedBox(height: 32),

                  // Real offerings from RevenueCat
                  if (_offerings?.current?.availablePackages.isNotEmpty == true)
                    ..._offerings!.current!.availablePackages
                        .map((package) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isPurchasing
                                      ? null
                                      : () => _purchase(package),
                                  style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16)),
                                  child: _isPurchasing
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Text(
                                          '${package.storeProduct.title} - ${package.storeProduct.priceString}'),
                                ),
                              ),
                            ))
                  else ...[
                    // Sandbox / test mode options
                    _buildPlanCard(
                      theme,
                      title: 'Monthly',
                      price: '\$4.99/mo',
                      subtitle: 'Unlimited custom coaches',
                      onTap: _isPurchasing
                          ? null
                          : () {
                              final sp = Provider.of<SubscriptionProvider>(
                                  context,
                                  listen: false);
                              sp.setTestPremium(true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Premium activated (Test Mode)')),
                              );
                              Navigator.pop(context);
                            },
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      theme,
                      title: 'Yearly',
                      price: '\$39.99/yr',
                      subtitle: 'Save 33% — best value',
                      highlight: true,
                      onTap: _isPurchasing
                          ? null
                          : () {
                              final sp = Provider.of<SubscriptionProvider>(
                                  context,
                                  listen: false);
                              sp.setTestPremium(true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Premium activated (Test Mode)')),
                              );
                              Navigator.pop(context);
                            },
                    ),
                    const SizedBox(height: 12),
                    if (!hasTrialStarted)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isPurchasing ? null : _startTrial,
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Start 7-Day Free Trial (1 coach)'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '(Sandbox mode — no real charge)',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isPurchasing ? null : _restore,
                    child: const Text('Restore Purchases'),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.termsOfService),
                    child: Text(
                      'Terms of Service • Privacy Policy',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    ThemeData theme, {
    required String title,
    required String price,
    required String subtitle,
    bool highlight = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: highlight ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highlight
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (highlight) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('BEST',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                Text(price,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
