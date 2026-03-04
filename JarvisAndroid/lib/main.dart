import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/design_system.dart';
import 'views/main_tab_navigator.dart';
import 'viewmodels/mentor_view_model.dart';
import 'views/translator_view.dart'; // Using the VM defined inside

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force dark mode and transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: DesignSystem.background,
  ));

  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MentorViewModel()..init()),
        ChangeNotifierProvider(create: (_) => TranslatorViewModel()),
      ],
      child: MaterialApp(
        title: 'J.A.R.V.I.S.',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: DesignSystem.background,
          primaryColor: DesignSystem.emerald,
          colorScheme: ColorScheme.fromSeed(
            seedColor: DesignSystem.emerald,
            brightness: Brightness.dark,
            background: DesignSystem.background,
          ),
          useMaterial3: true,
        ),
        home: const MainTabNavigator(),
      ),
    );
  }
}
