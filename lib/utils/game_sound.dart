import 'package:audioplayers/audioplayers.dart';

class GameSound {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void playSound(String assetPath) async {
    await _audioPlayer.play(AssetSource(assetPath));
    //print('sim');
  }

  static void stopSound() {
    _audioPlayer.stop();
  }

  static void loser(String assetPath) async {
    // await _audioPlayer.play();
  }
}
