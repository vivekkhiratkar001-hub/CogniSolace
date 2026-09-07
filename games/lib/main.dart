import 'package:flutter/material.dart';
import 'games_catalog.dart';

/// Minimal local development/test runner for the Cognitive Games module.
/// Launches the dementia-friendly catalog providing access to:
/// - Know My People
/// - Daily Market
/// - My Day
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CogniSolaceGamesTestApp());
}

class CogniSolaceGamesTestApp extends StatelessWidget {
  const CogniSolaceGamesTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniSolace Cognitive Games (Dev Runner)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          primary: const Color(0xFF1E3A5F),
          secondary: const Color(0xFF2E6F40),
        ),
      ),
      home: const CognitiveGamesCatalog(),
    );
  }
}
