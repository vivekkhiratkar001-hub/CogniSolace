import 'package:flutter/material.dart';
import '../widgets/score_card.dart';

/// Progress Screen for COGNISOLACE
///
/// Project: AI-Based Cognitive Gaming and Memory Assistance Platform
///          for Elderly Dementia Patients in North Eastern Region (NER)
///
/// Role: Member 1 – Flutter Frontend Developer
///
/// Purpose:
/// - Displays simple, encouraging cognitive wellness scores using reusable ScoreCard widgets.
/// - Strictly avoids complex graphs or confusing analytics to prevent anxiety.
/// - Uses dummy data; will be populated by FastAPI backend & adaptive AI models later.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  // Color constants (Royal Purple for positive encouragement & calming greens)
  static const Color progressPurple = Color(0xFF4527A0);
  static const Color backgroundColor = Color(0xFFF7FAF7);
  static const Color textPrimary = Color(0xFF1A2E22);
  static const Color textSecondary = Color(0xFF37474F);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: backgroundColor,

      // 1. Clear AppBar with Title & Large Back Button
      appBar: AppBar(
        backgroundColor: progressPurple,
        foregroundColor: Colors.white,
        elevation: 2.0,
        toolbarHeight: 72.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32.0),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Progress 📊',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Responsive constraint: avoids stretched layout on tablets
            constraints: const BoxConstraints(maxWidth: 680.0),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32.0 : 20.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encouraging Banner
                  Container(
                    padding: EdgeInsets.all(isTablet ? 24.0 : 18.0),
                    decoration: BoxDecoration(
                      color: progressPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(
                        color: progressPurple.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isTablet ? 60.0 : 50.0,
                          height: isTablet ? 60.0 : 50.0,
                          decoration: const BoxDecoration(
                            color: progressPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 30.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wonderful Work! 🌟',
                                style: TextStyle(
                                  fontSize: isTablet ? 22.0 : 19.0,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'You are exercising your memory regularly. Keep it up!',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.5,
                                  color: textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Section Title
                  Text(
                    'Activity Summary',
                    style: TextStyle(
                      fontSize: isTablet ? 24.0 : 20.0,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // -----------------------------------------------------------
                  // CARD 1: Games Played (12)
                  // -----------------------------------------------------------
                  const ScoreCard(
                    emoji: '🎮',
                    title: 'Games Played',
                    value: '12',
                    description: 'Fun games completed this week',
                    icon: Icons.sports_esports_rounded,
                    accentColor: Color(0xFF1B5E20), // Forest Green
                  ),

                  const SizedBox(height: 10.0),

                  // -----------------------------------------------------------
                  // CARD 2: Average Score (75%)
                  // -----------------------------------------------------------
                  const ScoreCard(
                    emoji: '⭐',
                    title: 'Average Score',
                    value: '75%',
                    description: 'Consistent performance and accuracy',
                    icon: Icons.star_rounded,
                    accentColor: Color(0xFFF57F17), // Warm Amber
                  ),

                  const SizedBox(height: 10.0),

                  // -----------------------------------------------------------
                  // CARD 3: Memory Performance (80%)
                  // -----------------------------------------------------------
                  const ScoreCard(
                    emoji: '🧠',
                    title: 'Memory Performance',
                    value: '80%',
                    description: 'Pattern recall and recognition score',
                    icon: Icons.psychology_rounded,
                    accentColor: Color(0xFF0277BD), // Soothing Blue
                  ),

                  const SizedBox(height: 10.0),

                  // -----------------------------------------------------------
                  // CARD 4: Today's Activity (Completed)
                  // -----------------------------------------------------------
                  const ScoreCard(
                    emoji: '📅',
                    title: "Today's Activity",
                    value: 'Completed',
                    description: 'Daily brain exercise routine finished',
                    icon: Icons.check_circle_rounded,
                    accentColor: Color(0xFF2E7D32), // Success Green
                    isValueText: true,
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
