import '../models/emotional_confidence.dart';
import '../models/behavior_pattern.dart';
import 'database_service.dart';
import '../utils/sentiment_analyzer.dart';

enum EmotionalState { calm, restless, stressed, lowEnergy, neutral, distressed }

/// Only distressed / stressed / restless warrant the support box.
bool emotionalStateNeedsSupport(EmotionalState state) =>
    state == EmotionalState.distressed ||
    state == EmotionalState.stressed ||
    state == EmotionalState.restless;

class EmotionalInferenceService {
  static final EmotionalInferenceService instance = EmotionalInferenceService._init();
  EmotionalInferenceService._init();

  // ── Shared cache — every screen reads the same value ─────────────────────
  EmotionalState? _cachedState;
  EmotionalConfidence? _cachedConfidence;
  DateTime? _lastComputed;
  static const _cacheTtl = Duration(minutes: 5);

  bool get _cacheValid =>
      _cachedState != null &&
      _lastComputed != null &&
      DateTime.now().difference(_lastComputed!) < _cacheTtl;

  /// Call this after saving a journal entry or emotional note so the next
  /// read recomputes from fresh data.
  void invalidateCache() {
    _cachedState = null;
    _cachedConfidence = null;
    _lastComputed = null;
  }

  Future<void> initializeML() async {}

  // ── Public API ────────────────────────────────────────────────────────────

  Future<EmotionalState> inferEmotionalState() async {
    if (_cacheValid) return _cachedState!;
    _cachedState = await _computeState();
    _cachedConfidence = await _computeConfidence();
    _lastComputed = DateTime.now();
    return _cachedState!;
  }

  Future<EmotionalConfidence> calculateConfidence() async {
    if (_cacheValid && _cachedConfidence != null) return _cachedConfidence!;
    await inferEmotionalState(); // fills both caches
    return _cachedConfidence!;
  }

  // ── State computation ─────────────────────────────────────────────────────

  Future<EmotionalState> _computeState() async {
    final patterns = await DatabaseService.instance.getRecentBehaviorPatterns(days: 3);
    final emotionalNotes = await DatabaseService.instance.getRecentEmotionalNotes(days: 3);
    final recentJournal = await _recentJournal(days: 3);

    if (patterns.isEmpty && emotionalNotes.isEmpty && recentJournal.isEmpty) {
      return EmotionalState.neutral;
    }

    // Behavior metrics
    final dailyPatterns = _groupByDay(patterns);
    int lateNight = 0, highSpeed = 0, shortS = 0;
    final List<int> sessionTimes = [];
    for (final p in patterns) {
      sessionTimes.add(p.screenTimeSeconds);
      if (p.timeOfDay == 'lateNight') lateNight++;
      if (p.interactionSpeed > 5) highSpeed++;
      if (p.screenTimeSeconds < 60) shortS++;
    }
    final dayCount = dailyPatterns.length.clamp(1, 99);
    final double avgOpens = patterns.length / dayCount;
    final double variance = _variance(sessionTimes.map((s) => s.toDouble()).toList());
    final double lateRatio = patterns.isEmpty ? 0 : lateNight / patterns.length;
    final double speedRatio = patterns.isEmpty ? 0 : highSpeed / patterns.length;
    final double shortRatio = patterns.isEmpty ? 0 : shortS / patterns.length;

    // NLP: emotional notes
    int negNotes = 0, posNotes = 0;
    double noteSum = 0.0;
    for (final note in emotionalNotes) {
      final s = SentimentAnalyzer.analyzeDetailed(note.content)['score'] as double;
      noteSum += s;
      if (s <= -2.0) negNotes++;
      else if (s >= 2.0) posNotes++;
    }

    // NLP: journal entries
    int negJ = 0, posJ = 0;
    double journalSum = 0.0;
    for (final e in recentJournal) {
      final score = _journalScore(e);
      journalSum += score;
      if (score <= -2.0) negJ++;
      else if (score >= 2.0) posJ++;
    }
    final double avgJournal = recentJournal.isEmpty ? 0 : journalSum / recentJournal.length;

    final int totalNeg = negNotes + negJ;
    final int totalPos = posNotes + posJ;
    final double combined = (noteSum + journalSum) /
        (emotionalNotes.length + recentJournal.length).clamp(1, 9999);

    // Rules
    if ((totalNeg >= 3 && combined < -1.5) ||
        (avgOpens > 10 && lateRatio > 0.5 && totalNeg >= 2) ||
        (avgJournal < -2.5 && negJ >= 2)) {
      return EmotionalState.distressed;
    }
    if ((totalNeg >= 2 && variance > 150) ||
        (avgOpens > 7 && speedRatio > 0.4 && combined < -0.5) ||
        (avgJournal < -1.5 && variance > 100)) {
      return EmotionalState.restless;
    }
    if ((lateRatio > 0.4 && avgOpens > 5) ||
        (totalNeg >= 2 && lateRatio > 0.3) ||
        (avgJournal < -1.0 && lateRatio > 0.2)) {
      return EmotionalState.stressed;
    }
    if ((avgOpens < 3 && shortRatio > 0.5) ||
        (avgOpens < 4 && totalNeg >= 1 && totalPos == 0) ||
        (avgJournal < -0.5 && avgOpens < 4)) {
      return EmotionalState.lowEnergy;
    }
    if ((totalPos >= 2 && combined > 0.5) ||
        (avgOpens >= 3 && avgOpens <= 6 && speedRatio < 0.3 &&
            variance < 150 && totalNeg == 0) ||
        (avgJournal > 1.5 && posJ >= 2)) {
      return EmotionalState.calm;
    }
    return EmotionalState.neutral;
  }

