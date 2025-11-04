import 'package:audioplayers/audioplayers.dart';

class SoundController{


  final AudioPlayer _player = AudioPlayer();

  Future<void> playCorrect()async{
    await _player.play(AssetSource('sounds/correct.mp3'));
  }

  Future<void> playWrong()async{
    await _player.play(AssetSource('sounds/wrong.mp3'));
  }
}