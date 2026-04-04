import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../utils/app_theme.dart';

const _quotes = [
  '"You are allowed to be both a masterpiece\nand a work in progress."',
  '"Be gentle with yourself.\nYou are a child of the universe."',
  '"Every day is a new beginning.\nTake a deep breath and start again."',
  '"Your feelings are valid.\nYour journey matters."',
  '"Small steps every day\nlead to big changes over time."',
];

class _Page {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_Bullet> bullets;
  const _Page({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.bullets,
  });
}

class _Bullet {
  final IconData icon;
  final String text;
  const _Bullet(this.icon, this.text);
}

final _pages = [
  _Page(
    title: 'Welcome',
    subtitle: 'Your personal companion\nfor emotional well-being',
    icon: Icons.favorite_rounded,
    accent: AppTheme.primary,
    bullets: [
      _Bullet(Icons.lock_outline_rounded, 'All data stays on your device'),
      _Bullet(Icons.psychology_rounded, 'Understands you without intrusive questions'),
      _Bullet(Icons.auto_awesome_rounded, 'Adapts to your daily patterns'),
    ],
  ),
  _Page(
    title: 'Emotional Tracking',
    subtitle: 'We quietly learn your patterns\nso you don\'t have to',
    icon: Icons.insights_rounded,
    accent: AppTheme.primary,
    bullets: [
      _Bullet(Icons.access_time_rounded, 'Tracks usage time & session patterns'),
      _Bullet(Icons.speed_rounded, 'Monitors interaction speed & frequency'),
      _Bullet(Icons.emoji_emotions_rounded, 'Detects 6 emotional states automatically'),
    ],
  ),
  _Page(
    title: 'Share Your Feelings',
    subtitle: 'Express yourself whenever\nyou feel ready',
    icon: Icons.edit_note_rounded,
    accent: AppTheme.primary,
    bullets: [
      _Bullet(Icons.notifications_none_rounded, 'Gentle daily check-in prompt'),
      _Bullet(Icons.touch_app_rounded, 'Tap the FAB anytime to open it'),
      _Bullet(Icons.sentiment_satisfied_alt_rounded, 'Positive, neutral & negative sentiment analysis'),
    ],
  ),
  _Page(
    title: 'Calm Audio',
    subtitle: 'Soothing sounds to help\nyou relax and reset',
    icon: Icons.music_note_rounded,
    accent: AppTheme.primary,
    bullets: [
      _Bullet(Icons.headphones_rounded, 'Curated calming audio tracks'),
      _Bullet(Icons.loop_rounded, 'Seamless looping for deep focus'),
      _Bullet(Icons.offline_bolt_rounded, 'Works fully offline'),
    ],
  ),
  _Page(
    title: 'Breathing Techniques',
    subtitle: '6 guided techniques to\ncalm your nervous system',
    icon: Icons.air_rounded,
    accent: AppTheme.primary,
    bullets: [
      _Bullet(Icons.timer_rounded, 'Animated timers for each phase'),
      _Bullet(Icons.format_list_numbered_rounded, 'Box, 4-7-8, deep breathing & more'),
      _Bullet(Icons.self_improvement_rounded, 'Reduces stress in under 5 minutes'),
    ],
  ),
  _Page(
    title: 'Find Calm Places',
    subtitle: 'Discover nearby spaces\nthat support your well-being',
    icon: Icons.location_on_rounded,
    accent: AppTheme.primary,
    bullets: [
      _Bullet(Icons.local_hospital_rounded, 'Therapists & mental health centers'),
      _Bullet(Icons.park_rounded, 'Parks & nature spots near you'),
      _Bullet(Icons.map_rounded, 'Powered by OpenStreetMap'),
    ],
  ),
  _Page(
    title: 'You\'re All Set',
    subtitle: 'Your wellness journey\nstarts right now',
    icon: Icons.rocket_launch_rounded,
    accent: AppTheme.primary,
    bullets: [
      _Bullet(Icons.privacy_tip_rounded, '100% private — no cloud, no sharing'),
      _Bullet(Icons.refresh_rounded, 'Pull to refresh your emotional state anytime'),
      _Bullet(Icons.favorite_border_rounded, 'We\'re here for you, every step of the way'),
    ],
  ),
];

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  int _quoteIndex = 0;
  Timer? _quoteTimer;

  // Quote fade
  late final AnimationController _quoteCtrl;
  late final Animation<double> _quoteFade;

  // Per-page content animation
  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _quoteCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _quoteFade = CurvedAnimation(parent: _quoteCtrl, curve: Curves.easeInOut);
    _quoteCtrl.forward();
    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (_) => _nextQuote());

    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    _contentCtrl.forward();
  }

  void _nextQuote() async {
    await _quoteCtrl.reverse();
    if (!mounted) return;
    setState(() => _quoteIndex = (_quoteIndex + 1) % _quotes.length);
    _quoteCtrl.forward();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _contentCtrl.reset();
    _contentCtrl.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => HomeScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _quoteCtrl.dispose();
    _contentCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withOpacity(0.10),
              AppTheme.background(context),
              AppTheme.primaryLight.withOpacity(0.06),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Quote banner ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FadeTransition(
                  opacity: _quoteFade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      _quotes[_quoteIndex],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary(context),
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ),

                  // Page swipe area
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, index) => _PageContent(
                    page: _pages[index],
                    contentFade: _contentFade,
                    contentSlide: _contentSlide,
                  ),
                ),
              ),

              // ── Dot indicators ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primary
                          : AppTheme.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // ── Buttons ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Skip (hidden on last page)
                    if (!isLast)
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    if (!isLast) const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          key: ValueKey(isLast),
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                            ),
                          ),
                          child: Text(
                            isLast ? '✨ Get Started' : 'Next  →',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Per-page content widget ──────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _Page page;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;

  const _PageContent({
    required this.page,
    required this.contentFade,
    required this.contentSlide,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: contentFade,
      child: SlideTransition(
        position: contentSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [page.accent, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: page.accent.withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(page.icon, size: 52, color: Colors.white),
              ),

              const SizedBox(height: 28),

              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary(context),
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 28),

              // Feature bullets
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Column(
                  children: page.bullets
                      .asMap()
                      .entries
                      .map((e) => _BulletRow(bullet: e.value, index: e.key))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final _Bullet bullet;
  final int index;

  const _BulletRow({required this.bullet, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 120),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: index < 2 ? 14 : 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(bullet.icon, size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                bullet.text,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
