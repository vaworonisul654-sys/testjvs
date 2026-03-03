import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../config/app_config.dart';
import '../../services/openai_service.dart';

class TextTranslatorScreen extends StatefulWidget {
  const TextTranslatorScreen({super.key});

  @override
  State<TextTranslatorScreen> createState() => _TextTranslatorScreenState();
}

class _TextTranslatorScreenState extends State<TextTranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final OpenAIService _openAIService = OpenAIService();
  
  String _sourceLanguage = 'Russian';
  String _targetLanguage = 'English';
  bool _isTranslating = false;

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      
      final tempText = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = tempText;
    });
  }

  Future<void> _translate() async {
    if (_inputController.text.isEmpty) return;
    
    setState(() => _isTranslating = true);
    
    try {
      final result = await _openAIService.translateText(
        _inputController.text,
        _targetLanguage,
      );
      setState(() {
        _outputController.text = result;
      });
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundColor),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildLanguageSelector(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildInputCard(),
                          const SizedBox(height: 16),
                          _buildOutputCard(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTranslateButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A192F), Color(0xFF112240)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TEXT TRANSLATION',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          color: const Color(AppConfig.primaryColor),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Center(child: Text(_sourceLanguage, style: const TextStyle(color: Colors.white70)))),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Color(AppConfig.primaryColor)),
            onPressed: _swapLanguages,
          ),
          Expanded(child: Center(child: Text(_targetLanguage, style: const TextStyle(color: Colors.white70)))),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return _buildGlassCard(
      child: TextField(
        controller: _inputController,
        maxLines: 6,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Enter text here...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return _buildGlassCard(
      color: const Color(AppConfig.primaryColor).withOpacity(0.05),
      child: TextField(
        controller: _outputController,
        maxLines: 6,
        readOnly: true,
        style: const TextStyle(color: Color(AppConfig.secondaryColor), fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Translation will appear here...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTranslateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isTranslating ? null : _translate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConfig.primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: const Color(AppConfig.primaryColor).withOpacity(0.5),
        ),
        child: _isTranslating
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'TRANSLATE',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
