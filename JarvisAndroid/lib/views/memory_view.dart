import 'package:flutter/material.dart';
import '../utils/design_system.dart';

class MemoryView extends StatelessWidget {
  const MemoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background components
          Container(decoration: const BoxDecoration(gradient: DesignSystem.mainGradient)),
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.emerald.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildTemplateList()),
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Floating Action Button for Memory
          Positioned(
            right: 24,
            bottom: 120,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: DesignSystem.emerald,
              child: const Icon(Icons.add, color: DesignSystem.background),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            "Память",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            "0 из 10 шаблонов",
            style: TextStyle(fontSize: 13, color: Color(0x6600E08E), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cpu_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "Ваша память пуста",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
