import 'package:flutter/material.dart';

/// Game Screen UI Container for COGNISOLACE
///
/// Project: AI-Based Cognitive Gaming and Memory Assistance Platform
///          for Elderly Dementia Patients in North Eastern Region (NER)
///
/// Role: Member 1 – Flutter Frontend Developer
///
/// Responsibility:
/// - Provides the accessible UI container, navigation, metrics, and instructions.
/// - Member 2 will develop and integrate the actual cognitive game logic into
///   the large designated placeholder area.
/// - Contains zero ML, AI, RAG, LLM, or backend code.
class GameScreen extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final Color themeColor;

  const GameScreen({
    super.key,
    this.gameId = 'memory_matching',
    this.gameTitle = 'Memory Matching Game',
    this.themeColor = const Color(0xFF1B5E20), // Calm Forest / Tea Garden Green
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Dummy metrics as specified in requirements
  int _score = 0;
  final String _difficulty = 'Easy';

  /// Shows a high-contrast, elderly-friendly SnackBar notification
  void _showNotification(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.all(20.0),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Restarts game metrics (dummy interaction)
  void _restartGame() {
    setState(() {
      _score = 0;
    });
    _showNotification('Game restarted! Score has been reset to 0.');
  }

  /// Exits the game screen and returns to games menu
  void _exitGame() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Screen responsiveness: adjust dimensions for tablet vs mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // High-contrast, glare-free color palette
    const Color backgroundColor = Color(0xFFF7FAF7);
    const Color textPrimary = Color(0xFF1A2E22);
    const Color textSecondary = Color(0xFF37474F);

    return Scaffold(
      backgroundColor: backgroundColor,

      // 1. Clear AppBar with Back Button and Game Title
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 2.0,
        toolbarHeight: 72.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32.0),
          tooltip: 'Back to Games',
          onPressed: _exitGame,
        ),
        title: Text(
          widget.gameTitle,
          style: TextStyle(
            fontSize: isTablet ? 24.0 : 21.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Responsive constraint: keeps layout comfortable on wide screens
            constraints: const BoxConstraints(maxWidth: 680.0),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 28.0 : 18.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. Score and Difficulty Display
                  _buildMetricsRow(isTablet),

                  const SizedBox(height: 18.0),

                  // 3. Instructions Section
                  _buildInstructionsCard(isTablet, textPrimary, textSecondary),

                  const SizedBox(height: 20.0),

                  // 4. Large Placeholder Area for Member 2's Game Widget
                  _buildGamePlaceholderArea(isTablet, textPrimary, textSecondary),

                  const SizedBox(height: 24.0),

                  // 5. Large Action Buttons: Restart & Exit Game
                  _buildActionButtons(isTablet),

                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Metric display cards for Score and Difficulty
  Widget _buildMetricsRow(bool isTablet) {
    return Row(
      children: [
        // Score Display
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20.0 : 16.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: widget.themeColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2.0),
                ),
              ],
            ),
            child: Row(
              children: [
                // Trophy Icon Badge
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: widget.themeColor,
                    size: isTablet ? 30.0 : 26.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF526057),
                      ),
                    ),
                    Text(
                      '$_score',
                      style: TextStyle(
                        fontSize: isTablet ? 26.0 : 22.0,
                        fontWeight: FontWeight.w900,
                        color: widget.themeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14.0),

        // Difficulty Display
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20.0 : 16.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: const Color(0xFF0277BD).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2.0),
                ),
              ],
            ),
            child: Row(
              children: [
                // Speed/Difficulty Icon Badge
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0277BD).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.speed_rounded,
                    color: Color(0xFF0277BD),
                    size: 26.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Difficulty',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF526057),
                      ),
                    ),
                    Text(
                      _difficulty,
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0277BD),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Simple Instructions section with reassuring, non-punishing guidance
  Widget _buildInstructionsCard(
    bool isTablet,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: widget.themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: widget.themeColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: widget.themeColor,
                size: 26.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            '1. Look carefully at the activity cards on screen.',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 15.0,
              color: textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '2. Tap to find matching pairs or repeat the pattern.',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 15.0,
              color: textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '3. Take your time! There is no timer or pressure.',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 15.0,
              fontWeight: FontWeight.w600,
              color: widget.themeColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Large Placeholder Area reserved for Member 2's Cognitive Game Widget
  Widget _buildGamePlaceholderArea(
    bool isTablet,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      constraints: BoxConstraints(
        minHeight: isTablet ? 300.0 : 250.0,
      ),
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 4.0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Game Icon Badge
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_esports_rounded,
              size: isTablet ? 48.0 : 40.0,
              color: widget.themeColor,
            ),
          ),

          const SizedBox(height: 16.0),

          // Title
          Text(
            'Game Widget Area',
            style: TextStyle(
              fontSize: isTablet ? 24.0 : 20.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 6.0),

          // Clarifying description for team integration
          Text(
            'This space is reserved for Member 2 to plug in the interactive cognitive game widget.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.5,
              color: textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20.0),

          // Interactive sample cards demonstrating touch accessibility
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.center,
            children: [
              _buildPlaceholderCard('🌿 Tea Leaf', isTablet),
              _buildPlaceholderCard('🦏 Rhino', isTablet),
              _buildPlaceholderCard('🎋 Bamboo', isTablet),
              _buildPlaceholderCard('🌸 Orchid', isTablet),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper for sample placeholder cards
  Widget _buildPlaceholderCard(String label, bool isTablet) {
    return Material(
      color: widget.themeColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          setState(() {
            _score += 10;
          });
          _showNotification('Selected $label! (+10 pts)');
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 22.0 : 16.0,
            vertical: 12.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: widget.themeColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.bold,
              color: widget.themeColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Large Elderly-Friendly Action Buttons: Restart Game & Exit Game
  Widget _buildActionButtons(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Large Restart Game Button
        ElevatedButton(
          onPressed: _restartGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeColor,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, isTablet ? 64.0 : 56.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            elevation: 3.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: isTablet ? 30.0 : 26.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Restart Game',
                style: TextStyle(
                  fontSize: isTablet ? 21.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12.0),

        // Large Exit Game Button
        OutlinedButton(
          onPressed: _exitGame,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF37474F),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFCFD8DC), width: 2.0),
            minimumSize: Size(double.infinity, isTablet ? 64.0 : 56.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            elevation: 1.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.exit_to_app_rounded,
                size: isTablet ? 28.0 : 24.0,
                color: const Color(0xFF37474F),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Exit Game',
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF37474F),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
