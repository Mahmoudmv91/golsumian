import 'package:audioplayers/audioplayers.dart';

class SoundController {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCorrect() async {
    await _player.play(AssetSource('sounds/jump_circle_correct.mp3'));
  }

  Future<void> playWrong() async {
    await _player.play(AssetSource('sounds/jump_circle_wrong.mp3'));
  }

  Future<void> playSound({required String path}) async {
    await _player.play(AssetSource('sounds/$path'));
  }

  Future<void> playStop()async{
    await _player.stop();
  }
}
