import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/emotional_inference_service.dart';
import '../models/emotional_confidence.dart';
// emotionalStateNeedsSupport is defined in emotional_inference_service.dart
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/optional_share_dialog.dart';
import '../widgets/ui_components.dart';
import '../services/behavior_tracker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  EmotionalState _currentState = EmotionalState.neutral;
  EmotionalConfidence? _confidence;
  bool _medicalGuidanceDismissed = false;
  String? _username;
  Map<String, dynamic>? _todayMood;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat(reverse: true);
    _fadeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmotionalState();
      _showDialogIfNeeded();
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final username = await AuthService.instance.currentUser;
    final todayMood = await DatabaseService.instance.getTodayMoodLog();
    if (mounted) setState(() { _username = username; _todayMood = todayMood; });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false,
      );
    }
  }

  Future<void> _showDialogIfNeeded() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) await OptionalShareDialog.show(context, autoShow: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEmotionalState({bool forceRefresh = false}) async {
    BehaviorTracker.instance.trackInteraction();
    if (forceRefresh) EmotionalInferenceService.instance.invalidateCache();
    final state = await EmotionalInferenceService.instance.inferEmotionalState();
    final confidence = await EmotionalInferenceService.instance.calculateConfidence();
    final todayMood = await DatabaseService.instance.getTodayMoodLog();
    if (mounted) {
      setState(() {
        _currentState = state;
        _confidence = confidence;
        _todayMood = todayMood;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final themeProvider = ThemeProvider.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      // Transparent app bar — sits on top of the gradient hero
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Reminders',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: Icon(
              themeProvider?.themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              color: Colors.white,
            ),
            onPressed: themeProvider?.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => OptionalShareDialog.show(context),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadEmotionalState(forceRefresh: true),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient Hero Header ──────────────────────────────
              _HeroHeader(username: _username, todayMood: _todayMood),

              // ── Body content ──────────────────────────────────────
              Padding(
                padding: r.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: r.hp(2)),
                    if (_confidence != null &&
                        emotionalStateNeedsSupport(_currentState) &&
                        _confidence!.canEscalateToMedical() &&
                        !_medicalGuidanceDismissed)
                      MedicalGuidanceCard(
                        fadeController: _fadeController,
                        onDismiss: () => setState(() => _medicalGuidanceDismissed = true),
                      ),
                    EmotionalStateCard(
                      state: _currentState,
                      confidence: _confidence,
                      fadeController: _fadeController,
                      pulseController: _pulseController,
                    ),
                    SizedBox(height: r.hp(3)),
                    Text('Wellness Tools', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Everything you need, in one place',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: r.hp(2)),
                    WellnessToolsList(),
                    SizedBox(height: r.hp(4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gradient Hero Header ──────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String? username;
  final Map<String, dynamic>? todayMood;
  const _HeroHeader({required this.username, required this.todayMood});

  static const _moods = [
    {'label': 'Sad',     'color': Color(0xFFB0BEC5)},
    {'label': 'Anxious', 'color': Color(0xFFFFCC80)},
    {'label': 'Neutral', 'color': Color(0xFF80DEEA)},
    {'label': 'Good',    'color': Color(0xFFA5D6A7)},
    {'label': 'Great',   'color': Color(0xFFCE93D8)},
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final logged = todayMood != null;
    final moodIdx = logged ? todayMood!['mood'] as int : null;
    final mood = moodIdx != null ? _moods[moodIdx] : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.gradientDeep,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: Stack(
          children: [
            // Large decorative circle — top right
            Positioned(
              top: -50, right: -40,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            // Medium circle — bottom left
            Positioned(
              bottom: -20, left: -50,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Small accent circle — top left
            Positioned(
              top: 60, left: 20,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App name row
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mental Wellness',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Greeting — large and bold
                    Text(
                      username != null ? '${_greeting()},\n$username' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your space for emotional well-being',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Mood card — frosted glass
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/mood_tracker'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              "TODAY'S MOOD",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.65),
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              logged ? (mood!['label'] as String) : 'Tap to log your mood',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: logged
                                    ? (mood!['color'] as Color)
                                    : Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ])),
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Icon(
                              logged ? Icons.check_rounded : Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
