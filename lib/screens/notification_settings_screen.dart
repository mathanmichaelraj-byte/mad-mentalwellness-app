import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _mood = true, _gratitude = true, _sleep = true, _affirm = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ns = NotificationService.instance;
    final results = await Future.wait([
      ns.isEnabled('notif_mood'),
      ns.isEnabled('notif_gratitude'),
      ns.isEnabled('notif_sleep'),
      ns.isEnabled('notif_affirm'),
    ]);
    setState(() {
      _mood      = results[0];
      _gratitude = results[1];
      _sleep     = results[2];
      _affirm    = results[3];
      _loading   = false;
    });
  }

  Future<void> _toggle(String key, int id, bool val, Future<void> Function() schedule) async {
    await NotificationService.instance.setEnabled(key, id, val, schedule);
    setState(() {
      if (key == 'notif_mood')      _mood      = val;
      if (key == 'notif_gratitude') _gratitude = val;
      if (key == 'notif_sleep')     _sleep     = val;
      if (key == 'notif_affirm')    _affirm    = val;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(val ? 'Reminder enabled' : 'Reminder paused'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _disableAll() async {
    await NotificationService.instance.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    for (final k in ['notif_mood', 'notif_gratitude', 'notif_sleep', 'notif_affirm']) {
      await prefs.setBool(k, false);
    }
    setState(() { _mood = false; _gratitude = false; _sleep = false; _affirm = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('All reminders paused'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ns = NotificationService.instance;
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(title: const Text('Reminders'), backgroundColor: Colors.transparent, elevation: 0),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Description
                Text(
                  'Gentle daily reminders help you build consistent wellness habits over time.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                Text('Daily Reminders', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),

                _ReminderTile(
                  title: 'Mood Check-in',
                  description: 'A gentle prompt to log how you\'re feeling each day.',
                  value: _mood, index: 0,
                  onChanged: (v) => _toggle('notif_mood', ns.moodId, v, ns.scheduleMoodReminder),
                ),
                _ReminderTile(
                  title: 'Gratitude Journal',
                  description: 'A reminder to write your three daily gratitude prompts.',
                  value: _gratitude, index: 1,
                  onChanged: (v) => _toggle('notif_gratitude', ns.gratitudeId, v, ns.scheduleGratitudeReminder),
                ),
                _ReminderTile(
                  title: 'Sleep Log',
                  description: 'A nudge to record your bedtime and wake time.',
                  value: _sleep, index: 2,
                  onChanged: (v) => _toggle('notif_sleep', ns.sleepId, v, ns.scheduleSleepReminder),
                ),
                _ReminderTile(
                  title: 'Daily Affirmation',
                  description: 'A rotating word of encouragement delivered each morning.',
                  value: _affirm, index: 3,
                  onChanged: (v) => _toggle('notif_affirm', ns.affirmId, v, ns.scheduleAffirmationReminder),
                ),

                const SizedBox(height: 32),

                // Sample affirmation preview
                _AffirmationPreview(),

                const SizedBox(height: 32),

                OutlinedButton(
                  onPressed: _disableAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.inkSoft,
                    side: BorderSide(color: AppTheme.divider(context)),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                  ),
                  child: const Text('Pause All Reminders'),
                ),
              ]),
            ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final String title, description;
  final bool value;
  final int index;
  final ValueChanged<bool> onChanged;
  const _ReminderTile({
    required this.title, required this.description,
    required this.value, required this.index, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: value
                ? AppTheme.primary.withValues(alpha: 0.3)
                : AppTheme.divider(context),
          ),
          boxShadow: value ? [AppTheme.shadow] : [],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ])),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
    );
  }
}

class _AffirmationPreview extends StatefulWidget {
  @override
  State<_AffirmationPreview> createState() => _AffirmationPreviewState();
}

class _AffirmationPreviewState extends State<_AffirmationPreview>
    with SingleTickerProviderStateMixin {
  static const _samples = [
    'You are allowed to take up space and be exactly who you are.',
    'Every small step forward is still progress. Be proud of yourself.',
    'You have survived every difficult day so far. You are stronger than you know.',
    'Rest is not a reward — it is a necessity. Give yourself permission to pause.',
  ];

  int _idx = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _next() async {
    await _ctrl.reverse();
    setState(() => _idx = (_idx + 1) % _samples.length);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Sample Affirmation', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [AppTheme.shadowStrong],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeTransition(
            opacity: _fade,
            child: Text(
              '"${_samples[_idx]}"',
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppTheme.white,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _next,
            child: Text(
              'See another',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.white.withValues(alpha: 0.75),
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}
