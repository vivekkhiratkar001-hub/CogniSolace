import 'package:flutter/material.dart';
import 'bridges/adaptive_engine_bridge.dart';
import 'bridges/backend_sync_bridge.dart';
import 'content/content_repository.dart';
import 'content/local_content_repository.dart';
import 'content/models/caregiver_profile.dart';
import 'core/constants/game_constants.dart';
import 'core/models/game_difficulty.dart';
import 'core/models/game_result.dart';
import 'games/daily_market/views/daily_market_view.dart';
import 'games/know_my_people/views/know_my_people_view.dart';
import 'games/memory_of_home/views/memory_of_home_view.dart';
import 'games/my_day/views/my_day_view.dart';
import 'games/pattern_path/views/pattern_path_view.dart';

/// Top-level Dementia-Friendly Game Hub / Launcher.
/// Designed for single-line plug-and-play integration by Member 1 (Main App).
class CognitiveGamesCatalog extends StatefulWidget {
  final String patientId;
  final String initialRegion;
  final CaregiverProfile? caregiverProfile;
  final ContentRepository? contentRepository;
  final AdaptiveEngineBridge? adaptiveEngine;
  final BackendSyncBridge? backendSync;
  final Function(GameResult result)? onGameFinished;

  const CognitiveGamesCatalog({
    super.key,
    this.patientId = 'patient_ner_001',
    this.initialRegion = 'assam',
    this.caregiverProfile,
    this.contentRepository,
    this.adaptiveEngine,
    this.backendSync,
    this.onGameFinished,
  });

  @override
  State<CognitiveGamesCatalog> createState() => _CognitiveGamesCatalogState();
}

class _CognitiveGamesCatalogState extends State<CognitiveGamesCatalog> {
  late final ContentRepository _contentRepo;
  late final AdaptiveEngineBridge _adaptiveEngine;
  late final BackendSyncBridge _backendSync;

  late String _currentRegion;
  GameDifficulty _selectedDifficulty = GameDifficulty.easy;

  @override
  void initState() {
    super.initState();
    _contentRepo = widget.contentRepository ?? LocalContentRepository();
    _adaptiveEngine = widget.adaptiveEngine ?? LocalRuleBasedAdaptiveEngine();
    _backendSync = widget.backendSync ?? LocalOfflineBufferSync();
    _currentRegion = widget.initialRegion;
  }

  void _handleGameResult(GameResult result) {
    _backendSync.sendGameResult(result);
    _adaptiveEngine.submitTelemetry(result);
    widget.onGameFinished?.call(result);
  }

