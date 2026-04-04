import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/emotional_inference_service.dart';
import '../utils/app_theme.dart';
import '../utils/sentiment_analyzer.dart';

const _categoryShades = {
  'Self-Worth': Color(0xFF0D9488),
  'Healing':    Color(0xFF0F766E),
  'Calm':       Color(0xFF2DD4BF),
  'Resilience': Color(0xFF0E7490),
  'Positivity': Color(0xFF0891B2),
  'Trust':      Color(0xFF134E4A),
  'Grief':      Color(0xFF6366F1),
  'Anxiety':    Color(0xFF8B5CF6),
  'Energy':     Color(0xFF059669),
};

const _emotionToCategories = {
  'joy':     ['Positivity', 'Self-Worth', 'Energy'],
  'calm':    ['Calm', 'Trust', 'Self-Worth'],
  'sadness': ['Healing', 'Self-Worth', 'Grief'],
  'anxiety': ['Anxiety', 'Calm', 'Trust'],
  'anger':   ['Healing', 'Resilience'],
  'grief':   ['Grief', 'Healing', 'Self-Worth'],
  'hope':    ['Resilience', 'Positivity', 'Trust'],
  'neutral': ['Self-Worth', 'Calm', 'Positivity'],
};

const _affirmations = [
  {'text': 'I am worthy of love and belonging.',               'category': 'Self-Worth'},
  {'text': 'I believe in my ability to grow and improve.',    'category': 'Self-Worth'},
  {'text': 'I am enough, exactly as I am right now.',         'category': 'Self-Worth'},
  {'text': 'My feelings are valid and I honor them.',         'category': 'Self-Worth'},
  {'text': 'I am healing and getting stronger every day.',    'category': 'Healing'},
  {'text': 'I release what no longer serves me.',             'category': 'Healing'},
  {'text': 'My past does not define my future.',              'category': 'Healing'},
  {'text': 'Every wound I carry is also a story of survival.','category': 'Healing'},
  {'text': 'I breathe in peace and exhale tension.',          'category': 'Calm'},
  {'text': 'I am safe, grounded, and at peace.',              'category': 'Calm'},
  {'text': 'I choose calm over chaos in every moment.',       'category': 'Calm'},
  {'text': 'In this moment, I am exactly where I need to be.','category': 'Calm'},
  {'text': 'I have the strength to face any challenge.',      'category': 'Resilience'},
  {'text': 'Every setback is a setup for a comeback.',        'category': 'Resilience'},
  {'text': 'I am resilient, brave, and unstoppable.',         'category': 'Resilience'},
  {'text': 'I attract positivity and good energy.',           'category': 'Positivity'},
  {'text': 'Today I choose joy, gratitude, and love.',        'category': 'Positivity'},
  {'text': 'Good things are always coming my way.',           'category': 'Positivity'},
  {'text': 'I trust the journey, even when I cannot see the path.', 'category': 'Trust'},
  {'text': 'I trust myself to make the right decisions.',    'category': 'Trust'},
  {'text': 'It is okay to grieve. My feelings are real.',    'category': 'Grief'},
  {'text': 'I allow myself to feel without judgment.',        'category': 'Grief'},
  {'text': 'My anxiety does not define me.',                  'category': 'Anxiety'},
  {'text': 'I am bigger than my worries.',                    'category': 'Anxiety'},
  {'text': 'I have energy and vitality flowing through me.',  'category': 'Energy'},
  {'text': 'Each breath renews my strength and focus.',       'category': 'Energy'},
];

Color _shade(String category) => _categoryShades[category] ?? AppTheme.primary;
Color _lighten(Color c) => Color.lerp(c, const Color(0xFF99F6E4), 0.45)!;

// ── Maps EmotionalState → emotion key ────────────────────────────────────────
String _stateToEmotion(EmotionalState state) {
  switch (state) {
    case EmotionalState.calm:       return 'calm';
    case EmotionalState.restless:   return 'anxiety';
    case EmotionalState.stressed:   return 'anxiety';
    case EmotionalState.lowEnergy:  return 'sadness';
    case EmotionalState.distressed: return 'grief';
    case EmotionalState.neutral:    return 'neutral';
  }
}

