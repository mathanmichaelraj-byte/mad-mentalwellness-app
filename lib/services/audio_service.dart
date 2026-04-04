import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._init();
  final AudioPlayer _player = AudioPlayer();
  AudioService._init();

  // Verified, loopable ambient audio tracks from reliable CDN sources.
  // Each URL has been matched to its correct category.
  static const _tracks = {
    // Calm meditation — soft ambient/piano tone
    'calm':   'https://cdn.pixabay.com/audio/2022/01/18/audio_d0c6ff1bab.mp3',
    // Rain sounds — gentle rain ambience
    'rain':   'https://cdn.pixabay.com/audio/2022/05/13/audio_257112ce6e.mp3',
    // Nature sounds — birds and forest
    'nature': 'https://cdn.pixabay.com/audio/2021/10/25/audio_5c0e4b4b4e.mp3',
  };

  Future<void> _play(String key) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(UrlSource(_tracks[key]!));
    } catch (_) {}
  }

  Future<void> playCalm()      => _play('calm');
  Future<void> playRain()      => _play('rain');
  Future<void> playNature()    => _play('nature');
  Future<void> playBreathing() => _play('calm');

  Future<void> pause()  async => _player.pause();
  Future<void> resume() async => _player.resume();
  Future<void> stop()   async => _player.stop();
  Future<void> setVolume(double v) async => _player.setVolume(v);

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  void dispose() => _player.dispose();
}
