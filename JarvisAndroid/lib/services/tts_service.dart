import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import '../config/app_config.dart';

class TTSService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isSpeaking = false;
  
  // Jitter Buffer logic
  final List<Uint8List> _buffer = [];
  final int minBufferChunks = 1; // Instant start optimized

  Future<void> init() async {
    await _player.openPlayer();
  }

  Future<void> playChunk(Uint8List data) async {
    if (data.isEmpty) return;
    
    isSpeaking = true;
    _buffer.add(data);
    
    if (_buffer.length >= minBufferChunks) {
      final combinedData = Uint8List.fromList(_buffer.expand((x) => x).toList());
      _buffer.clear();
      
      await _player.feedFromStream(combinedData);
    }
  }

  Future<void> stop() async {
    await _player.stopPlayer();
    _buffer.clear();
    isSpeaking = false;
  }

  void dispose() {
    _player.closePlayer();
  }
}
