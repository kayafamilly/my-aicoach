import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:my_aicoach/services/purchase_service.dart';
import 'package:my_aicoach/providers/subscription_provider.dart';
import 'package:my_aicoach/config/routes.dart';

class PaywallScreen extends StatefulWidget {
  final String source;

  const PaywallScreen({super.key, this.source = 'default'});

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
    final isFromMarket = widget.source == 'market';
    final isTrialExhausted = hasTrialStarted && !subProvider.canCreateCoach;

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
                    isFromMarket
                        ? 'Unlock the Community Market'
                        : 'Create Your Own AI Coaches',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFromMarket
                        ? 'Subscribe to Premium to browse and import coaches created by the community.'
                        : isTrialExhausted
                            ? 'You\'ve used your free trial coach. Subscribe to create unlimited coaches and access the Community Market.'
                            : 'Design custom coaches with your own expertise, personality, and even web search capabilities.',
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
                      theme, Icons.storefront, 'Access the Community Market'),
                  _buildFeatureItem(
                      theme, Icons.support_agent, 'Priority support'),
                  const SizedBox(height: 32),

                  // Subscription offerings from RevenueCat
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
                    // Offerings not available — show fallback
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off,
                              size: 40, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load subscription plans.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check your internet connection and try again.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _loadOfferings,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (!hasTrialStarted && !isFromMarket && !isTrialExhausted)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isPurchasing ? null : _startTrial,
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Start 7-Day Free Trial (1 coach)'),
                      ),
                    ),
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
}
