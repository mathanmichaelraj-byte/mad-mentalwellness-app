import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/behavior_tracker.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mood_history_screen.dart';
import 'screens/emotional_release_screen.dart';
import 'screens/calm_audio_screen.dart';
import 'screens/location_finder_screen.dart';
import 'screens/breathing_techniques_screen.dart';
import 'screens/login_screen.dart';
import 'screens/daily_mood_tracker_screen.dart';
import 'screens/mood_journal_screen.dart';
import 'screens/gratitude_journal_screen.dart';
import 'screens/affirmations_screen.dart';
import 'screens/sleep_tracker_screen.dart';
import 'screens/progress_dashboard_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  await NotificationService.instance.initialize();
  BehaviorTracker.instance.startSession();
  runApp(const MentalWellnessApp());
}

class MentalWellnessApp extends StatefulWidget {
  const MentalWellnessApp({super.key});

  @override
  State<MentalWellnessApp> createState() => _MentalWellnessAppState();
}

class _MentalWellnessAppState extends State<MentalWellnessApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      BehaviorTracker.instance.endSession();
    } else if (state == AppLifecycleState.resumed) {
      BehaviorTracker.instance.startSession();
    }
  }
  
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', newMode == ThemeMode.dark);
    setState(() {
      _themeMode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      toggleTheme: toggleTheme,
      themeMode: _themeMode,
      child: MaterialApp(
        title: 'Mental Wellness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: SplashScreen(),
        routes: {
          '/home': (context) => HomeScreen(),
          '/mood': (context) => MoodHistoryScreen(),
          '/release': (context) => EmotionalReleaseScreen(),
          '/audio': (context) => CalmAudioScreen(),
          '/location': (context) => LocationFinderScreen(),
          '/breathing': (context) => BreathingTechniquesScreen(),
          '/login': (context) => const LoginScreen(),
          '/mood_tracker': (context) => const DailyMoodTrackerScreen(),
          '/journal': (context) => const MoodJournalScreen(),
          '/gratitude': (context) => const GratitudeJournalScreen(),
          '/affirmations': (context) => const AffirmationsScreen(),
          '/sleep': (context) => const SleepTrackerScreen(),
          '/progress': (context) => const ProgressDashboardScreen(),
          '/notifications': (context) => const NotificationSettingsScreen(),
        },
      ),
    );
  }
}

class ThemeProvider extends InheritedWidget {
  final Function() toggleTheme;
  final ThemeMode themeMode;

  const ThemeProvider({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}