  // ── Confidence computation ────────────────────────────────────────────────

  Future<EmotionalConfidence> _computeConfidence() async {
    final patterns = await DatabaseService.instance.getRecentBehaviorPatterns(days: 7);
    final emotionalNotes = await DatabaseService.instance.getRecentEmotionalNotes(days: 7);
    final recentJournal = await _recentJournal(days: 7);

    if (patterns.isEmpty && emotionalNotes.isEmpty && recentJournal.isEmpty) {
      return EmotionalConfidence(
        level: ConfidenceLevel.low, score: 0.0, signalCount: 0,
        lastUpdated: DateTime.now(), signals: [],
      );
    }

    final dailyPatterns = _groupByDay(patterns);
    final List<String> signals = [];
    double score = 0.0;

    if (dailyPatterns.length >= 3) { signals.add('consistent_behavior_pattern'); score += 0.15; }

    final allTexts = [
      ...emotionalNotes.map((n) => n.content),
      ...recentJournal.map((e) => e['content'] as String? ?? ''),
    ].where((t) => t.isNotEmpty).toList();

    if (allTexts.length >= 2) {
      signals.add('frequent_emotional_expression'); score += 0.15;
      int negCount = 0, posCount = 0;
      double sentSum = 0.0;
      for (final t in allTexts) {
        final s = SentimentAnalyzer.analyzeDetailed(t)['score'] as double;
        sentSum += s;
        if (s <= -2.0) negCount++;
        else if (s >= 2.0) posCount++;
      }
      if (negCount >= 3 || (negCount >= 2 && sentSum < -3.0)) {
        signals.add('persistent_negative_sentiment'); score += 0.3;
      } else if (negCount >= 2) {
        signals.add('repeated_negative_sentiment'); score += 0.2;
      }
      if (allTexts.length >= 3 &&
          (negCount == allTexts.length || posCount == allTexts.length)) {
        signals.add('consistent_emotional_pattern'); score += 0.15;
      }
    }

    if (recentJournal.length >= 3) { signals.add('active_journaling'); score += 0.1; }

    final lateNight = patterns.where((p) => p.timeOfDay == 'lateNight').length;
    if (patterns.isNotEmpty && lateNight / patterns.length > 0.4) {
      signals.add('persistent_late_night_activity'); score += 0.2;
    }

    final dayCount = dailyPatterns.length.clamp(1, 99);
    final avgDaily = patterns.length / dayCount;
    if (avgDaily > 5) { signals.add('high_frequency_usage'); score += 0.15; }
    if (avgDaily > 7) { signals.add('elevated_app_usage'); score += 0.15; }

    if (_variance(patterns.map((p) => p.screenTimeSeconds.toDouble()).toList()) > 150) {
      signals.add('erratic_usage_pattern'); score += 0.15;
    }

    final weekendP = patterns.where((p) => p.dayOfWeek == 'Saturday' || p.dayOfWeek == 'Sunday').length;
    final weekdayP = patterns.length - weekendP;
    if (weekendP > 0 && weekdayP > 0 &&
        ((weekendP / 2.0) - (weekdayP / 5.0)).abs() > 2) {
      signals.add('weekend_weekday_behavior_shift'); score += 0.1;
    }

    final shortS = patterns.where((p) => p.screenTimeSeconds < 60).length;
    if (patterns.isNotEmpty && shortS / patterns.length > 0.5) {
      signals.add('frequent_brief_sessions'); score += 0.1;
    }

    final ConfidenceLevel level;
    if (score >= 0.6 && signals.length >= 4) {
      level = ConfidenceLevel.high;
    } else if (score >= 0.3 && signals.length >= 2) {
      level = ConfidenceLevel.medium;
    } else {
      level = ConfidenceLevel.low;
    }

    return EmotionalConfidence(
      level: level, score: score.clamp(0.0, 1.0),
      signalCount: signals.length, lastUpdated: DateTime.now(), signals: signals,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _recentJournal({required int days}) async {
    final all = await DatabaseService.instance.getJournalEntries();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) {
      try { return DateTime.parse(e['date'] as String).isAfter(cutoff); }
      catch (_) { return false; }
    }).toList();
  }

