import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_aicoach/config/theme.dart';
import 'package:my_aicoach/config/routes.dart';
import 'package:my_aicoach/database/database.dart';
import 'package:my_aicoach/services/coach_service.dart';
import 'package:my_aicoach/services/chat_service.dart';
import 'package:my_aicoach/services/llm_service.dart';
import 'package:my_aicoach/services/purchase_service.dart';
import 'package:my_aicoach/services/notification_service.dart';
import 'package:my_aicoach/providers/coach_provider.dart';
import 'package:my_aicoach/providers/subscription_provider.dart';
import 'package:my_aicoach/providers/chat_provider.dart';
import 'package:my_aicoach/providers/theme_provider.dart';
import 'package:my_aicoach/providers/calendar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    await dotenv.load(fileName: ".env.example");
  }

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  // Initialize Database
  final database = AppDatabase();

  // Initialize RevenueCat (safe on non-mobile)
  await PurchaseService.init();

  // Initialize notifications
  await NotificationService.init();

  // Seed database
  final coachService = CoachService(database);
  await coachService.seedCoachesIfNeeded();

  final chatService = ChatService(database);
  final llmService = LLMService();

  runApp(
    MultiProvider(
      providers: [
        // Services (Dependencies)
        Provider<AppDatabase>.value(value: database),
        Provider<CoachService>.value(value: coachService),
        Provider<ChatService>.value(value: chatService),
        Provider<LLMService>.value(value: llmService),

        // State Providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProxyProvider<CoachService, CoachProvider>(
          create: (context) => CoachProvider(coachService),
          update: (context, service, previous) =>
              previous ?? CoachProvider(service),
        ),
        ChangeNotifierProxyProvider2<ChatService, LLMService, ChatProvider>(
          create: (context) => ChatProvider(chatService, llmService),
          update: (context, chatSvc, llmSvc, previous) =>
              previous ?? ChatProvider(chatSvc, llmSvc),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MyApp(
          showOnboarding: !hasSeenOnboarding,
          themeMode: themeProvider.themeMode,
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final ThemeMode themeMode;

  const MyApp(
      {super.key, required this.showOnboarding, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myAIcoach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: showOnboarding ? AppRoutes.onboarding : AppRoutes.home,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
