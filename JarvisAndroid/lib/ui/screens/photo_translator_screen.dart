import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../config/app_config.dart';
import '../../services/openai_service.dart';

class PhotoTranslatorScreen extends StatefulWidget {
  const PhotoTranslatorScreen({super.key});

  @override
  State<PhotoTranslatorScreen> createState() => _PhotoTranslatorScreenState();
}

class _PhotoTranslatorScreenState extends State<PhotoTranslatorScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final OpenAIService _openAIService = OpenAIService();
  
  bool _isProcessing = false;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || _isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      
      final image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _openAIService.analyzeImage(
        base64Image,
        'Translate any text in this image. If it is an object, identify it and translate its name to Russian or English depending on context. Output ONLY the translation.',
      );

      setState(() {
        _resultText = result;
      });
    } catch (e) {
      debugPrint('Error taking photo: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundColor),
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildOverlay(),
          if (_resultText != null) _buildResultCard(),
          if (_isProcessing) _buildProcessingIndicator(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null) return const Center(child: CircularProgressIndicator());
    
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SizedBox.expand(
            child: CameraPreview(_controller!),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildOverlay() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeader(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => setState(() => _resultText = null),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildCaptureControls(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHOTO TRANSLATOR',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 30, height: 3, color: const Color(AppConfig.primaryColor)),
      ],
    );
  }

  Widget _buildCaptureControls() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, color: Color(AppConfig.backgroundColor), size: 32),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Positioned(
      bottom: 120,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(AppConfig.primaryColor), size: 18),
                    SizedBox(width: 8),
                    Text('AI ANALYSIS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _resultText!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: CircularProgressIndicator(color: Color(AppConfig.primaryColor)),
      ),
    );
  }
}
