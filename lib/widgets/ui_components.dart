import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/behavior_tracker.dart';
import '../services/emotional_inference_service.dart';
import '../models/emotional_confidence.dart';

// ── Shared primitives ─────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppTheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w700,
    ),
  );
}

class TealChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const TealChip({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.white : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isFullWidth;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppTheme.primary,
      foregroundColor: foregroundColor ?? AppTheme.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppTheme.space16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
    );
    final child = icon != null
        ? ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label), style: style)
        : ElevatedButton(onPressed: onPressed, style: style, child: Text(label));
    return isFullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class SuggestionItem extends StatelessWidget {
  final String text;
  const SuggestionItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ]),
    );
  }
}

class BreathingStep extends StatelessWidget {
  final String action;
  final String duration;
  final IconData icon;
  const BreathingStep({super.key, required this.action, required this.duration, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: AppTheme.space16),
        Expanded(child: Text(action, style: Theme.of(context).textTheme.titleMedium)),
        Text(duration, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class FadeScaleTransition extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeScaleTransition({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

// ── Home Screen Components ────────────────────────────────────────────────────

class HeaderSection extends StatelessWidget {
  final String? username;
  const HeaderSection({super.key, this.username});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // replaced by _HeroHeader in home_screen
}

class MedicalGuidanceCard extends StatelessWidget {
  final AnimationController fadeController;
  final VoidCallback onDismiss;
  const MedicalGuidanceCard({super.key, required this.fadeController, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeController,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: AppTheme.subtleGradient(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          boxShadow: [AppTheme.shadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('We\'re here for you', style: Theme.of(context).textTheme.titleLarge)),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 18, color: AppTheme.textSecondary(context)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              'We\'ve noticed patterns that suggest you might benefit from additional support.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ActionButton(label: 'Explore Support Options', isFullWidth: true,
                onPressed: () => Navigator.pushNamed(context, '/location')),
          ]),
        ),
      ),
    );
  }
}

class EmotionalStateCard extends StatelessWidget {
  final dynamic state;
  final dynamic confidence;
  final AnimationController fadeController;
  final AnimationController pulseController;

  const EmotionalStateCard({
    super.key,
    required this.state,
    required this.confidence,
    required this.fadeController,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeController,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          boxShadow: [AppTheme.shadow],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Gradient header band
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: AppTheme.gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'EMOTIONAL STATE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white70, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  _getDescription(),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                      color: Colors.white, height: 1.2),
                ),
              ])),
              if (confidence != null) _buildBadge(),
            ]),
          ),
          // Suggestions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ..._getSuggestions().map((s) => SuggestionItem(text: s)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildBadge() {
    final levelName = confidence.level.toString().split('.').last;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.7, end: 1.0)
          .animate(CurvedAnimation(parent: pulseController, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          levelName.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: 0.8),
        ),
      ),
    );
  }

  String _getDescription() {
    if (state is EmotionalState) {
      return EmotionalInferenceService.instance.getStateDescription(state as EmotionalState);
    }
    switch (state.toString().split('.').last) {
      case 'calm':       return 'You seem calm and balanced';
      case 'restless':   return 'You might be feeling restless';
      case 'stressed':   return 'You may be experiencing stress';
      case 'lowEnergy':  return 'Your energy seems low today';
      case 'distressed': return 'Patterns suggest some distress';
      default:           return 'Your state appears neutral';
    }
  }

  List<String> _getSuggestions() {
    if (state is EmotionalState && confidence is EmotionalConfidence) {
      return EmotionalInferenceService.instance.getSuggestions(
          state as EmotionalState, (confidence as EmotionalConfidence).level);
    }
    return ['Take a moment to breathe deeply', 'Stay hydrated', 'Consider a short walk'];
  }
}

// ── Wellness Tools — Vertical Rectangle List ──────────────────────────────────

class WellnessToolsList extends StatelessWidget {
  const WellnessToolsList({super.key});

