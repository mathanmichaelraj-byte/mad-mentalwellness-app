import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/behavior_tracker.dart';
import '../utils/app_theme.dart';

class BreathingTechnique {
  final String name;
  final String description;
  final String purpose;
  final int inhale;
  final int hold;
  final int exhale;
  final int cycles;
  final IconData icon;
  final Gradient gradient;

  BreathingTechnique({
    required this.name,
    required this.description,
    required this.purpose,
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.cycles,
    required this.icon,
    required this.gradient,
  });
}

class BreathingTechniquesScreen extends StatelessWidget {
  const BreathingTechniquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final techniques = _buildTechniques();
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Breathing Techniques'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: techniques.length,
        itemBuilder: (context, index) {
          final t = techniques[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + index * 70),
            curve: Curves.easeOut,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
            ),
            child: _TechniqueCard(
              technique: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BreathingExerciseScreen(technique: t)),
              ),
            ),
          );
        },
      ),
    );
  }

  List<BreathingTechnique> _buildTechniques() => [
    BreathingTechnique(
      name: '4-7-8 Relaxation', description: 'Calms nervous system, reduces anxiety',
      purpose: 'Stress & Anxiety Relief', inhale: 4, hold: 7, exhale: 8, cycles: 4,
      icon: Icons.nightlight_rounded, gradient: AppTheme.gradient,
    ),
    BreathingTechnique(
      name: 'Box Breathing', description: 'Used by Navy SEALs for focus',
      purpose: 'Focus & Concentration', inhale: 4, hold: 4, exhale: 4, cycles: 5,
      icon: Icons.crop_square_rounded, gradient: AppTheme.gradient,
    ),
    BreathingTechnique(
      name: 'Anger Release', description: 'Quick exhale releases tension',
      purpose: 'Anger Management', inhale: 3, hold: 2, exhale: 6, cycles: 6,
      icon: Icons.whatshot_rounded, gradient: AppTheme.gradient,
    ),
    BreathingTechnique(
      name: 'Grief Comfort', description: 'Gentle rhythm for emotional pain',
      purpose: 'Sadness & Grief', inhale: 5, hold: 3, exhale: 7, cycles: 5,
      icon: Icons.favorite_rounded, gradient: AppTheme.gradient,
    ),
    BreathingTechnique(
      name: 'Energy Boost', description: 'Increases alertness and energy',
      purpose: 'Low Energy', inhale: 2, hold: 1, exhale: 2, cycles: 10,
      icon: Icons.bolt_rounded, gradient: AppTheme.gradient,
    ),
    BreathingTechnique(
      name: 'Sleep Preparation', description: 'Slows heart rate for better sleep',
      purpose: 'Insomnia & Restlessness', inhale: 4, hold: 6, exhale: 8, cycles: 6,
      icon: Icons.bedtime_rounded, gradient: AppTheme.gradient,
    ),
  ];
}

