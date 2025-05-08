import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playPhaseCompleteSound() async {
    try {
      await _player.stop(); // Stop any current sound
      await _player.play(AssetSource('assets/sounds/levelsuccess.wav'));
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }

  static Future<void> playGameCompleteSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.ogg'));
    } catch (e) {
      print('Error playing game complete sound: $e');
    }
  }
}