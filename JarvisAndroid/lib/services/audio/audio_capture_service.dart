import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioCaptureService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<List<int>> _audioStreamController = StreamController<List<int>>.broadcast();
  
  Stream<List<int>> get audioStream => _audioStreamController.stream;
  bool _isRecording = false;

  Future<void> init() async {
    await _recorder.openRecorder();
  }

  Future<void> startCapture() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception("Microphone permission denied");
    }

    await _recorder.startRecorder(
      toStream: _audioStreamController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );
    _isRecording = true;
  }

  Future<void> stopCapture() async {
    await _recorder.stopRecorder();
    _isRecording = false;
  }

  void dispose() {
    _recorder.closeRecorder();
    _audioStreamController.close();
  }
}
