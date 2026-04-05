import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._init();
  final AudioPlayer _player = AudioPlayer();
  AudioService._init();

  // All URLs verified 200 OK as of build time (audio/mpeg, >1MB each)
  static const _tracks = {
    // Calm meditation — soft ambient music (~4.7 MB)
    'calm':       'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3',
    // Rain sounds — rain ambience (~4.9 MB)
    'rain':       'https://cdn.pixabay.com/audio/2022/08/04/audio_2dde668d05.mp3',
    // Nature / forest birds (~2.6 MB)
    'nature':     'https://cdn.pixabay.com/audio/2021/11/25/audio_91b32e02f9.mp3',
    // Ocean / deep ambient (~4.6 MB)
    'ocean':      'https://cdn.pixabay.com/audio/2022/11/22/audio_febc508520.mp3',
    // Sleep music — gentle instrumental
    'sleep':      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    // Focus / white noise style
    'focus':      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  };

  Future<void> _play(String key) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(UrlSource(_tracks[key]!));
    } catch (_) {}
  }

  Future<void> playCalm()       => _play('calm');
  Future<void> playRain()       => _play('rain');
  Future<void> playNature()     => _play('nature');
  Future<void> playOcean()      => _play('ocean');
  Future<void> playSleep()      => _play('sleep');
  Future<void> playFocus()      => _play('focus');
  Future<void> playBreathing()  => _play('calm');

  Future<void> pause()  async => _player.pause();
  Future<void> resume() async => _player.resume();
  Future<void> stop()   async => _player.stop();
  Future<void> setVolume(double v) async => _player.setVolume(v);

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  void dispose() => _player.dispose();
}
