import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:my_aicoach/config/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'Your Personal AI Coach',
      description: 'Get personalized guidance for every aspect of your life, available 24/7.',
      icon: Icons.psychology,
      color: const Color(0xFF4A90E2),
    ),
    OnboardingPageModel(
      title: 'Expert Perspectives',
      description: 'Switch between different coaching styles: Life, Career, Fitness, and more.',
      icon: Icons.groups,
      color: const Color(0xFF50E3C2),
    ),
    OnboardingPageModel(
      title: 'Achieve Your Goals',
      description: 'Set goals, track progress, and unlock your full potential with AI-powered insights.',
      icon: Icons.rocket_launch,
      color: const Color(0xFFFF5252),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _isLastPage = index == _pages.length - 1;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(context, _pages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: theme.colorScheme.primary,
                      dotColor: theme.colorScheme.surfaceContainerHighest,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_isLastPage) {
                        await _completeOnboarding();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: Icon(_isLastPage ? Icons.check : Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, OnboardingPageModel page) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }
}

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
