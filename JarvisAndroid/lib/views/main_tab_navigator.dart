import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import 'translator_view.dart';
import 'mentor_view.dart';
import 'memory_view.dart';

class MainTabNavigator extends StatefulWidget {
  const MainTabNavigator({super.key});

  @override
  State<MainTabNavigator> createState() => _MainTabNavigatorState();
}

class _MainTabNavigatorState extends State<MainTabNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MainTranslatorView(),
    const Center(child: Text("Текст")),  
    const MentorView(),
    const Center(child: Text("Фото")),   
    const MemoryView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(decoration: const BoxDecoration(gradient: DesignSystem.mainGradient)),
          
          // Page Content
          _pages[_selectedIndex],

          // Floating Tab Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildFloatingTabBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 72,
            decoration: DesignSystem.glassDecoration(radius: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tabItem(0, Icons.waves, "Голос"),
                _tabItem(1, Icons.chat_bubble_outline, "Текст"),
                _jarvisCentralButton(),
                _tabItem(3, Icons.camera_alt_outlined, "Фото"),
                _tabItem(4, Icons.memory, "Память"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? DesignSystem.emerald : Colors.white.withOpacity(0.3),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? DesignSystem.emerald : Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _jarvisCentralButton() {
    bool isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                DesignSystem.emerald.withOpacity(0.8),
                DesignSystem.emerald.withAlpha(50),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DesignSystem.emerald.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: DesignSystem.emerald.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
