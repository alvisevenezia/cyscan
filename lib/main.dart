import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/cy_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..checkAdminStatus(),
      child: const CyScanApp(),
    ),
  );
}

class CyScanApp extends StatelessWidget {
  const CyScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyScan',
      debugShowCheckedModeBanner: false,
      theme: CyTheme.theme,
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const ScannerScreen(),
      // Bouton paramètres serveur — discret, coin bas gauche
      Positioned(
        bottom: 28, left: 20,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.wifi_rounded, color: Colors.white38, size: 18),
          ),
        ),
      ),
    ]);
  }
}