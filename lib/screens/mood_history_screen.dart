import 'package:flutter/material.dart';
import '../services/emotional_inference_service.dart';
import '../services/database_service.dart';
import '../services/behavior_tracker.dart';
import '../models/behavior_pattern.dart';
import '../models/emotional_confidence.dart';
import '../utils/app_theme.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen>
    with SingleTickerProviderStateMixin {
  EmotionalState? _currentState;
  EmotionalConfidence? _confidence;
  List<BehaviorPattern> _patterns = [];
  bool _loading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    BehaviorTracker.instance.trackInteraction();
    setState(() => _loading = true);
    if (forceRefresh) EmotionalInferenceService.instance.invalidateCache();
    final state = await EmotionalInferenceService.instance.inferEmotionalState();
    final confidence = await EmotionalInferenceService.instance.calculateConfidence();
    final patterns = await DatabaseService.instance.getRecentBehaviorPatterns(days: 7);
    if (mounted) {
      setState(() {
        _currentState = state;
        _confidence = confidence;
        _patterns = patterns;
        _loading = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Emotional Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _animationController.reset();
              _loadData(forceRefresh: true);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing your patterns...',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadData(forceRefresh: true),
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildCurrentStateCard(),
                    const SizedBox(height: 20),
                    _buildConfidenceCard(),
                    const SizedBox(height: 20),
                    _buildMetricsCard(),
                    const SizedBox(height: 20),
                    _buildHowItWorksCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Insights',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Understanding your emotional patterns over time',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStateCard() {
    if (_currentState == null) return const SizedBox();

    final stateColor = AppTheme.getStateColor(_currentState.toString());

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              stateColor.withOpacity(0.15),
              stateColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: stateColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: stateColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [stateColor, stateColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: stateColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(
                _getStateIcon(_currentState!),
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current State',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    EmotionalInferenceService.instance
                        .getStateDescription(_currentState!),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    if (_confidence == null) return const SizedBox();
    
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.1),
              AppTheme.success.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confidence Level',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getConfidenceColor(_confidence!.level),
                        _getConfidenceColor(_confidence!.level).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getConfidenceColor(_confidence!.level)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Text(
                    _confidence!.level.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _confidence!.score,
                backgroundColor: AppTheme.background(context),
                color: _getConfidenceColor(_confidence!.level),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),

            // Score info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_confidence!.score * 100).toStringAsFixed(0)}% confidence',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_confidence!.signalCount} signals',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Signals
            const Text(
              'Detected Signals',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),

            ..._confidence!.signals.map(
              (signal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatSignal(signal),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
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

  Widget _buildMetricsCard() {
    if (_patterns.isEmpty) {
      return FadeTransition(
        opacity: _animationController,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [AppTheme.shadow],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.gradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Building Your Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We need a few more days of data to show your behavioral patterns. Keep using the app!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Aggregate by day
    Map<String, List<BehaviorPattern>> dailyPatterns = {};
    for (var pattern in _patterns) {
      final day = pattern.timestamp.toIso8601String().split('T')[0];
      dailyPatterns.putIfAbsent(day, () => []).add(pattern);
    }

    int lateNightSessions = 0;
    int totalScreenTime = 0;

    for (var pattern in _patterns) {
      if (pattern.timeOfDay == 'lateNight') lateNightSessions++;
      totalScreenTime += pattern.screenTimeSeconds;
    }

    double avgDailySessions = _patterns.length / dailyPatterns.length;
    double lateNightPercent = (_patterns.isEmpty ? 0 : lateNightSessions / _patterns.length) * 100;
    int avgScreenTime = _patterns.isEmpty ? 0 : totalScreenTime ~/ _patterns.length;

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.1),
              AppTheme.success.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            _buildMetricRow(
              'Daily Sessions',
              avgDailySessions.toStringAsFixed(1),
              Icons.phone_android,
              AppTheme.gradient,
            ),
            _buildMetricRow(
              'Late Night Usage',
              '${lateNightPercent.toStringAsFixed(0)}%',
              Icons.nightlight_round,
              AppTheme.gradient,
            ),
            _buildMetricRow(
              'Avg Session Time',
              '${avgScreenTime}s',
              Icons.timer,
              AppTheme.gradient,
            ),
            _buildMetricRow(
              'Total Sessions',
              _patterns.length.toString(),
              Icons.insights,
              AppTheme.gradient,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Gradient gradient, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.1),
              AppTheme.success.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'How We Calculate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildStep('Track app usage patterns automatically'),
            _buildStep('Analyze time-of-day and frequency'),
            _buildStep('Calculate confidence from multiple signals'),
            _buildStep('Infer emotional state from patterns'),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppTheme.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All analysis is done locally on your device. No data is sent anywhere.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward,
              size: 14,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStateIcon(EmotionalState state) {
    switch (state) {
      case EmotionalState.calm:
        return Icons.self_improvement;
      case EmotionalState.restless:
        return Icons.trending_up;
      case EmotionalState.stressed:
        return Icons.warning_amber_rounded;
      case EmotionalState.lowEnergy:
        return Icons.battery_2_bar;
      case EmotionalState.distressed:
        return Icons.emergency;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getConfidenceColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.low:
        return AppTheme.textSecondary(context);
      case ConfidenceLevel.medium:
        return AppTheme.success;
      case ConfidenceLevel.high:
        return AppTheme.primary;
    }
  }

  String _formatSignal(String signal) {
    return signal
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
