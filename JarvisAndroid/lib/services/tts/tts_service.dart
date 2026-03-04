import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class TTSService {
  final AudioPlayer _player = AudioPlayer();
  
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    // Initial configuration for low-latency playback
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playGeminiAudio(Uint8List audioData) async {
    _isSpeaking = true;
    try {
      await _player.play(BytesSource(audioData));
      // In a real implementation with streaming PCM, we'd use a more advanced 
      // buffer management, but for basic parity, this works.
    } catch (e) {
      print("TTS Playback error: $e");
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _player.dispose();
  }
}
