import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../state/mentor_provider.dart';
import '../../config/app_config.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  @override
  void initState() {
    super.initState();
    // Re-connect in Mentor mode when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MentorProvider>();
      provider.connect(AppConfig.geminiKey, isMentorMode: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentorProvider>();
    
    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundColor),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildJarvisCore(provider.isRecording),
                const Spacer(),
                _buildConversationCard(provider.transcript),
                const SizedBox(height: 20),
                _buildMicButton(provider),
                const SizedBox(height: 40),
              ],
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Color(AppConfig.primaryColor), size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JARVIS CORE',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'MENTOR SYSTEM ACTIVE',
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJarvisCore(bool isActive) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rings
        _buildRing(size: 200, opacity: 0.1, duration: 4000),
        _buildRing(size: 160, opacity: 0.2, duration: 3000),
        
        // Inner Core
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(AppConfig.primaryColor),
                const Color(AppConfig.primaryColor).withOpacity(0.5),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(AppConfig.primaryColor).withOpacity(0.5),
                blurRadius: isActive ? 40 : 20,
                spreadRadius: isActive ? 10 : 0,
              ),
            ],
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 50),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
      ],
    );
  }

  Widget _buildRing({required double size, required double opacity, required int duration}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(AppConfig.primaryColor).withOpacity(opacity), width: 2),
      ),
    ).animate(onPlay: (c) => c.repeat())
     .rotate(duration: Duration(milliseconds: duration));
  }

  Widget _buildConversationCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              text.isEmpty ? "Welcome back! Ready for our next lesson?" : text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(MentorProvider provider) {
    return GestureDetector(
      onTap: () => provider.toggleRecording(),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: provider.isRecording ? Colors.red : const Color(AppConfig.primaryColor),
        ),
        child: Icon(
          provider.isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
