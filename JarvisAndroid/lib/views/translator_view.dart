import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/design_system.dart';
import '../viewmodels/translator_view_model.dart';

class MainTranslatorView extends StatelessWidget {
  const MainTranslatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TranslatorViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(decoration: const BoxDecoration(gradient: DesignSystem.mainGradient)),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildTranslationList(viewModel),
                ),
                _buildActionArea(viewModel),
                const SizedBox(height: 100), // Tab bar space
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("ГОЛОС", style: DesignSystem.labelSmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: DesignSystem.glassDecoration(radius: 20),
            child: const Row(
              children: [
                Text("RU", style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.swap_horiz, size: 16, color: DesignSystem.emerald),
                Text("EN", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.history, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildTranslationList(TranslatorViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: viewModel.history.length,
      itemBuilder: (context, index) {
        final item = viewModel.history[index];
        return _buildChatBubble(item);
      },
    );
  }

  Widget _buildChatBubble(TranslationItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.originalText, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DesignSystem.glassDecoration(radius: 16),
            child: Text(
              item.translatedText,
              style: const TextStyle(color: DesignSystem.emerald, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(TranslatorViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: GestureDetector(
          onTap: () => viewModel.toggleRecording(),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: viewModel.isRecording ? Colors.red.withOpacity(0.2) : DesignSystem.emerald.withOpacity(0.1),
              border: Border.all(
                color: viewModel.isRecording ? Colors.red : DesignSystem.emerald,
                width: 2,
              ),
            ),
            child: Icon(
              viewModel.isRecording ? Icons.stop : Icons.mic,
              color: viewModel.isRecording ? Colors.red : DesignSystem.emerald,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

// Simplified ViewModel for Demo parity
class TranslatorViewModel extends ChangeNotifier {
  bool isRecording = false;
  List<TranslationItem> history = [];

  void toggleRecording() {
    isRecording = !isRecording;
    if (!isRecording) {
      // Mock translation
      history.insert(0, TranslationItem(originalText: "Привет, как дела?", translatedText: "Hello, how are you?"));
    }
    notifyListeners();
  }
}

class TranslationItem {
  final String originalText;
  final String translatedText;
  TranslationItem({required this.originalText, required this.translatedText});
}