// ── Maps mood index (0-4) → emotion key ──────────────────────────────────────
String _moodIndexToEmotion(int idx) {
  switch (idx) {
    case 0: return 'grief';    // Terrible
    case 1: return 'sadness';  // Sad
    case 2: return 'neutral';  // Okay
    case 3: return 'joy';      // Happy
    case 4: return 'joy';      // Amazing
    default: return 'neutral';
  }
}

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});
  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen>
    with SingleTickerProviderStateMixin {
  Set<int> _favorites = {};
  int _dailyIndex = 0;
  late TabController _tabCtrl;
  String _detectedEmotion = 'neutral';
  List<int> _moodAffirmationIndices = [];
  bool _loadingMood = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _dailyIndex = DateTime.now().dayOfYear % _affirmations.length;
    _loadFavorites();
    _loadMoodAffirmations();
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 0 && !_tabCtrl.indexIsChanging) {
        _loadMoodAffirmations();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('affirmation_favorites') ?? [];
    if (mounted) setState(() => _favorites = saved.map(int.parse).toSet());
  }

  Future<void> _loadMoodAffirmations() async {
    if (mounted) setState(() => _loadingMood = true);

    String emotion = 'neutral';

    try {
      // ── Step 1: read the most recent journal entry mood directly from DB ──
      // This is always fresh — no cache involved.
      final allEntries = await DatabaseService.instance.getJournalEntries();

      if (allEntries.isNotEmpty) {
        final latest = allEntries.first; // ordered by date DESC

        // Use stored sentiment first
        final stored = (latest['sentiment'] as String? ?? '').toLowerCase();
        if (stored == 'positive') {
          emotion = 'joy';
        } else if (stored == 'negative') {
          // Run NLP on content for finer emotion
          final content = (latest['content'] as String? ?? '').trim();
          if (content.isNotEmpty) {
            final nlpEmotion = SentimentAnalyzer.detectEmotion(content);
            emotion = (nlpEmotion != 'neutral') ? nlpEmotion : 'sadness';
          } else {
            emotion = _moodIndexToEmotion(latest['mood'] as int? ?? 2);
          }
        } else {
          // neutral stored — use mood index + NLP on content
          final content = (latest['content'] as String? ?? '').trim();
          final moodIdx = latest['mood'] as int? ?? 2;
          if (content.isNotEmpty) {
            final nlpEmotion = SentimentAnalyzer.detectEmotion(content);
            emotion = (nlpEmotion != 'neutral')
                ? nlpEmotion
                : _moodIndexToEmotion(moodIdx);
          } else {
            emotion = _moodIndexToEmotion(moodIdx);
          }
        }

        // ── Step 2: also run NLP across last 5 entries for richer signal ──
        final recent5 = allEntries.take(5).toList();
        final combinedText = recent5
            .map((e) => e['content'] as String? ?? '')
            .where((t) => t.isNotEmpty)
            .join(' ');
        if (combinedText.isNotEmpty) {
          final combinedEmotion = SentimentAnalyzer.detectEmotion(combinedText);
          // Only override if combined gives a non-neutral specific emotion
          if (combinedEmotion != 'neutral') emotion = combinedEmotion;
        }
      } else {
        // ── Step 3: no journal entries — fall back to inferred emotional state ──
        // Invalidate cache so we get the freshest state
        EmotionalInferenceService.instance.invalidateCache();
        final state = await EmotionalInferenceService.instance.inferEmotionalState();
        emotion = _stateToEmotion(state);
      }
    } catch (_) {
      emotion = 'neutral';
    }

    final targetCategories = _emotionToCategories[emotion] ?? ['Self-Worth', 'Calm'];
    final matched = _affirmations
        .asMap()
        .entries
        .where((e) => targetCategories.contains(e.value['category']))
        .map((e) => e.key)
        .toList();

    // Fresh shuffle every call
    matched.shuffle(math.Random(DateTime.now().millisecondsSinceEpoch));

    if (mounted) {
      setState(() {
        _detectedEmotion = emotion;
        _moodAffirmationIndices = matched.take(6).toList();
        _loadingMood = false;
      });
    }
  }

  Future<void> _toggleFavorite(int index) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
      }
    });
    await prefs.setStringList(
        'affirmation_favorites', _favorites.map((i) => '$i').toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Affirmations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadMoodAffirmations,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary(context),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'For You'), Tab(text: 'All'), Tab(text: 'Saved')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildForYouTab(), _buildAllTab(), _buildFavoritesTab()],
      ),
    );
  }

  Widget _buildForYouTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _DailyHighlight(
          index: _dailyIndex,
          onFavorite: () => _toggleFavorite(_dailyIndex),
          isFavorite: _favorites.contains(_dailyIndex),
        ),
        const SizedBox(height: 28),
        Row(children: [
          Text('Based on Your Mood',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(SentimentAnalyzer.emotionColor(_detectedEmotion))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              SentimentAnalyzer.emotionLabel(_detectedEmotion),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(SentimentAnalyzer.emotionColor(_detectedEmotion)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          'Updated from your latest journal entries',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
        ),
        const SizedBox(height: 16),
        if (_loadingMood)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2),
            ),
          )
        else if (_moodAffirmationIndices.isEmpty)
          _buildEmptyMood()
        else
          ..._moodAffirmationIndices.asMap().entries.map((e) => _AffirmationCard(
                index: e.value,
                data: _affirmations[e.value],
                isFavorite: _favorites.contains(e.value),
                isDaily: e.value == _dailyIndex,
                animIndex: e.key,
                onFavorite: () => _toggleFavorite(e.value),
              )),
      ]),
    );
  }

  Widget _buildEmptyMood() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          const Text('📓', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Write in your journal to get personalized affirmations',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: AppTheme.textSecondary(context)),
          ),
        ]),
      );

  Widget _buildAllTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('All Affirmations', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 14),
        ..._affirmations.asMap().entries.map((e) => _AffirmationCard(
              index: e.key,
              data: e.value,
              isFavorite: _favorites.contains(e.key),
              isDaily: e.key == _dailyIndex,
              animIndex: e.key,
              onFavorite: () => _toggleFavorite(e.key),
            )),
      ]),
    );
  }

  Widget _buildFavoritesTab() {
    final favs = _affirmations
        .asMap()
        .entries
        .where((e) => _favorites.contains(e.key))
        .toList();
    if (favs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border_rounded,
                color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text('No saved affirmations yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Tap the heart on any affirmation to save it',
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: favs
          .map((e) => _AffirmationCard(
                index: e.key,
                data: e.value,
                isFavorite: true,
                isDaily: e.key == _dailyIndex,
                animIndex: e.key,
                onFavorite: () => _toggleFavorite(e.key),
              ))
          .toList(),
    );
  }
}

