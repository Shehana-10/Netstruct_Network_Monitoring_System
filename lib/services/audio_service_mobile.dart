// audio_service_mobile.dart
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playNotificationSound() async {
    try {
      // Remove "assets/" from the path since it's already included
      await _audioPlayer.play(AssetSource('audio/mixkit.wav'));
      print('Mobile audio played successfully');
    } catch (e) {
      print('AudioPlayers failed: $e');
      // More detailed error handling
      print('Make sure the file exists at: assets/audio/mixkit.wav');
      print('And pubspec.yaml has: "assets/audio/mixkit.wav"');
    }
  }
}
