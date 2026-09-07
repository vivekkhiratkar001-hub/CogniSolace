import 'package:flutter/material.dart';
import '../widgets/large_button.dart';
import 'games_screen.dart';
import 'assistant_screen.dart';
import 'reminder_screen.dart';
import 'progress_screen.dart';

/// Home Screen for COGNISOLACE
///
/// Designed specifically for elderly dementia patients in the North Eastern Region (NER).
/// Key Focus:
/// - Extreme visual simplicity (Zero clutter)
/// - Reusable LargeButton widgets for aging eyes & motor tremor support
/// - Clear, reassuring greetings
/// - Tablet & mobile responsive layout
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen responsiveness: check if viewing on a tablet or phone
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7), // Soft calming anti-glare background
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Responsive constraint: keeps layout focused and clean on tablets
            constraints: const BoxConstraints(maxWidth: 650),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32.0 : 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top App Title
                  const Text(
                    'COGNISOLACE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      color: Color(0xFF1B5E20), // Tea Garden / Forest Green
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // 2. Friendly Elderly Greeting
                  Text(
                    'Good Morning, User! 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 32.0 : 26.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A2E22), // High contrast dark text
                    ),
                  ),

                  const SizedBox(height: 8.0),

                  // Gentle reassurance subtitle
                  const Text(
                    'Tap any big button below to begin:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF526057),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // 3. Button 1: Play Game
                  LargeButton(
                    title: 'Play Game 🎮',
                    subtitle: 'Exercise your memory with fun games',
                    icon: Icons.sports_esports_rounded,
                    backgroundColor: const Color(0xFF1B5E20), // Forest Green
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GamesScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10.0),

                  // 4. Button 2: AI Assistant
                  LargeButton(
                    title: 'AI Assistant 🤖',
                    subtitle: 'Chat and get simple memory help',
                    icon: Icons.smart_toy_rounded,
                    backgroundColor: const Color(0xFF0277BD), // Soothing Blue
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssistantScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10.0),

                  // 5. Button 3: Today's Routine
                  LargeButton(
                    title: "Today's Routine ⏰",
                    subtitle: 'Check your daily reminders and tasks',
                    icon: Icons.access_time_filled_rounded,
                    backgroundColor: const Color(0xFFD84315), // Warm Orange
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReminderScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10.0),

                  // 6. Button 4: My Progress
                  LargeButton(
                    title: 'My Progress 📊',
                    subtitle: 'View your activity and score summary',
                    icon: Icons.bar_chart_rounded,
                    backgroundColor: const Color(0xFF4527A0), // Royal Purple
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28.0),

                  // ── Voice Help Section ──────────────────────────────────
                  // Optional secondary entry-point for elderly users who
                  // prefer speaking over tapping small buttons.
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'or use voice',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.0)),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // Large outlined Voice Help button
                  // Navigates to the AI Assistant so the user can speak
                  // TODO (Member 4): launch speech recognition directly here
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssistantScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.mic_rounded,
                      size: 28.0,
                      color: Color(0xFF0277BD),
                    ),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎤  Voice Help',
                          style: TextStyle(
                            fontSize: isTablet ? 20.0 : 18.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0277BD),
                          ),
                        ),
                        Text(
                          'Tap and speak to get help',
                          style: TextStyle(
                            fontSize: isTablet ? 15.0 : 13.5,
                            color: const Color(0xFF37474F),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, isTablet ? 80.0 : 70.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 14.0,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF0277BD),
                        width: 2.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      backgroundColor: const Color(0xFFE3F2FD), // Light blue
                    ),
                  ),

                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
