import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:my_aicoach/services/purchase_service.dart';
import 'package:my_aicoach/providers/subscription_provider.dart';

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
      await PurchaseService.purchasePackage(package);
      if (mounted) {
        Provider.of<SubscriptionProvider>(context, listen: false).checkStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Purchase successful! Welcome to Premium.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
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
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    'Unlock Premium Features',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get access to all coaches and create your own custom AI coaches.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color:
                            theme.textTheme.bodyLarge?.color?.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureItem(
                      theme, Icons.lock_open, 'Access all premium coaches'),
                  _buildFeatureItem(theme, Icons.add_circle,
                      'Create unlimited custom coaches'),
                  _buildFeatureItem(
                      theme, Icons.history, 'Unlimited conversation history'),
                  _buildFeatureItem(
                      theme, Icons.support_agent, 'Priority support'),
                  const SizedBox(height: 32),
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
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Premium - \$4.99/month',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '(Sandbox mode - no real purchase)',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isPurchasing
                                  ? null
                                  : () {
                                      Provider.of<SubscriptionProvider>(context,
                                              listen: false)
                                          .setTestPremium(true);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Premium activated (Test Mode)')),
                                      );
                                      Navigator.pop(context);
                                    },
                              child: const Text('Activate Premium (Test Mode)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isPurchasing ? null : _restore,
                    child: const Text('Restore Purchases'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Terms of Service • Privacy Policy',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
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
