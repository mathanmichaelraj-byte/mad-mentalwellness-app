import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});
  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;

  // Raw data
  List<Map<String, dynamic>> _moodLogs = [];
  List<Map<String, dynamic>> _journalEntries = []; // last 7 days
  List<Map<String, dynamic>> _sleepLogs = [];

  // 30-day totals (counted per-table in DB)
  int _moodCount30 = 0, _journalCount30 = 0, _gratitudeCount30 = 0, _sleepCount30 = 0;

  // NLP insights
  Map<String, dynamic> _nlp = {};

  late final AnimationController _fadeCtrl;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final db = DatabaseService.instance;
    final cutoff30 = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String()
        .split('T')[0];

    // Run all queries in parallel
    final results = await Future.wait([
      db.getMoodLogs(days: 7),                          // 0
      db.getJournalEntriesLast7Days(),                  // 1
      db.getSleepHistory(days: 7),                      // 2
      db.countEntriesSince('mood_logs', cutoff30),      // 3
      db.countJournalEntriesSince(cutoff30),            // 4
      db.countEntriesSince('gratitude_logs', cutoff30), // 5
      db.countEntriesSince('sleep_logs', cutoff30),     // 6
      db.getNlpInsights(),                              // 7
    ]);

    setState(() {
      _moodLogs        = results[0] as List<Map<String, dynamic>>;
      _journalEntries  = results[1] as List<Map<String, dynamic>>;
      _sleepLogs       = results[2] as List<Map<String, dynamic>>;
      _moodCount30     = results[3] as int;
      _journalCount30  = results[4] as int;
      _gratitudeCount30= results[5] as int;
      _sleepCount30    = results[6] as int;
      _nlp             = results[7] as Map<String, dynamic>;
      _loading = false;
    });

    _fadeCtrl.forward(from: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _scrollCtrl.hasClients &&
            _scrollCtrl.position.maxScrollExtent > 0) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent * 0.38,
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  int get _totalEntries30d =>
      _moodCount30 + _journalCount30 + _gratitudeCount30 + _sleepCount30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('📊 Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 24),
                        _buildBreakdown(),
                        const SizedBox(height: 24),
                        _buildNlpInsights(),
                        const SizedBox(height: 24),
                        _buildMoodChart(),
                        const SizedBox(height: 24),
                        _buildJournalChart(),
                        const SizedBox(height: 24),
                        _buildSleepChart(),
                        const SizedBox(height: 20),
                      ]),
                ),
              ),
            ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - v)), child: child)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('30-Day Summary',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: _totalEntries30d),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (_, v, __) => Text('$v',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1)),
              ),
              const Text('total entries logged',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            child:
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 38),
          ),
        ]),
      ),
    );
  }

  // ── Per-category breakdown ────────────────────────────────────────────────
  Widget _buildBreakdown() {
    final items = [
      _BreakdownItem('Mood Logs',    _moodCount30,      '😊', AppTheme.primary),
      _BreakdownItem('Journal',      _journalCount30,   '📓', const Color(0xFF6366F1)),
      _BreakdownItem('Gratitude',    _gratitudeCount30, '🌸', const Color(0xFFEC4899)),
      _BreakdownItem('Sleep Logs',   _sleepCount30,     '🌙', const Color(0xFF8B5CF6)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Last 30 Days',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context))),
      const SizedBox(height: 14),
      Row(children: items
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < items.length - 1 ? 10 : 0),
                  child: _buildBreakdownTile(e.value, e.key),
                ),
              ))
          .toList()),
    ]);
  }

  Widget _buildBreakdownTile(_BreakdownItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, child) =>
          Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: item.count),
            duration: Duration(milliseconds: 800 + index * 100),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text('$v',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: item.color)),
          ),
          const SizedBox(height: 3),
          Text(item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary(context),
                  height: 1.3)),
        ]),
      ),
    );
  }

  // ── NLP Insights ──────────────────────────────────────────────────────────
  Widget _buildNlpInsights() {
    final total = (_nlp['total'] as int? ?? 0);
    if (total == 0) return const SizedBox.shrink();

    final pos  = _nlp['positive'] as int? ?? 0;
    final neg  = _nlp['negative'] as int? ?? 0;
    final neu  = _nlp['neutral']  as int? ?? 0;
    final tags = (_nlp['topTags'] as List?)?.cast<String>() ?? [];
    final moodDist = (_nlp['moodDistribution'] as Map?)?.cast<int, int>() ?? {};

    final moodLabels = ['😢', '😔', '😐', '😊', '🤩'];
    final moodColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      AppTheme.primary,
      const Color(0xFF10B981),
      const Color(0xFF6366F1),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('NLP Insights 🧠',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context))),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Sentiment bar
          Text('Sentiment (last 30 days)',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(children: [
              if (pos > 0) Expanded(flex: pos, child: Container(height: 14, color: const Color(0xFF10B981))),
              if (neu > 0) Expanded(flex: neu, child: Container(height: 14, color: const Color(0xFFF59E0B))),
              if (neg > 0) Expanded(flex: neg, child: Container(height: 14, color: const Color(0xFFEF4444))),
            ]),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _nlpLegend('Positive', pos, total, const Color(0xFF10B981)),
            _nlpLegend('Neutral',  neu, total, const Color(0xFFF59E0B)),
            _nlpLegend('Negative', neg, total, const Color(0xFFEF4444)),
          ]),
          if (moodDist.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Mood Distribution',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final count = moodDist[i] ?? 0;
                return Column(children: [
                  Text(moodLabels[i], style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('$count',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: moodColors[i])),
                ]);
              }),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Top Journal Tags',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Text(t,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
        ]),
      ),
    ]);
  }

  Widget _nlpLegend(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text('$label $pct%',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
    ]);
  }

  // ── Mood chart ────────────────────────────────────────────────────────────
  Widget _buildMoodChart() {
    final days = _last7Days();
    final moodMap = {for (final l in _moodLogs) l['date'] as String: l['mood'] as int};
    if (moodMap.isEmpty) return const SizedBox.shrink();

    return _ChartCard(
      title: 'Mood Trends (7 days)',
      child: _BarChart(
        days: days,
        getValue: (d) =>
            moodMap.containsKey(d) ? ((moodMap[d]! + 1) / 5.0) * 100 : 0.0,
        getColor: (d) {
          final m = moodMap[d];
          if (m == null) return AppTheme.primary.withValues(alpha: 0.15);
          return [
            const Color(0xFFEF4444),
            const Color(0xFFF59E0B),
            AppTheme.primary,
            const Color(0xFF10B981),
            const Color(0xFF6366F1)
          ][m];
        },
        getLabel: (d) {
          final m = moodMap[d];
          return m != null ? ['😢', '😔', '😐', '😊', '🤩'][m] : null;
        },
      ),
    );
  }

  // ── Journal chart ─────────────────────────────────────────────────────────
  Widget _buildJournalChart() {
    final days = _last7Days();
    // _journalEntries already filtered to last 7 days by getJournalEntriesLast7Days()
    final countMap = <String, int>{};
    for (final e in _journalEntries) {
      // date is full ISO string — take first 10 chars
      final d = (e['date'] as String).substring(0, 10);
      countMap[d] = (countMap[d] ?? 0) + 1;
    }
    if (countMap.isEmpty) return const SizedBox.shrink();
    final maxCount = countMap.values.fold(1, (a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Journal Entries (7 days)',
      child: _BarChart(
        days: days,
        getValue: (d) =>
            countMap.containsKey(d) ? (countMap[d]! / maxCount) * 100 : 0.0,
        getColor: (_) => const Color(0xFF6366F1),
        getLabel: (d) =>
            countMap.containsKey(d) ? '${countMap[d]}' : null,
      ),
    );
  }

  // ── Sleep chart ───────────────────────────────────────────────────────────
  Widget _buildSleepChart() {
    if (_sleepLogs.isEmpty) return const SizedBox.shrink();
    final days = _last7Days();
    final sleepMap = {
      for (final l in _sleepLogs)
        l['date'] as String: l['durationHours'] as double
    };

    return _ChartCard(
      title: 'Sleep Hours (7 nights)',
      child: _BarChart(
        days: days,
        getValue: (d) =>
            sleepMap.containsKey(d) ? (sleepMap[d]! / 10.0) * 100 : 0.0,
        getColor: (d) {
          final h = sleepMap[d] ?? 0;
          return h >= 7
              ? const Color(0xFF10B981)
              : h >= 5
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444);
        },
        getLabel: (d) => sleepMap.containsKey(d)
            ? '${sleepMap[d]!.toStringAsFixed(1)}h'
            : null,
      ),
    );
  }

  List<String> _last7Days() => List.generate(7, (i) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        return DateFormat('yyyy-MM-dd').format(d);
      });
}

class _BreakdownItem {
  final String label, emoji;
  final int count;
  final Color color;
  const _BreakdownItem(this.label, this.count, this.emoji, this.color);
}

// ── Chart card ────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context))),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
        ),
        child: child,
      ),
    ]);
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<String> days;
  final double Function(String) getValue;
  final Color Function(String) getColor;
  final String? Function(String) getLabel;
  const _BarChart(
      {required this.days,
      required this.getValue,
      required this.getColor,
      required this.getLabel});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) {
            final barH = getValue(d);
            final color = getColor(d);
            final label = getLabel(d);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: barH),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) =>
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (label != null) ...[
                  Text(label, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 3),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: v.clamp(4.0, 110.0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: barH > 0
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((d) => Text(
                  DateFormat('E').format(DateTime.parse(d)),
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary(context)),
                ))
            .toList(),
      ),
    ]);
  }
}

