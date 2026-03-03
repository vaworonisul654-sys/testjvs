import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_voice_system/ui/screens/main_translator.dart';
import 'package:jarvis_voice_system/ui/screens/text_translator_screen.dart';
import 'package:jarvis_voice_system/ui/screens/mentor_screen.dart';
import 'package:jarvis_voice_system/ui/screens/photo_translator_screen.dart';
import 'package:jarvis_voice_system/ui/screens/memory_screen.dart';
import 'package:jarvis_voice_system/config/app_config.dart';

class RootTabView extends StatefulWidget {
  const RootTabView({super.key});

  @override
  State<RootTabView> createState() => _RootTabViewState();
}

class _RootTabViewState extends State<RootTabView> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MainTranslatorScreen(),
    const TextTranslatorScreen(),
    const MentorScreen(),
    const PhotoTranslatorScreen(),
    const MemoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A192F),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF10B981), // Emerald
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mic_none), label: 'VOICE'),
            BottomNavigationBarItem(icon: Icon(Icons.translate), label: 'TEXT'),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF10B981),
                child: Icon(Icons.bolt, size: 18, color: Colors.white),
              ),
              label: 'CORE',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: 'PHOTO'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'MEMORY'),
          ],
        ),
      ),
    );
  }
}
