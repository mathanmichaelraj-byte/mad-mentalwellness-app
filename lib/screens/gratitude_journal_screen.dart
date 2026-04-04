import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

const _prompts = [
  'Something that made you smile today 😊',
  'Someone who inspired or helped you 🌟',
  'One thing you\'re grateful to have 🙏',
];

class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});
  @override
  State<GratitudeJournalScreen> createState() => _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _ctrls = List.generate(3, (_) => TextEditingController());
  bool _loading = true;
  bool _saved = false;
  int _streak = 0;
  List<Map<String, dynamic>> _history = [];
  late final AnimationController _streakCtrl;
  late final Animation<double> _streakScale;

  @override
  void initState() {
    super.initState();
    _streakCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _streakScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _streakCtrl, curve: Curves.elasticOut));
    _load();
  }

  @override
  void dispose() {
    _streakCtrl.dispose();
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final today = await DatabaseService.instance.getTodayGratitude();
    final history = await DatabaseService.instance.getGratitudeHistory();
    final streak = await DatabaseService.instance.getGratitudeStreak();
    if (today != null) {
      for (int i = 0; i < 3; i++) {
        _ctrls[i].text = today['prompt${i + 1}'] as String? ?? '';
      }
      _saved = true;
    } else {
      for (final c in _ctrls) c.clear();
      _saved = false;
    }
    setState(() { _history = history; _streak = streak; _loading = false; });
    _streakCtrl.forward(from: 0);
  }

  Future<void> _save() async {
    await DatabaseService.instance.insertGratitude(
      prompt1: _ctrls[0].text.trim(),
      prompt2: _ctrls[1].text.trim(),
      prompt3: _ctrls[2].text.trim(),
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Gratitude saved! 🌸'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(title: const Text('🌸 Gratitude Journal'), backgroundColor: Colors.transparent, elevation: 0),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildStreakCard(),
                const SizedBox(height: 24),
                _buildTodayCard(),
                const SizedBox(height: 28),
                if (_history.isNotEmpty) _buildHistory(),
              ]),
            ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFEC4899).withOpacity(0.15), AppTheme.primary.withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.25)),
      ),
      child: Row(children: [
        ScaleTransition(
          scale: _streakScale,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF97316)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$_streak', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const Text('days', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ]),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_streak == 0 ? 'Start your streak!' : _streak == 1 ? 'Great start! 🌱' : 'Amazing streak! 🔥',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 4),
          Text(_streak == 0
              ? 'Fill in today\'s gratitude to begin'
              : 'You\'ve been grateful for $_streak day${_streak > 1 ? 's' : ''} in a row',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildTodayCard() {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Gratitude', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            Text(today, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
          ]),
        ]),
        const SizedBox(height: 22),
        ...List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${i + 1}. ${_prompts[i]}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrls[i],
              enabled: !_saved,
              maxLines: 2,
              style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write here...',
                hintStyle: TextStyle(color: AppTheme.textSecondary(context).withOpacity(0.6)),
                filled: true,
                fillColor: AppTheme.primary.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2)),
              ),
            ),
          ]),
        )),
        if (!_saved)
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius))),
              child: const Text('Save Gratitude 🌸', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ))
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radius)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Saved for today! Come back tomorrow 🌸',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildHistory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Past Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
      const SizedBox(height: 14),
      ..._history.map((h) {
        final date = DateTime.parse(h['date'] as String);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.15)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('🌸', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(DateFormat('EEE, MMM d').format(date),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
              ]),
              const SizedBox(height: 10),
              ...List.generate(3, (i) {
                final val = h['prompt${i + 1}'] as String? ?? '';
                if (val.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1}. ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
                    Expanded(child: Text(val, style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context), height: 1.4))),
                  ]),
                );
              }),
            ]),
          ),
        );
      }),
    ]);
  }
}