class _TechniqueCard extends StatelessWidget {
  final BreathingTechnique technique;
  final VoidCallback onTap;
  const _TechniqueCard({required this.technique, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          boxShadow: [AppTheme.shadow],
        ),
        child: Row(children: [
          Container(
            width: 72, height: 80,
            decoration: BoxDecoration(
              gradient: technique.gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radius),
                bottomLeft: Radius.circular(AppTheme.radius),
              ),
            ),
            child: Icon(technique.icon, color: Colors.white, size: 30),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(technique.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(technique.purpose,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                const SizedBox(height: 2),
                Text(technique.description,
                    style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                // Timing chips
                Row(children: [
                  _TimingChip('In ${technique.inhale}s'),
                  if (technique.hold > 0) ...[const SizedBox(width: 6), _TimingChip('Hold ${technique.hold}s')],
                  const SizedBox(width: 6),
                  _TimingChip('Out ${technique.exhale}s'),
                ]),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  final String label;
  const _TimingChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary)),
  );
}

// ── Breathing Exercise Screen ─────────────────────────────────────────────────

enum _Phase { ready, inhale, hold, exhale, complete }

class BreathingExerciseScreen extends StatefulWidget {
  final BreathingTechnique technique;
  const BreathingExerciseScreen({super.key, required this.technique});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _currentCycle = 0;
  int _countdown = 0;
  _Phase _phase = _Phase.ready;

  // Circle scale animation
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  // Ripple animation
  late AnimationController _rippleCtrl;

  // Fade for phase label
  late AnimationController _labelCtrl;
  late Animation<double> _labelFade;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );

    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _labelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _labelFade = CurvedAnimation(parent: _labelCtrl, curve: Curves.easeInOut);
    _labelCtrl.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    _rippleCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _startExercise() {
    BehaviorTracker.instance.trackInteraction();
    HapticFeedback.mediumImpact();
    setState(() { _currentCycle = 1; });
    _startInhale();
  }

  void _startInhale() {
    _setPhase(_Phase.inhale, widget.technique.inhale);
    _scaleCtrl.duration = Duration(seconds: widget.technique.inhale);
    _scaleCtrl.forward(from: 0);
    _runTimer(widget.technique.inhale, _startHold);
  }

  void _startHold() {
    _setPhase(_Phase.hold, widget.technique.hold);
    _runTimer(widget.technique.hold, _startExhale);
  }

  void _startExhale() {
    _setPhase(_Phase.exhale, widget.technique.exhale);
    _scaleCtrl.duration = Duration(seconds: widget.technique.exhale);
    _scaleCtrl.reverse(from: 1);
    _runTimer(widget.technique.exhale, _nextCycle);
  }

  void _nextCycle() {
    HapticFeedback.lightImpact();
    if (_currentCycle < widget.technique.cycles) {
      setState(() => _currentCycle++);
      _startInhale();
    } else {
      _complete();
    }
  }

  void _setPhase(_Phase phase, int seconds) {
    _labelCtrl.reverse().then((_) {
      if (mounted) {
        setState(() { _phase = phase; _countdown = seconds; });
        _labelCtrl.forward();
      }
    });
  }

  void _complete() {
    _timer?.cancel();
    _scaleCtrl.stop();
    HapticFeedback.heavyImpact();
    setState(() { _phase = _Phase.complete; });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Well Done! 🎉'),
        content: Text(
          'You completed ${widget.technique.cycles} cycles of ${widget.technique.name}.\nHow do you feel?',
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Finish'),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _startExercise(); },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 44)),
            child: const Text('Repeat'),
          ),
        ],
      ),
    );
  }

  void _runTimer(int seconds, VoidCallback onComplete) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) { t.cancel(); onComplete(); }
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    _scaleCtrl.stop();
    setState(() { _phase = _Phase.ready; _currentCycle = 0; _countdown = 0; });
  }

  bool get _isRunning => _phase != _Phase.ready && _phase != _Phase.complete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(widget.technique.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(children: [
          // Progress indicator
          if (_isRunning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(children: [
                Text('Cycle $_currentCycle of ${widget.technique.cycles}',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
                const Spacer(),
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentCycle / widget.technique.cycles,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
              ]),
            ),

          Expanded(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Animated breathing circle
                SizedBox(
                  width: 280, height: 280,
                  child: Stack(alignment: Alignment.center, children: [
                    // Ripple rings (only when running)
                    if (_isRunning)
                      AnimatedBuilder(
                        animation: _rippleCtrl,
                        builder: (_, __) {
                          return Stack(alignment: Alignment.center, children: [
                            _RippleRing(progress: _rippleCtrl.value, maxRadius: 140),
                            _RippleRing(progress: (_rippleCtrl.value + 0.5) % 1.0, maxRadius: 140),
                          ]);
                        },
                      ),
                    // Main breathing circle
                    AnimatedBuilder(
                      animation: _scaleAnim,
                      builder: (_, __) {
                        final scale = _isRunning ? _scaleAnim.value : 0.7;
                        final size = 160.0 * scale + 40;
                        return Container(
                          width: size, height: size,
                          decoration: BoxDecoration(
                            gradient: widget.technique.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35 * scale),
                                blurRadius: 40 * scale,
                                spreadRadius: 8 * scale,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _countdown > 0
                                ? Text(
                                    '$_countdown',
                                    style: const TextStyle(
                                      fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white,
                                    ),
                                  )
                                : Icon(widget.technique.icon, color: Colors.white, size: 48),
                          ),
                        );
                      },
                    ),
                  ]),
                ),

                const SizedBox(height: 40),

                // Phase label with fade
                FadeTransition(
                  opacity: _labelFade,
                  child: Text(
                    _phaseLabel(),
                    style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Instruction text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    key: ValueKey(_phase),
                    _phaseInstruction(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15, color: AppTheme.textSecondary(context), height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Technique info chips
                if (!_isRunning && _phase == _Phase.ready)
                  Wrap(
                    spacing: 10, runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoChip('Inhale ${widget.technique.inhale}s', Icons.arrow_upward_rounded),
                      if (widget.technique.hold > 0)
                        _InfoChip('Hold ${widget.technique.hold}s', Icons.pause_rounded),
                      _InfoChip('Exhale ${widget.technique.exhale}s', Icons.arrow_downward_rounded),
                      _InfoChip('${widget.technique.cycles} cycles', Icons.repeat_rounded),
                    ],
                  ),
              ]),
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _isRunning
                ? ElevatedButton.icon(
                    onPressed: _stopExercise,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _phase == _Phase.complete ? null : _startExercise,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_phase == _Phase.complete ? 'Completed!' : 'Begin Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  String _phaseLabel() {
    switch (_phase) {
      case _Phase.ready:    return 'Ready';
      case _Phase.inhale:   return 'Breathe In';
      case _Phase.hold:     return 'Hold';
      case _Phase.exhale:   return 'Breathe Out';
      case _Phase.complete: return 'Complete! 🎉';
    }
  }

  String _phaseInstruction() {
    switch (_phase) {
      case _Phase.ready:
        return 'Find a comfortable position.\nTake a moment to settle in.';
      case _Phase.inhale:
        return 'Slowly breathe in through your nose.\nFeel your chest and belly expand.';
      case _Phase.hold:
        return 'Hold your breath gently.\nStay still and relaxed.';
      case _Phase.exhale:
        return 'Slowly breathe out through your mouth.\nRelease all tension with the breath.';
      case _Phase.complete:
        return 'You did it! Take a moment\nto notice how you feel.';
    }
  }
}

class _RippleRing extends StatelessWidget {
  final double progress;
  final double maxRadius;
  const _RippleRing({required this.progress, required this.maxRadius});

  @override
  Widget build(BuildContext context) {
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.25;
    return Container(
      width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppTheme.primary),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
    ]),
  );
}
