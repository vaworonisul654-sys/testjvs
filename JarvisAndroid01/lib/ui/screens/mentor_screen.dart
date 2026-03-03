import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../state/mentor_provider.dart';
import '../../config/app_config.dart';

class MentorScreen extends StatelessWidget {
  const MentorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentorProvider>();
    
    return Scaffold(
      backgroundColor: AppConfig.obsidian,
      body: Stack(
        children: [
          _buildGlowEffect(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, provider),
                const Spacer(),
                _buildBrainCore(provider),
                const Spacer(),
                _buildResponseArea(provider),
                const SizedBox(height: 40),
                _buildStatusFooter(provider),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Positioned(
      bottom: -100,
      child: Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppConfig.emerald.withOpacity(0.05),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .blur(begin: const Offset(80, 80), end: const Offset(120, 120), duration: 4.seconds),
    );
  }

  Widget _buildHeader(BuildContext context, MentorProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white30),
            onPressed: () => provider.endSession(),
          ),
          Text(
            "JARVIS CORE",
            style: TextStyle(
              color: AppConfig.emerald,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 14,
            ),
          ),
          const Icon(Icons.settings, color: Colors.white30),
        ],
      ),
    );
  }

  Widget _buildBrainCore(MentorProvider provider) {
    return GestureDetector(
      onTap: () {
        if (provider.isActive) {
          provider.endSession();
        } else {
          provider.startSession(autoStart: true);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulse Rings (matching iOS rings)
          for (int i = 0; i < 3; i++)
            _buildPulseRing(i, provider.isActive),
          
          // Main Core
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppConfig.emerald.withOpacity(0.8), AppConfig.emerald.withOpacity(0.2)],
              ),
              boxShadow: [
                BoxShadow(color: AppConfig.emerald.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)
              ],
            ),
            child: Icon(
              Icons.psychology, 
              size: 60, 
              color: Colors.white,
            ).animate(target: provider.state == MentorState.speaking ? 1 : 0)
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 500.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRing(int index, bool isActive) {
    return Container(
      width: 160.0 + (index * 60.0),
      height: 160.0 + (index * 60.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppConfig.emerald.withOpacity(0.15), width: 1),
      ),
    ).animate(onPlay: (c) => c.repeat())
     .scale(
       duration: 2.seconds, 
       delay: (index * 500).ms, 
       begin: const Offset(0.9, 0.9), 
       end: const Offset(1.1, 1.1),
       curve: Curves.easeInOut
     )
     .fadeOut(duration: 2.seconds);
  }

  Widget _buildResponseArea(MentorProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          if (provider.currentResponse.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                provider.currentResponse,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ).animate().fadeIn().moveY(begin: 20, end: 0)
          else
            Text(
              provider.state == MentorState.idle ? "Нажмите на ядро, чтобы начать урок" : "Подключение к ядру...",
              style: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter(MentorProvider provider) {
    if (provider.state == MentorState.active) {
      return Text("Я слушаю вас...", style: TextStyle(color: AppConfig.emerald, fontWeight: FontWeight.bold));
    }
    return const SizedBox();
  }
}
