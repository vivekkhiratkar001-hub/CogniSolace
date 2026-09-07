import 'package:flutter/material.dart';
import 'game_screen.dart';

/// Cognitive Games Selection Screen for COGNISOLACE
///
/// Role: Member 1 – Flutter Frontend Developer
///
/// Note: Member 2 is responsible for the underlying game logic and cognitive models.
/// This screen provides an accessible, elderly-friendly UI with placeholder navigation.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  /// Helper to perform placeholder navigation to a selected game
  void _navigateToGame(BuildContext context, String gameId, String gameTitle, Color themeColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          gameId: gameId,
          gameTitle: gameTitle,
          themeColor: themeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Screen responsiveness for phone vs tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Calming, high-contrast colors suited for elderly dementia patients
    const Color forestGreen = Color(0xFF1B5E20);
    const Color calmingBlue = Color(0xFF0277BD);
    const Color backgroundColor = Color(0xFFF7FAF7);
    const Color textPrimary = Color(0xFF1A2E22);
    const Color textSecondary = Color(0xFF37474F);

    return Scaffold(
      backgroundColor: backgroundColor,

      // Clear, large AppBar with accessible Back button
      appBar: AppBar(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 2.0,
        toolbarHeight: 72.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32.0),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cognitive Games',
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
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Friendly Page Heading
                  Text(
                    'Choose a Game to Play',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 28.0 : 24.0,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8.0),

                  // Simple, reassuring instruction
                  Text(
                    'Tap the large "Start Game" button to begin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 18.0 : 16.0,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28.0),

                  // -------------------------------------------------------------
                  // GAME 1: Memory Matching Game
                  // -------------------------------------------------------------
                  _buildGameCard(
                    context: context,
                    isTablet: isTablet,
                    title: 'Memory Matching Game',
                    emoji: '🧠',
                    description: 'Match similar pictures and improve memory.',
                    icon: Icons.psychology_rounded,
                    themeColor: forestGreen,
                    onStart: () => _navigateToGame(
                      context,
                      'memory_matching',
                      'Memory Matching Game',
                      forestGreen,
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // -------------------------------------------------------------
                  // GAME 2: Sequence Memory Game
                  // -------------------------------------------------------------
                  _buildGameCard(
                    context: context,
                    isTablet: isTablet,
                    title: 'Sequence Memory Game',
                    emoji: '🔢',
                    description: 'Remember and repeat the sequence.',
                    icon: Icons.format_list_numbered_rounded,
                    themeColor: calmingBlue,
                    onStart: () => _navigateToGame(
                      context,
                      'sequence_memory',
                      'Sequence Memory Game',
                      calmingBlue,
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

  /// Reusable Game Card Widget with large icon, text, and dedicated Start Game button
  Widget _buildGameCard({
    required BuildContext context,
    required bool isTablet,
    required String title,
    required String emoji,
    required String description,
    required IconData icon,
    required Color themeColor,
    required VoidCallback onStart,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.3),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12.0,
            offset: const Offset(0, 4.0),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 26.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row containing Large Icon and Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large Circular Icon Avatar
              Container(
                width: isTablet ? 72.0 : 62.0,
                height: isTablet ? 72.0 : 62.0,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: isTablet ? 42.0 : 36.0,
                    color: themeColor,
                  ),
                ),
              ),

              const SizedBox(width: 18.0),

              // Game Title with Emoji
              Expanded(
                child: Text(
                  '$emoji $title',
                  style: TextStyle(
                    fontSize: isTablet ? 23.0 : 20.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2E22),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14.0),

          // Simple Description for Elderly Users
          Text(
            description,
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF37474F),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20.0),

          // Large Accessible "Start Game" Button
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, isTablet ? 64.0 : 56.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 3.0,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: isTablet ? 34.0 : 28.0,
                  color: Colors.white,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Start Game',
                  style: TextStyle(
                    fontSize: isTablet ? 22.0 : 19.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