  double _journalScore(Map<String, dynamic> entry) {
    final content = (entry['content'] as String? ?? '').trim();
    final stored = entry['sentiment'] as String?;
    if (stored != null && stored.isNotEmpty && stored != 'neutral') {
      return stored == 'positive' ? 2.0 : -2.0;
    }
    if (content.isNotEmpty) {
      return SentimentAnalyzer.analyzeDetailed(content)['score'] as double;
    }
    // Mood index proxy: 0=terrible→-3, 1=sad→-1.5, 2=okay→0, 3=happy→1.5, 4=amazing→3
    final moodIdx = entry['mood'] as int? ?? 2;
    return (moodIdx - 2) * 1.5;
  }

  Map<String, List<BehaviorPattern>> _groupByDay(List<BehaviorPattern> patterns) {
    final map = <String, List<BehaviorPattern>>{};
    for (final p in patterns) {
      final day = p.timestamp.toIso8601String().split('T')[0];
      map.putIfAbsent(day, () => []).add(p);
    }
    return map;
  }

  double _variance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
  }

  // ── Descriptions & suggestions ────────────────────────────────────────────

  String getStateDescription(EmotionalState state) {
    switch (state) {
      case EmotionalState.calm:       return 'You seem calm and balanced';
      case EmotionalState.restless:   return 'You might be feeling restless';
      case EmotionalState.stressed:   return 'You may be experiencing stress';
      case EmotionalState.lowEnergy:  return 'Your energy seems low today';
      case EmotionalState.distressed: return 'Patterns suggest you may need support';
      case EmotionalState.neutral:    return 'Your state appears neutral';
    }
  }

  List<String> getSuggestions(EmotionalState state, ConfidenceLevel confidence) {
    if (confidence == ConfidenceLevel.low) {
      return ['Take a moment to breathe deeply', 'Stay hydrated', 'Consider a short walk'];
    }
    if (confidence == ConfidenceLevel.high && state == EmotionalState.distressed) {
      return [
        'This pattern may indicate ongoing distress',
        'Consider speaking with a mental health professional',
        'Use the location finder to find nearby support',
      ];
    }
    switch (state) {
      case EmotionalState.restless:
        return ['Try listening to calming audio', 'Practice breathing exercises', 'Take a short walk outside'];
      case EmotionalState.stressed:
        return ['Consider visiting a calming location', 'Listen to relaxation audio', 'Try deep breathing for 5 minutes'];
      case EmotionalState.lowEnergy:
        return ['Get some fresh air', 'Light physical activity might help', 'Stay hydrated and rest'];
      case EmotionalState.calm:
        return ['Keep up your great routine', 'Share your positivity with others'];
      default:
        return ['Keep maintaining your wellness routine'];
    }
  }
}
