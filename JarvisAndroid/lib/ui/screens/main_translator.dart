import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'dart:ui';
import '../../state/mentor_provider.dart';
import '../../config/app_config.dart';

class MainTranslatorScreen extends StatelessWidget {
  const MainTranslatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConfig.backgroundColor),
      body: Stack(
        children: [
          // Background Gradient
          _buildBackground(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildStatusIndicator(context),
                  const SizedBox(height: 20),
                  _buildTerminalCard(context),
                  const Spacer(),
                  _buildMicButton(context),
                  const SizedBox(height: 40),
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
          colors: [
             Color(0xFF0A192F),
             Color(0xFF112240),
             Color(0xFF002147),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'J.A.R.V.I.S.',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'SYSTEM ACTIVATED',
                style: TextStyle(color: Color(AppConfig.primaryColor), fontSize: 10, letterSpacing: 3),
              ),
            ],
          ),
          const CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final provider = context.watch<MentorProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: provider.isRecording ? Colors.red : Color(AppConfig.primaryColor),
          ),
        ).animate(onPlay: (controller) => controller.repeat())
         .scale(duration: 800.ms, begin: const Offset(1,1), end: const Offset(1.5, 1.5))
         .then()
         .scale(duration: 800.ms, begin: const Offset(1.5,1.5), end: const Offset(1, 1)),
        const SizedBox(width: 10),
        Text(
          provider.currentStatus.toUpperCase(),
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalCard(BuildContext context) {
    final provider = context.watch<MentorProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.translate, color: Colors.white54, size: 16),
                    SizedBox(width: 8),
                    Text('LIVE TRANSCRIPT', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  provider.transcript.isEmpty ? "Waiting for system response..." : provider.transcript,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(BuildContext context) {
    final provider = context.read<MentorProvider>();
    final isRecording = context.select((MentorProvider p) => p.isRecording);
    
    return AvatarGlow(
      animate: isRecording,
      glowColor: isRecording ? Colors.red : Color(AppConfig.primaryColor),
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      child: GestureDetector(
        onTap: () => provider.toggleRecording(),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? Colors.red : Color(AppConfig.primaryColor),
            boxShadow: [
              BoxShadow(
                color: (isRecording ? Colors.red : Color(AppConfig.primaryColor)).withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 8,
              )
            ],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 42),
        ),
      ),
    );
  }
}
