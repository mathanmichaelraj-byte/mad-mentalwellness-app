import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_service.dart';
import '../services/behavior_tracker.dart';
import '../utils/app_theme.dart';

class _Track {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Future<void> Function() play;
  const _Track({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.play,
  });
}

class _Section {
  final String label;
  final List<_Track> tracks;
  const _Section(this.label, this.tracks);
}

class CalmAudioScreen extends StatefulWidget {
  const CalmAudioScreen({super.key});
  @override
  State<CalmAudioScreen> createState() => _CalmAudioScreenState();
}

class _CalmAudioScreenState extends State<CalmAudioScreen>
    with SingleTickerProviderStateMixin {
  String _activeId = '';
  bool _isPlaying = false;
  double _volume = 0.8;
  late AnimationController _pulseCtrl;
  late final List<_Section> _sections;

  @override
  void initState() {
    super.initState();

    _sections = [
      _Section('🧘 Meditation', [
        _Track(
          id: 'calm',
          title: 'Calm Meditation',
          description: 'Soft ambient tones to quiet the mind',
          icon: Icons.self_improvement_outlined,
          color: AppTheme.primary,
          play: AudioService.instance.playCalm,
        ),
      ]),
      _Section('🌿 Nature', [
        _Track(
          id: 'rain',
          title: 'Rain Sounds',
          description: 'Gentle rain — perfect for focus or sleep',
          icon: Icons.water_drop_outlined,
          color: const Color(0xFF6366F1),
          play: AudioService.instance.playRain,
        ),
        _Track(
          id: 'nature',
          title: 'Forest Birds',
          description: 'Birds and woodland ambience',
          icon: Icons.forest_outlined,
          color: const Color(0xFF10B981),
          play: AudioService.instance.playNature,
        ),
        _Track(
          id: 'ocean',
          title: 'Ocean Waves',
          description: 'Deep ambient ocean soundscape',
          icon: Icons.waves_outlined,
          color: const Color(0xFF0EA5E9),
          play: AudioService.instance.playOcean,
        ),
      ]),
      _Section('🌙 Sleep', [
        _Track(
          id: 'sleep',
          title: 'Sleep Music',
          description: 'Gentle instrumental to drift off',
          icon: Icons.bedtime_outlined,
          color: const Color(0xFF8B5CF6),
          play: AudioService.instance.playSleep,
        ),
      ]),
      _Section('🎯 Focus', [
        _Track(
          id: 'focus',
          title: 'Focus Flow',
          description: 'Steady rhythm to sharpen concentration',
          icon: Icons.center_focus_strong_outlined,
          color: const Color(0xFFF59E0B),
          play: AudioService.instance.playFocus,
        ),
      ]),
    ];

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    AudioService.instance.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    AudioService.instance.setVolume(_volume);
  }

  @override
  void dispose() {
    AudioService.instance.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  _Track? get _activeTrack {
    for (final s in _sections) {
      for (final t in s.tracks) {
        if (t.id == _activeId) return t;
      }
    }
    return null;
  }

  Future<void> _selectTrack(_Track track) async {
    BehaviorTracker.instance.trackInteraction();
    if (_activeId == track.id && _isPlaying) {
      await AudioService.instance.pause();
      return;
    }
    if (_activeId == track.id && !_isPlaying) {
      await AudioService.instance.resume();
      return;
    }
    await AudioService.instance.stop();
    setState(() => _activeId = track.id);
    await track.play();
  }

  Future<void> _stop() async {
    await AudioService.instance.stop();
    setState(() {
      _activeId = '';
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeTrack;
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('🎵 Calm Audio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Now Playing card
            if (active != null) ...[
              _NowPlayingCard(
                track: active,
                isPlaying: _isPlaying,
                pulseCtrl: _pulseCtrl,
                onPlayPause: () => _selectTrack(active),
                onStop: _stop,
              ),
              const SizedBox(height: 10),
              // Volume slider
              Row(children: [
                Icon(Icons.volume_down_rounded,
                    color: AppTheme.textSecondary(context), size: 18),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor:
                          AppTheme.primary.withValues(alpha: 0.15),
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withValues(alpha: 0.1),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        AudioService.instance.setVolume(v);
                      },
                    ),
                  ),
                ),
                Icon(Icons.volume_up_rounded,
                    color: AppTheme.textSecondary(context), size: 18),
              ]),
              const SizedBox(height: 24),
            ],

            // Sections
            ..._sections.map((section) => _buildSection(section)),

            const SizedBox(height: 16),
            // Tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Icon(Icons.headphones_outlined,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Use headphones for the most immersive calming experience.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(_Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 10),
        ...section.tracks.map((t) => _TrackTile(
              track: t,
              isActive: _activeId == t.id,
              isPlaying: _activeId == t.id && _isPlaying,
              onTap: () => _selectTrack(t),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Now Playing Card ──────────────────────────────────────────────────────────
class _NowPlayingCard extends StatelessWidget {
  final _Track track;
  final bool isPlaying;
  final AnimationController pulseCtrl;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  const _NowPlayingCard({
    required this.track,
    required this.isPlaying,
    required this.pulseCtrl,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.gradientDeep,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [AppTheme.shadowStrong],
      ),
      child: Column(children: [
        ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.08).animate(
            CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(
              isPlaying ? Icons.graphic_eq_rounded : track.icon,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'NOW PLAYING',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 1.4),
        ),
        const SizedBox(height: 6),
        Text(track.title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CtrlBtn(
              icon: isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              onTap: onPlayPause),
          const SizedBox(width: 16),
          _CtrlBtn(icon: Icons.stop_rounded, onTap: onStop),
        ]),
      ]),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CtrlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: AppTheme.primary, size: 28),
      ),
    );
  }
}

// ── Track Tile ────────────────────────────────────────────────────────────────
class _TrackTile extends StatelessWidget {
  final _Track track;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;
  const _TrackTile(
      {required this.track,
      required this.isActive,
      required this.isPlaying,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: isActive
                ? track.color.withValues(alpha: 0.6)
                : AppTheme.primary.withValues(alpha: 0.1),
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: isActive ? [AppTheme.shadow] : [],
        ),
        child: Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [track.color, track.color.withValues(alpha: 0.7)]
                    : [
                        track.color.withValues(alpha: 0.15),
                        track.color.withValues(alpha: 0.07)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radius),
                bottomLeft: Radius.circular(AppTheme.radius),
              ),
            ),
            child: Icon(track.icon,
                color: isActive ? Colors.white : track.color, size: 24),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isActive
                                ? track.color
                                : AppTheme.textPrimary(context),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(track.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(
              isPlaying
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_outline_rounded,
              color: isActive ? track.color : AppTheme.textSecondary(context),
              size: 28,
            ),
          ),
        ]),
      ),
    );
  }
}
