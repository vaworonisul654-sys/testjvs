import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../state/mentor_provider.dart';
import '../../config/app_config.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentorProvider>();
    final history = provider.profile.sessionHistory;

    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundColor),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverToBoxAdapter(child: _buildHeader()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverToBoxAdapter(child: _buildStatsGrid(provider)),
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(left: 24, top: 30, bottom: 16),
                  sliver: SliverToBoxAdapter(
                    child: Text('RECENT SESSIONS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSessionItem(history[index]),
                    childCount: history.length,
                  ),
                ),
                if (history.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No sessions recorded yet.', style: TextStyle(color: Colors.white24))),
                  ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A192F), Color(0xFF1B263B)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEARNER MEMORY',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 40, height: 3, color: const Color(AppConfig.primaryColor)),
      ],
    );
  }

  Widget _buildStatsGrid(MentorProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('LEVEL', 'Lvl ${provider.profile.overallLevel.toStringAsFixed(1)}', Icons.trending_up),
        _buildStatCard('WORDS', '${provider.profile.learnedVocabulary.length}', Icons.menu_book),
        _buildStatCard('SESSIONS', '${provider.profile.sessionHistory.length}', Icons.history),
        _buildStatCard('ACCURACY', '88%', Icons.check_circle_outline),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(AppConfig.primaryColor), size: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem(dynamic session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(AppConfig.primaryColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.topic, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(session.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Text('${session.successRate * 100}%', style: const TextStyle(color: Color(AppConfig.primaryColor), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
