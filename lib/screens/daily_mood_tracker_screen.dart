import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class DailyMoodTrackerScreen extends StatefulWidget {
  const DailyMoodTrackerScreen({super.key});

  @override
  State<DailyMoodTrackerScreen> createState() => _DailyMoodTrackerScreenState();
}

class _DailyMoodTrackerScreenState extends State<DailyMoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedMood; // 0–4
  final _noteCtrl = TextEditingController();
  bool _saved = false;
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  static const _moods = [
    {'emoji': '😔', 'label': 'Sad', 'color': Color(0xFF6B7280)},
    {'emoji': '😟', 'label': 'Anxious', 'color': Color(0xFFF59E0B)},
    {'emoji': '😐', 'label': 'Neutral', 'color': Color(0xFF14B8A6)},
    {'emoji': '🙂', 'label': 'Good', 'color': Color(0xFF10B981)},
    {'emoji': '😄', 'label': 'Great', 'color': Color(0xFF6366F1)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final logs = await DatabaseService.instance.getMoodLogs(days: 7);
    final todayLog = await DatabaseService.instance.getTodayMoodLog();
    setState(() {
      _history = logs;
      if (todayLog != null) {
        _selectedMood = todayLog['mood'] as int;
        _noteCtrl.text = todayLog['note'] as String? ?? '';
        _saved = true;
      }
      _loading = false;
    });
    _fadeCtrl.forward();
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) return;
    await DatabaseService.instance.insertMoodLog(
      mood: _selectedMood!,
      note: _noteCtrl.text.trim(),
    );
    setState(() => _saved = true);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mood saved! Keep tracking 🌱'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Daily Mood Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayCard(),
                    const SizedBox(height: 28),
                    if (_history.isNotEmpty) _buildHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodayCard() {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.today_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How are you feeling?',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context))),
                  Text(today,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Mood selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_moods.length, (i) {
              final mood = _moods[i];
              final selected = _selectedMood == i;
              return GestureDetector(
                onTap: _saved ? null : () => setState(() => _selectedMood = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? (mood['color'] as Color).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? (mood['color'] as Color)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: Text(mood['emoji'] as String,
                            style: const TextStyle(fontSize: 30)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected
                              ? (mood['color'] as Color)
                              : AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Note field
          TextField(
            controller: _noteCtrl,
            enabled: !_saved,
            maxLines: 3,
            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add a note about your day... (optional)',
              hintStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
              filled: true,
              fillColor: AppTheme.primary.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (!_saved)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedMood != null ? _saveMood : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius)),
                ),
                child: const Text('Save Today\'s Mood',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Mood logged for today!',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 7 Days',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context))),
        const SizedBox(height: 14),
        ...(_history.map((log) {
          final moodIdx = log['mood'] as int;
          final mood = _moods[moodIdx];
          final date = DateTime.parse(log['date'] as String);
          final note = log['note'] as String?;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: (mood['color'] as Color).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text(mood['emoji'] as String, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE, MMM d').format(date),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context)),
                      ),
                      if (note != null && note.isNotEmpty)
                        Text(note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary(context))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (mood['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mood['label'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mood['color'] as Color),
                  ),
                ),
              ],
            ),
          );
        })),
      ],
    );
  }
}
