import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class GeminiLiveService {
  WebSocketChannel? _channel;
  bool _isSessionActive = false;
  
  // Callbacks
  Function(String)? onTranslatedText;
  Function(List<int>)? onAudioData;
  Function()? onTurnComplete;
  Function(String)? onUserTranscription;
  Function(String)? onError;
  Function()? onSetupComplete;

  static const String _host = "generativelanguage.googleapis.com";
  static const String _version = "v1alpha";
  
  bool get isSessionActive => _isSessionActive;

  void startSession({
    required String apiKey,
    required String systemInstruction,
    String model = "models/gemini-2.0-flash-exp",
  }) {
    final url = "wss://$_host/ws/google.ai.generativelanguage.$_version.GenerativeService.BidiGenerateContent?key=$apiKey";
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isSessionActive = true;
      
      _listen();
      _sendSetup(systemInstruction, model);
    } catch (e) {
      onError?.call("Connection failed: $e");
    }
  }

  void _sendSetup(String systemInstruction, String model) {
    if (_channel == null) return;

    final setup = {
      "setup": {
        "model": model,
        "generation_config": {
          "response_modalities": ["AUDIO"],
          "speech_config": {
            "voice_config": {
              "prebuilt_voice_config": {"voice_name": "Puck"}
            }
          }
        },
        "system_instruction": {
          "parts": [{"text": systemInstruction}]
        }
      }
    };
    
    _channel!.sink.add(jsonEncode(setup));
  }

  void sendAudioChunk(List<int> pcmData) {
    if (_channel == null || !_isSessionActive) return;

    final message = {
      "realtime_input": {
        "media_chunks": [
          {"data": base64Encode(pcmData), "mime_type": "audio/pcm;rate=16000"}
        ]
      }
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  void sendTextMessage(String text) {
     if (_channel == null || !_isSessionActive) return;

    final message = {
      "client_content": {
        "turns": [
          {"parts": [{"text": text}], "role": "user"}
        ],
        "turn_complete": true
      }
    };
    
    _channel!.sink.add(jsonEncode(message));
  }

  void _listen() {
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      
      if (data["setup_complete"] != null) {
        onSetupComplete?.call();
      }
      
      if (data["server_content"] != null) {
        final content = data["server_content"];
        
        if (content["model_turn"] != null) {
          final parts = content["model_turn"]["parts"];
          for (var part in parts) {
            if (part["text"] != null) {
              onTranslatedText?.call(part["text"]);
            }
            if (part["inline_data"] != null) {
              final audio = base64Decode(part["inline_data"]["data"]);
              onAudioData?.call(audio);
            }
          }
        }
        
        if (content["turn_complete"] == true) {
          onTurnComplete?.call();
        }
      }
    }, onError: (e) {
      onError?.call(e.toString());
      _isSessionActive = false;
    }, onDone: () {
      _isSessionActive = false;
    });
  }

  void endSession() {
    _channel?.sink.close();
    _channel = null;
    _isSessionActive = false;
  }
}
