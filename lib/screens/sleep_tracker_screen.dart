import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

const _qualities = [
  {'emoji': '😴', 'label': 'Poor',    'color': Color(0xFFEF4444)},
  {'emoji': '😪', 'label': 'Fair',    'color': Color(0xFFF59E0B)},
  {'emoji': '🙂', 'label': 'Good',    'color': Color(0xFF14B8A6)},
  {'emoji': '😊', 'label': 'Great',   'color': Color(0xFF10B981)},
  {'emoji': '🤩', 'label': 'Perfect', 'color': Color(0xFF6366F1)},
];

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});
  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with SingleTickerProviderStateMixin {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _quality = 2;
  final _noteCtrl = TextEditingController();
  bool _saved = false;
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _load();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final today = await DatabaseService.instance.getTodaySleepLog();
    final history = await DatabaseService.instance.getSleepHistory();
    if (today != null) {
      final bt = today['bedtime'] as String;
      final wt = today['wakeTime'] as String;
      _bedtime = TimeOfDay(hour: int.parse(bt.split(':')[0]), minute: int.parse(bt.split(':')[1]));
      _wakeTime = TimeOfDay(hour: int.parse(wt.split(':')[0]), minute: int.parse(wt.split(':')[1]));
      _quality = today['quality'] as int;
      _noteCtrl.text = today['note'] as String? ?? '';
      _saved = true;
    } else {
      _saved = false;
    }
    setState(() { _history = history; _loading = false; });
    _fadeCtrl.forward(from: 0);
  }

  double get _durationHours {
    final bedMins = _bedtime.hour * 60 + _bedtime.minute;
    var wakeMins = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeMins <= bedMins) wakeMins += 24 * 60;
    return (wakeMins - bedMins) / 60.0;
  }

  String get _durationLabel {
    final h = _durationHours;
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    return '${hrs}h ${mins}m';
  }

  Future<void> _pickTime(bool isBed) async {
    if (_saved) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: isBed ? _bedtime : _wakeTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isBed ? _bedtime = picked : _wakeTime = picked);
  }

  Future<void> _save() async {
    await DatabaseService.instance.insertSleepLog(
      bedtime: '${_bedtime.hour.toString().padLeft(2, '0')}:${_bedtime.minute.toString().padLeft(2, '0')}',
      wakeTime: '${_wakeTime.hour.toString().padLeft(2, '0')}:${_wakeTime.minute.toString().padLeft(2, '0')}',
      durationHours: _durationHours,
      quality: _quality,
      note: _noteCtrl.text.trim(),
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Sleep logged! 🌙'),
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
      appBar: AppBar(title: const Text('🌙 Sleep Tracker'), backgroundColor: Colors.transparent, elevation: 0),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : FadeTransition(
              opacity: _fadeCtrl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLogCard(),
                  const SizedBox(height: 28),
                  if (_history.isNotEmpty) _buildHistory(),
                ]),
              ),
            ),
    );
  }

  Widget _buildLogCard() {
    final qualityData = _qualities[_quality];
    final color = qualityData['color'] as Color;
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
              child: const Icon(Icons.bedtime_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Text('Last Night\'s Sleep', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
        ]),
        const SizedBox(height: 22),

        // Duration display
        Center(child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, __) => Transform.scale(scale: v, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.15), AppTheme.primaryLight.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Column(children: [
              Text(_durationLabel, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              Text('total sleep', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
            ]),
          )),
        )),

        const SizedBox(height: 22),

        // Time pickers
        Row(children: [
          Expanded(child: _TimeTile(label: '🌙 Bedtime', time: _bedtime.format(context), onTap: () => _pickTime(true), disabled: _saved)),
          const SizedBox(width: 12),
          Expanded(child: _TimeTile(label: '☀️ Wake Time', time: _wakeTime.format(context), onTap: () => _pickTime(false), disabled: _saved)),
        ]),

        const SizedBox(height: 20),

        // Quality
        Text('Sleep Quality', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(_qualities.length, (i) {
          final q = _qualities[i];
          final sel = _quality == i;
          return GestureDetector(
            onTap: _saved ? null : () => setState(() => _quality = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sel ? (q['color'] as Color).withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? (q['color'] as Color) : Colors.transparent, width: 2),
              ),
              child: Column(children: [
                AnimatedScale(scale: sel ? 1.2 : 1.0, duration: const Duration(milliseconds: 200),
                    child: Text(q['emoji'] as String, style: const TextStyle(fontSize: 26))),
                const SizedBox(height: 4),
                Text(q['label'] as String, style: TextStyle(fontSize: 10,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? (q['color'] as Color) : AppTheme.textSecondary(context))),
              ]),
            ),
          );
        })),

        const SizedBox(height: 18),

        // Note
        TextField(
          controller: _noteCtrl,
          enabled: !_saved,
          maxLines: 2,
          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Notes: dreams, disturbances... (optional)',
            hintStyle: TextStyle(color: AppTheme.textSecondary(context).withOpacity(0.6), fontSize: 13),
            filled: true,
            fillColor: AppTheme.primary.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),

        const SizedBox(height: 18),

        if (!_saved)
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius))),
              child: const Text('Log Sleep 🌙', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ))
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radius)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text('Sleep logged! ${qualityData['emoji']} ${qualityData['label']}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildHistory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Last 7 Nights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
      const SizedBox(height: 14),
      ..._history.map((h) {
        final q = _qualities[h['quality'] as int];
        final color = q['color'] as Color;
        final date = DateTime.parse(h['date'] as String);
        final dur = (h['durationHours'] as double);
        final hrs = dur.floor();
        final mins = ((dur - hrs) * 60).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Text(q['emoji'] as String, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('EEE, MMM d').format(date),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
              Text('${h['bedtime']} → ${h['wakeTime']}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${hrs}h ${mins}m', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(q['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
            ]),
          ]),
        );
      }),
    ]);
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  final bool disabled;
  const _TimeTile({required this.label, required this.time, required this.onTap, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 6),
          Text(time, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ]),
      ),
    );
  }
}
