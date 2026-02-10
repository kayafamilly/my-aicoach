import 'package:flutter/material.dart';
import 'package:my_aicoach/screens/onboarding/onboarding_screen.dart';
import 'package:my_aicoach/screens/home/home_screen.dart';
import 'package:my_aicoach/screens/coach_detail/coach_detail_screen.dart';
import 'package:my_aicoach/screens/chat/chat_screen.dart';
import 'package:my_aicoach/screens/create_coach/create_coach_screen.dart';
import 'package:my_aicoach/screens/paywall/paywall_screen.dart';
import 'package:my_aicoach/screens/profile/profile_screen.dart';
import 'package:my_aicoach/screens/legal/privacy_policy_screen.dart';
import 'package:my_aicoach/screens/legal/terms_of_service_screen.dart';
import 'package:my_aicoach/screens/legal/help_support_screen.dart';
import 'package:my_aicoach/screens/market/market_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String coachDetail = '/coach-detail';
  static const String chat = '/chat';
  static const String createCoach = '/create-coach';
  static const String paywall = '/paywall';
  static const String profile = '/profile';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String helpSupport = '/help-support';
  static const String market = '/market';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        home: (context) => const HomeScreen(),
        createCoach: (context) => const CreateCoachScreen(),
        profile: (context) => const ProfileScreen(),
        privacyPolicy: (context) => const PrivacyPolicyScreen(),
        termsOfService: (context) => const TermsOfServiceScreen(),
        helpSupport: (context) => const HelpSupportScreen(),
        market: (context) => const MarketScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case coachDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CoachDetailScreen(),
        );
      case chat:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChatScreen(),
        );
      case paywall:
        final source = settings.arguments as String? ?? 'default';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PaywallScreen(source: source),
        );
      default:
        return null;
    }
  }
}
