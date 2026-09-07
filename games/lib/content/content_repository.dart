import '../core/models/game_difficulty.dart';
import '../core/models/game_scenario.dart';
import 'models/caregiver_profile.dart';
import 'models/content_pack.dart';

/// Abstract contract for loading culturally and personally familiar content.
/// Separates the game engine from raw JSON assets, local DBs, or cloud sync.
abstract class ContentRepository {
  /// Loads a specific cultural content pack
  Future<ContentPack> loadContentPack(String regionId);

  /// Generates a scenario for a given game and difficulty, applying the 3-tier fallback:
  /// 1. Caregiver personalized profile (if provided)
  /// 2. Regional pack (e.g. 'assam', 'meghalaya')
  /// 3. Generic default pack
  Future<GameScenario> generateScenario({
    required String gameId,
    required GameDifficulty difficulty,
    String? regionId,
    CaregiverProfile? caregiverProfile,
  });
}
