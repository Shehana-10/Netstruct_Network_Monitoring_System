// services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      // Preload the sound for faster playback
      await _player.setSource(AssetSource('assets/audio/mixkit.mp3'));
      _isInitialized = true;
    }
  }

  static Future<void> playNotificationSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _player.seek(Duration.zero); // Reset to beginning
      await _player.resume();
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  static void dispose() {
    _player.dispose();
    _isInitialized = false;
  }
}
