import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamController<Uint8List>? _audioStreamController;
  
  Future<void> init() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<Stream<Uint8List>> startCapture() async {
    _audioStreamController = StreamController<Uint8List>();
    
    await _recorder.startRecorder(
      toStream: _audioStreamController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: AppConfig.audioSampleRate,
    );
    
    return _audioStreamController!.stream;
  }

  Future<void> stopCapture() async {
    await _recorder.stopRecorder();
    await _audioStreamController?.close();
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}