// ── Daily highlight ───────────────────────────────────────────────────────────
class _DailyHighlight extends StatefulWidget {
  final int index;
  final VoidCallback onFavorite;
  final bool isFavorite;
  const _DailyHighlight(
      {required this.index,
      required this.onFavorite,
      required this.isFavorite});
  @override
  State<_DailyHighlight> createState() => _DailyHighlightState();
}

class _DailyHighlightState extends State<_DailyHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _affirmations[widget.index];
    final color = _shade(data['category']!);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
          opacity: v,
          child:
              Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, _lighten(color)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Text('TODAY\'S AFFIRMATION',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: widget.onFavorite,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(widget.isFavorite),
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, child) => ShaderMask(
              shaderCallback: (bounds) {
                final x = _shimmerCtrl.value * (bounds.width + 200) - 100;
                return LinearGradient(
                  colors: [Colors.white70, Colors.white, Colors.white70],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(x / bounds.width * 2 - 1, 0),
                  end: Alignment(x / bounds.width * 2 + 0.5, 0),
                ).createShader(bounds);
              },
              child: child!,
            ),
            child: Text(
              '"${data['text']}"',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.6,
                  fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 14),
          Text(data['category']!,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.4)),
        ]),
      ),
    );
  }
}

// ── Affirmation card ──────────────────────────────────────────────────────────
class _AffirmationCard extends StatefulWidget {
  final int index;
  final Map<String, String> data;
  final bool isFavorite;
  final bool isDaily;
  final int animIndex;
  final VoidCallback onFavorite;
  const _AffirmationCard(
      {required this.index,
      required this.data,
      required this.isFavorite,
      required this.isDaily,
      required this.animIndex,
      required this.onFavorite});
  @override
  State<_AffirmationCard> createState() => _AffirmationCardState();
}

class _AffirmationCardState extends State<_AffirmationCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim =
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _shade(widget.data['category']!);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + widget.animIndex * 35),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: widget.isDaily
                  ? color.withValues(alpha: 0.45)
                  : color.withValues(alpha: 0.12),
              width: widget.isDaily ? 1.8 : 1,
            ),
            boxShadow: widget.isDaily ? [AppTheme.shadow] : [],
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radius),
                    bottomLeft: Radius.circular(AppTheme.radius),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.data['text']!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.45, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(widget.data['category']!,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ),
                      if (widget.isDaily) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Today',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryLight)),
                        ),
                      ],
                    ]),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: widget.onFavorite,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        widget.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(widget.isFavorite),
                        color: widget.isFavorite
                            ? AppTheme.primary
                            : AppTheme.textSecondary(context),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary(context), size: 18),
                  ),
                ]),
              ),
            ]),
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Container(
                margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppTheme.radius)),
                ),
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Practice this affirmation',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 8),
                  Text(_practicePrompt(widget.data['category']!),
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary(context),
                          height: 1.5)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _practicePrompt(String category) {
    const prompts = {
      'Self-Worth': 'Say this aloud three times, placing your hand on your heart.',
      'Healing':    'Close your eyes, take a deep breath, and repeat this gently.',
      'Calm':       'Breathe in for 4 counts, hold for 2, exhale while repeating this.',
      'Resilience': 'Stand tall, shoulders back, and say this with conviction.',
      'Positivity': 'Smile as you say this — your body and mind respond to each other.',
      'Trust':      'Write this in your journal and reflect on a time you trusted yourself.',
      'Grief':      'Be gentle with yourself. Read this slowly and allow yourself to feel.',
      'Anxiety':    'Place both feet on the floor, breathe, and repeat until grounded.',
      'Energy':     'Say this while stretching — let your body feel the energy.',
    };
    return prompts[category] ?? 'Repeat this affirmation slowly and let it sink in.';
  }
}

extension on DateTime {
  int get dayOfYear => difference(DateTime(year, 1, 1)).inDays;
}
