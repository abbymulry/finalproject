import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSuccessSound() async {
    try {
      await _player.stop(); // Stop any current sound
      await _player.play(AssetSource('assets/sounds/success.ogg'));
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }
}