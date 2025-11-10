import 'package:just_audio/just_audio.dart';

class SoundController {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCorrect() async {
    _player.addAudioSource(AudioSource.asset('assets/sounds/thief_select.mp3'));

    await _player.play();
  }

  Future<void> playWrong() async {
    _player.addAudioSource(AudioSource.asset('assets/sounds/thief_select.mp3'));

    await _player.play();
  }

  Future<void> playSound({required String path}) async {
    await _player.setAsset('assets/sounds/$path');
    await _player.play();
  }

  Future<void> playStop() async {
    await _player.stop();
  }
}