  @override
  Widget build(BuildContext context) {
    // All tiles share the same unified teal gradient — deep teal → light teal
    // This gives a consistent, rich turquoise look across every tool
    const tealGradient = [AppTheme.primary, AppTheme.primaryLight];

    final features = [
      _Feature('Emotional Analysis', Icons.show_chart_rounded,     '/mood',         'mood_analysis',   tealGradient),
      _Feature('Mood Journal',       Icons.book_outlined,          '/journal',      'mood_journal',    tealGradient),
      _Feature('Daily Mood',         Icons.radio_button_checked,   '/mood_tracker', 'mood_tracker',    tealGradient),
      _Feature('Gratitude',          Icons.spa_outlined,           '/gratitude',    'gratitude',       tealGradient),
      _Feature('Affirmations',       Icons.format_quote_outlined,  '/affirmations', 'affirmations',    tealGradient),
      _Feature('Sleep Tracker',      Icons.nights_stay_outlined,   '/sleep',        'sleep',           tealGradient),
      _Feature('Progress',           Icons.bar_chart_rounded,      '/progress',     'progress',        tealGradient),
      _Feature('Calm Audio',         Icons.graphic_eq_rounded,     '/audio',        'calm_audio',      tealGradient),
      _Feature('Breathing',          Icons.blur_circular_outlined, '/breathing',    'breathing',       tealGradient),
      _Feature('Find Places',        Icons.near_me_outlined,       '/location',     'location',        tealGradient),
      _Feature('Emotional Release',  Icons.edit_outlined,          '/release',      'emotional_release', tealGradient),
    ];

    return Column(
      children: features.asMap().entries.map((e) => _ToolTile(
        feature: e.value,
        index: e.key,
      )).toList(),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final String route;
  final String featureKey;
  final List<Color> gradientColors;
  const _Feature(this.title, this.icon, this.route, this.featureKey, this.gradientColors);
}

// Short descriptions for each tool
const _descriptions = {
  'mood_analysis':    'Understand your emotional patterns',
  'mood_journal':     'Write diary entries with mood tags',
  'mood_tracker':     'Log how you feel each day',
  'gratitude':        'Three daily gratitude prompts',
  'affirmations':     'Curated words of encouragement',
  'sleep':            'Track your sleep quality and hours',
  'progress':         'Charts, streaks and NLP insights',
  'calm_audio':       'Soothing ambient soundscapes',
  'breathing':        'Guided breathing techniques',
  'location':         'Find therapists and calm spaces',
  'emotional_release':'Write freely in a safe space',
};

class _ToolTile extends StatefulWidget {
  final _Feature feature;
  final int index;
  const _ToolTile({required this.feature, required this.index});
  @override
  State<_ToolTile> createState() => _ToolTileState();
}

class _ToolTileState extends State<_ToolTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final desc = _descriptions[widget.feature.featureKey] ?? '';
    final colors = widget.feature.gradientColors;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + widget.index * 55),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(24 * (1 - v), 0), child: child),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          BehaviorTracker.instance.trackFeatureUsage(widget.feature.featureKey);
          Navigator.pushNamed(context, widget.feature.route);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              // Card background: very subtle teal tint gradient for richness
              gradient: LinearGradient(
                colors: [
                  AppTheme.surface(context),
                  AppTheme.primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
              boxShadow: [AppTheme.shadow],
            ),
            child: Row(children: [
              // Unified teal gradient left panel — taller for more presence
              Container(
                width: 76,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radius),
                    bottomLeft: Radius.circular(AppTheme.radius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Icon(widget.feature.icon, color: Colors.white, size: 28),
              ),
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      widget.feature.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
              ),
              // Arrow with teal tint
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Icon Container (backward compat) ─────────────────────────────────────────
class IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool useGradient;

  const IconContainer({
    super.key,
    required this.icon,
    required this.color,
    this.size = 22,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: useGradient ? color.withValues(alpha: 0.1) : color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, color: useGradient ? color : AppTheme.white, size: size),
    );
  }
}

// ── TealDot (used in other screens) ──────────────────────────────────────────
class TealDot extends StatelessWidget {
  final double size;
  const TealDot({super.key, this.size = 6});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
  );
}

// Keep WellnessToolsGrid as alias so other files don't break
class WellnessToolsGrid extends StatelessWidget {
  final dynamic responsive;
  const WellnessToolsGrid({super.key, required this.responsive});
  @override
  Widget build(BuildContext context) => const WellnessToolsList();
}