  Future<void> _launchGame(String gameId) async {
    try {
      // 1. Check recommended difficulty from Adaptive Engine or use selected difficulty
      final recommendedDifficulty = await _adaptiveEngine.getRecommendedDifficulty(
        patientId: widget.patientId,
        gameId: gameId,
      );
      final effectiveDifficulty = _selectedDifficulty != GameDifficulty.easy
          ? _selectedDifficulty
          : recommendedDifficulty;

      // 2. Generate culturally and personally adapted scenario
      final scenario = await _contentRepo.generateScenario(
        gameId: gameId,
        difficulty: effectiveDifficulty,
        regionId: _currentRegion,
        caregiverProfile: widget.caregiverProfile,
      );

      if (!mounted) return;

      Widget gameWidget;
      switch (gameId) {
        case 'know_my_people':
          gameWidget = KnowMyPeopleView(
            patientId: widget.patientId,
            scenario: scenario,
            onFinish: () => Navigator.of(context).pop(),
            onResult: _handleGameResult,
          );
          break;
        case 'memory_of_home':
          gameWidget = MemoryOfHomeView(
            patientId: widget.patientId,
            scenario: scenario,
            onFinish: () => Navigator.of(context).pop(),
            onResult: _handleGameResult,
          );
          break;
        case 'daily_market':
          gameWidget = DailyMarketView(
            patientId: widget.patientId,
            scenario: scenario,
            onFinish: () => Navigator.of(context).pop(),
            onResult: _handleGameResult,
          );
          break;
        case 'my_day':
          gameWidget = MyDayView(
            patientId: widget.patientId,
            scenario: scenario,
            onFinish: () => Navigator.of(context).pop(),
            onResult: _handleGameResult,
          );
          break;
        case 'pattern_path':
          gameWidget = PatternPathView(
            patientId: widget.patientId,
            scenario: scenario,
            onFinish: () => Navigator.of(context).pop(),
            onResult: _handleGameResult,
          );
          break;
        default:
          return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => gameWidget),
      );
    } catch (e, st) {
      debugPrint('_launchGame error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load game: $e')),
        );
      }
    }
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DementiaUX.cardBorderRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 38, color: color),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: DementiaUX.fontTitle,
                          fontWeight: FontWeight.bold,
                          color: DementiaUX.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: DementiaUX.fontBody,
                          color: DementiaUX.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill_rounded, size: 44, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DementiaUX.backgroundWarm,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 76,
        title: const Text(
          'Cognitive Games',
          style: TextStyle(
            fontSize: DementiaUX.fontTitle,
            fontWeight: FontWeight.bold,
            color: DementiaUX.textDark,
          ),
        ),
      ),
      body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Regional selection banner (NER Cultural customization)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: DementiaUX.accentAmber, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            'Region: ',
                            style: TextStyle(
                              fontSize: DementiaUX.fontBody,
                              fontWeight: FontWeight.bold,
                              color: DementiaUX.textDark,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _currentRegion,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              fontSize: DementiaUX.fontBody,
                              fontWeight: FontWeight.w600,
                              color: DementiaUX.primaryNavy,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'assam', child: Text('Assam (অসম)')),
                              DropdownMenuItem(value: 'meghalaya', child: Text('Meghalaya')),
                              DropdownMenuItem(value: 'generic', child: Text('Default Familiar')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _currentRegion = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded,
                              color: DementiaUX.primarySage, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            'Difficulty: ',
                            style: TextStyle(
                              fontSize: DementiaUX.fontBody,
                              fontWeight: FontWeight.bold,
                              color: DementiaUX.textDark,
                            ),
                          ),
                          DropdownButton<GameDifficulty>(
                            value: _selectedDifficulty,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              fontSize: DementiaUX.fontBody,
                              fontWeight: FontWeight.w600,
                              color: DementiaUX.primarySage,
                            ),
                            items: GameDifficulty.values.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d.displayName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDifficulty = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Game 1
                _buildGameCard(
                  title: 'Know My People',
                  subtitle: 'Remember and recognize family & caregivers',
                  icon: Icons.people_alt_rounded,
                  color: DementiaUX.primaryNavy,
                  onTap: () => _launchGame('know_my_people'),
                ),

                // Game 2
                _buildGameCard(
                  title: 'Memory of Home',
                  subtitle: 'Remember familiar objects and find what is missing',
                  icon: Icons.home_rounded,
                  color: const Color(0xFF5B3E8C),
                  onTap: () => _launchGame('memory_of_home'),
                ),

                // Game 3
                _buildGameCard(
                  title: 'Daily Market',
                  subtitle: 'Focus and find familiar goods in the stall',
                  icon: Icons.storefront_rounded,
                  color: DementiaUX.primarySage,
                  onTap: () => _launchGame('daily_market'),
                ),

                // Game 4
                _buildGameCard(
                  title: 'My Day',
                  subtitle: 'Arrange familiar daily living routines',
                  icon: Icons.today_rounded,
                  color: DementiaUX.accentAmber,
                  onTap: () => _launchGame('my_day'),
                ),

                // Game 5
                _buildGameCard(
                  title: 'Pattern Path',
                  subtitle: 'Recognize sequences and find the next shape',
                  icon: Icons.alt_route_rounded,
                  color: const Color(0xFFC85A32),
                  onTap: () => _launchGame('pattern_path'),
                ),
              ],
            ),
    );
  }
}
