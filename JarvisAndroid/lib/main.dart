import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:jarvis_voice_system/state/mentor_provider.dart';
import 'ui/root_tab_view.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MentorProvider()),
      ],
      child: const JarvisApp(),
    ),
  );
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'J.A.R.V.I.S.',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(AppConfig.primaryColor),
        scaffoldBackgroundColor: Color(AppConfig.backgroundColor),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const RootTabView(),
    );
  }
}
