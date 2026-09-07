import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CogniSolaceApp());
}

/// Root Application for COGNISOLACE
///
/// Specially customized for Elderly Dementia Patients in the North Eastern Region (NER).
/// Role: Member 1 – Flutter Frontend Developer.
class CogniSolaceApp extends StatelessWidget {
  const CogniSolaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application Title
      title: 'COGNISOLACE',
      debugShowCheckedModeBanner: false,

      // Elderly-Friendly Central Theme
      theme: AppTheme.lightTheme,

      // Starting Screen of the Application
      home: const HomeScreen(),
    );
  }
}
