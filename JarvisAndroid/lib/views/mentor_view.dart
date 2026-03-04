import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/design_system.dart';
import '../viewmodels/mentor_view_model.dart';

class MentorView extends StatefulWidget {
  const MentorView({super.key});

  @override
  State<MentorView> createState() => _MentorViewState();
}

class _MentorViewState extends State<MentorView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MentorViewModel>();
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            bottom: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.emerald.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                const Text(
                  "JARVIS CORE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0x8000E08E),
                  ),
                ),
                const Spacer(),
                
                // Central Visualizer
                _buildCoreVisualizer(viewModel),
                
                const Spacer(),
                
                // Response Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(
                      viewModel.currentResponse.isNotEmpty 
                        ? viewModel.currentResponse 
                        : (viewModel.state == MentorState.idle 
                            ? "Нажмите на ядро, чтобы начать урок" 
                            : "Я слушаю..."),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 100), // Bottom Tab Bar padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close_rounded, color: Colors.white30, size: 28),
          ),
          
          // Dashboard Button
          Container(
             decoration: DesignSystem.glassDecoration(radius: 12),
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: const Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(Icons.bar_chart, color: DesignSystem.emerald, size: 14),
                 SizedBox(width: 8),
                 Text(
                   "ИТОГИ",
                   style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DesignSystem.emerald),
                 ),
               ],
             ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.white30, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreVisualizer(MentorViewModel viewModel) {
    bool isActive = viewModel.state != MentorState.idle;
    
    return GestureDetector(
      onTap: () {
        if (isActive) {
          viewModel.stopSession();
        } else {
          // In a real app, API Key would be fetched from secure config
          viewModel.startSession("YOUR_GEMINI_API_KEY"); 
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          double pulse = isActive ? (1.0 + _pulseController.value * 0.1) : 1.0;
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Rings
                if (isActive)
                  ...List.generate(3, (index) {
                    double scale = 1.0 + (index * 0.4) + (_pulseController.value * 0.2);
                    return Opacity(
                      opacity: (1.0 - _pulseController.value) * 0.2,
                      child: Container(
                        width: 140 * scale,
                        height: 140 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: DesignSystem.emerald, width: 1),
                        ),
                      ),
                    );
                  }),
                
                // Main Core
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DesignSystem.emerald.withOpacity(0.15),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            DesignSystem.emerald.withOpacity(0.8),
                            DesignSystem.emerald.withOpacity(0.3),
                          ],
                        ),
                        border: Border.all(color: DesignSystem.emerald.withOpacity(0.5), width: 2),
                      ),
                      child: Transform.scale(
                        scale: pulse,
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 48,
                          shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'package:google_fonts/google_fonts.dart';
