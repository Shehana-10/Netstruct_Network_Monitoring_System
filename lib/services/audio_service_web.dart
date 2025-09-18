// audio_service_web.dart
import 'dart:html' as html;

class AudioService {
  static void playNotificationSound() {
    try {
      final audio =
          html.AudioElement()
            ..src = 'assets/audio/mixkit.wav'
            ..autoplay = true
            ..volume = 0.7;

      html.document.body?.append(audio);

      // Clean up after playback or timeout
      audio.onEnded.listen((_) => audio.remove());
      Future.delayed(Duration(seconds: 5), () => audio.remove());

      print('Web audio played successfully');
    } catch (e) {
      print('HTML audio failed: $e');
    }
  }
}
