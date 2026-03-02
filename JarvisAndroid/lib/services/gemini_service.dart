import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class GeminiService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connect(String apiKey, {String? customSystemInstruction}) async {
    final url = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey";
    _channel = WebSocketChannel.connect(Uri.parse(url));
    
    _channel!.stream.listen((message) {
      final decoded = jsonDecode(message);
      _messageController.add(decoded);
    }, onError: (error) {
      _messageController.add({"error": error.toString()});
    });
    
    _sendSetupControl(customSystemInstruction);
  }

  void _sendSetupControl(String? systemInstruction) {
    final setupMessage = {
      "setup": {
        "model": AppConfig.geminiModel,
        "generation_config": {
          "response_modalities": ["audio"],
          "speech_config": {
            "voice_config": {
              "prebuilt_voice_config": {"voice_name": "Puck"}
            }
          }
        },
        if (systemInstruction != null)
          "system_instruction": {
            "parts": [{"text": systemInstruction}]
          }
      }
    };
    _channel?.sink.add(jsonEncode(setupMessage));
  }

  Future<void> sendAudioChunk(Uint8List chunk) async {
    final b64 = base64Encode(chunk);
    final message = {
      "realtime_input": {
        "media_chunks": [{"data": b64, "mime_type": "audio/pcm"}]
      }
    };
    _channel?.sink.add(jsonEncode(message));
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
  }
}
