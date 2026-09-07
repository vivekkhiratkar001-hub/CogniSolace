import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models/game_difficulty.dart';
import '../core/models/game_item.dart';
import '../core/models/game_scenario.dart';
import 'content_repository.dart';
import 'models/caregiver_profile.dart';
import 'models/content_pack.dart';

/// Robust offline-first content repository implementing 3-tier fallback.
/// Tier 1: Caregiver Profile (personal photos, family relations, personal routine)
/// Tier 2: Selected North Eastern Regional Pack (Assam, Meghalaya, etc.)
/// Tier 3: Generic familiar home items & routines
class LocalContentRepository implements ContentRepository {
  static final Map<String, ContentPack> _packCache = {};

  @override
  Future<ContentPack> loadContentPack(String regionId) async {
    final normalized = regionId.toLowerCase().trim();
    if (_packCache.containsKey(normalized)) {
      return _packCache[normalized]!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/packs/${normalized}_pack.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final pack = ContentPack.fromJson(data);
      _packCache[normalized] = pack;
      return pack;
    } catch (_) {
      // Graceful fallback to embedded in-memory pack for resilience & offline unit testing
      final fallbackPack = _getEmbeddedFallbackPack(normalized);
      _packCache[normalized] = fallbackPack;
      return fallbackPack;
    }
  }

  @override
  Future<GameScenario> generateScenario({
    required String gameId,
    required GameDifficulty difficulty,
    String? regionId,
    CaregiverProfile? caregiverProfile,
  }) async {
    final targetRegion = regionId ?? caregiverProfile?.preferredRegion ?? 'assam';
    final pack = await loadContentPack(targetRegion);

    switch (gameId) {
      case 'know_my_people':
        return _buildKnowMyPeopleScenario(difficulty, caregiverProfile);
      case 'memory_of_home':
        return _buildMemoryOfHomeScenario(difficulty, pack, caregiverProfile);
      case 'daily_market':
        return _buildDailyMarketScenario(difficulty, pack, caregiverProfile);
      case 'my_day':
        return _buildMyDayScenario(difficulty, pack, caregiverProfile);
      case 'pattern_path':
        return _buildPatternPathScenario(difficulty);
      default:
        return _buildDailyMarketScenario(difficulty, pack, caregiverProfile);
    }
  }

  // -------------------------------------------------------------
  // Scenario Builders
  // -------------------------------------------------------------

  GameScenario _buildKnowMyPeopleScenario(
    GameDifficulty difficulty,
    CaregiverProfile? caregiver,
  ) {
    List<GameItem> familyCandidates;

    if (caregiver != null && caregiver.familyMembers.isNotEmpty) {
      // Tier 1: Caregiver provided family members
      familyCandidates = caregiver.familyMembers.map((m) {
        return GameItem(
          id: m.id,
          title: m.name,
          subtitle: m.relationship,
          imageAsset: m.photoPath,
          audioPrompt: m.voiceNotePath,
          category: 'family',
        );
      }).toList();
    } else {
      // Fallback familiar family members
      familyCandidates = const [
        GameItem(
          id: 'fam_1',
          title: 'Raju',
          subtitle: 'Son (Lara)',
          category: 'family',
        ),
        GameItem(
          id: 'fam_2',
          title: 'Sujata',
          subtitle: 'Daughter (Suwali)',
          category: 'family',
        ),
        GameItem(
          id: 'fam_3',
          title: 'Aarav',
          subtitle: 'Grandson (Nati)',
          category: 'family',
        ),
        GameItem(
          id: 'fam_4',
          title: 'Dr. Sharma',
          subtitle: 'Family Doctor',
          category: 'caregiver',
        ),
      ];
    }

    // Pick 1 target
    final target = familyCandidates.first;

    // Include all other available candidates in distractors for multi-round variety
    final distractors = familyCandidates.skip(1).toList();

    return GameScenario(
      id: 'kmp_${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'know_my_people',
      difficulty: difficulty,
      promptText: 'Who is this person?',
      targets: [target],
      distractors: distractors,
      hintText: 'This is your ${target.subtitle ?? "family member"}',
    );
  }

  GameScenario _buildDailyMarketScenario(
    GameDifficulty difficulty,
    ContentPack pack,
    CaregiverProfile? caregiver,
  ) {
    final allItems = List<GameItem>.from(pack.items);
    allItems.shuffle();

    int targetCount;

    switch (difficulty) {
      case GameDifficulty.easy:
        targetCount = 1;
        break;
      case GameDifficulty.medium:
        targetCount = 2;
        break;
      case GameDifficulty.hard:
        targetCount = 3;
        break;
    }

    final targets = allItems.take(targetCount).toList();
    // Include all other available items in distractors for multi-round sessions
    final distractors = allItems.skip(targetCount).toList();

    final promptNames = targets.map((t) => t.title).join(' and ');

    return GameScenario(
      id: 'dm_${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'daily_market',
      difficulty: difficulty,
      promptText: 'Please find $promptNames in the market stall.',
      targets: targets,
      distractors: distractors,
      hintText: 'Look for the ${targets.first.title}',
    );
  }

  GameScenario _buildMyDayScenario(
    GameDifficulty difficulty,
    ContentPack pack,
    CaregiverProfile? caregiver,
  ) {
    final rawSteps = pack.routineSteps;
    final int stepCount = difficulty == GameDifficulty.easy
        ? 2
        : (difficulty == GameDifficulty.medium ? 3 : 4);

    final selectedSteps = rawSteps.take(stepCount).toList();
    final targets = selectedSteps.map((s) => s.toGameItem()).toList();
    final remainingSteps = rawSteps.skip(stepCount).map((s) => s.toGameItem()).toList();
    final orderedIds = selectedSteps.map((s) => s.id).toList();

    return GameScenario(
      id: 'md_${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'my_day',
      difficulty: difficulty,
      promptText: 'Arrange your daily routine in order',
      targets: targets,
      distractors: remainingSteps,
      orderedTargetIds: orderedIds,
      hintText: 'First thing in the morning is: ${selectedSteps.first.title}',
    );
  }

  GameScenario _buildMemoryOfHomeScenario(
    GameDifficulty difficulty,
    ContentPack pack,
    CaregiverProfile? caregiver,
  ) {
    // 1. Pool of familiar candidate items from pack and caregiver
    final pool = List<GameItem>.from(pack.items);

    // Common household items to ensure sufficient distinct objects for all difficulties
    final extraHomeItems = const [
      GameItem(id: 'home_tea', title: 'Tea Cup', subtitle: 'Warm cup of tea', category: 'home'),
      GameItem(id: 'home_umbrella', title: 'Umbrella', subtitle: 'Rain umbrella', category: 'home'),
      GameItem(id: 'home_basket', title: 'Basket', subtitle: 'Woven cane basket', category: 'home'),
      GameItem(id: 'home_radio', title: 'Radio', subtitle: 'Classic radio', category: 'home'),
      GameItem(id: 'home_glasses', title: 'Glasses', subtitle: 'Reading spectacles', category: 'home'),
      GameItem(id: 'home_stick', title: 'Walking Stick', subtitle: 'Wooden walking cane', category: 'home'),
    ];

    for (final extra in extraHomeItems) {
      if (!pool.any((item) => item.id == extra.id || item.title.toLowerCase() == extra.title.toLowerCase())) {
        pool.add(extra);
      }
    }

    // Determine number of objects to remember based on difficulty:
    // Easy: 3 objects | Medium: 4 objects | Hard: 5 objects
    final int objectCount = difficulty == GameDifficulty.easy
        ? 3
        : (difficulty == GameDifficulty.medium ? 4 : 5);

    final initialItems = pool.take(objectCount).toList();

    // 1 object is chosen as the "missing" target
    final target = initialItems.first;

    // Distractor pool from items not in the initial set
    final distractorPool = pool.skip(objectCount).toList();
    final int distractorCount = difficulty == GameDifficulty.easy ? 2 : 3;
    final distractors = distractorPool.take(distractorCount).toList();

    return GameScenario(
      id: 'moh_${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'memory_of_home',
      difficulty: difficulty,
      promptText: 'Which object is missing?',
      targets: [target],
      distractors: [
        ...initialItems.skip(1),
        ...distractors,
      ],
      orderedTargetIds: initialItems.map((i) => i.id).toList(),
      hintText: 'Look at what was on the table earlier. Remember ${target.title}.',
    );
  }

  GameScenario _buildPatternPathScenario(GameDifficulty difficulty) {
    const circle = GameItem(
      id: 'shape_circle',
      title: 'Circle',
      subtitle: 'Blue Circle',
      category: 'shape',
    );
    const square = GameItem(
      id: 'shape_square',
      title: 'Square',
      subtitle: 'Green Square',
      category: 'shape',
    );
    const triangle = GameItem(
      id: 'shape_triangle',
      title: 'Triangle',
      subtitle: 'Amber Triangle',
      category: 'shape',
    );
    const star = GameItem(
      id: 'shape_star',
      title: 'Star',
      subtitle: 'Purple Star',
      category: 'shape',
    );

    List<GameItem> sequence;
    GameItem target;
    List<GameItem> distractors;

    switch (difficulty) {
      case GameDifficulty.easy:
        // A B A B -> [A]
        sequence = [circle, square, circle, square];
        target = circle;
        distractors = [square];
        break;
      case GameDifficulty.medium:
        // A B C A B -> [C]
        sequence = [circle, square, triangle, circle, square];
        target = triangle;
        distractors = [circle, square];
        break;
      case GameDifficulty.hard:
        // A B A C A B -> [A]
        sequence = [circle, square, circle, star, circle, square];
        target = circle;
        distractors = [square, triangle, star];
        break;
    }

    return GameScenario(
      id: 'pp_${DateTime.now().millisecondsSinceEpoch}',
      gameId: 'pattern_path',
      difficulty: difficulty,
      promptText: 'Which shape comes next in the pattern?',
      targets: [target],
      distractors: distractors,
      orderedTargetIds: sequence.map((i) => i.id).toList(),
      hintText: 'Notice how the shapes repeat in order.',
    );
  }

  // -------------------------------------------------------------
  // Embedded Fallback Packs for Zero-Asset Resilience
  // -------------------------------------------------------------

  ContentPack _getEmbeddedFallbackPack(String regionId) {
    if (regionId == 'generic') {
      return const ContentPack(
        regionId: 'generic',
        regionName: 'Familiar Home Items',
        languageCode: 'en',
        items: [
          GameItem(id: 'gen_tea', title: 'Tea Cup', subtitle: 'Warm cup of tea', category: 'home'),
          GameItem(id: 'gen_glasses', title: 'Reading Glasses', subtitle: 'Glasses for reading news', category: 'home'),
          GameItem(id: 'gen_radio', title: 'Classic Radio', subtitle: 'Songs and evening news', category: 'home'),
          GameItem(id: 'gen_stick', title: 'Walking Stick', subtitle: 'Helpful companion for walks', category: 'home'),
          GameItem(id: 'gen_umbrella', title: 'Umbrella', subtitle: 'Rain umbrella', category: 'home'),
          GameItem(id: 'gen_basket', title: 'Cane Basket', subtitle: 'Woven home basket', category: 'home'),
        ],
        routineSteps: [
          RoutineStepItem(id: 'gen_1', stepOrder: 1, title: 'Morning Cup of Tea', iconName: 'free_breakfast'),
          RoutineStepItem(id: 'gen_2', stepOrder: 2, title: 'Read the Morning Paper', iconName: 'newspaper'),
          RoutineStepItem(id: 'gen_3', stepOrder: 3, title: 'Walk in the Garden', iconName: 'yard'),
        ],
      );
    }

    if (regionId == 'meghalaya') {
      return const ContentPack(
        regionId: 'meghalaya',
        regionName: 'Meghalaya',
        languageCode: 'kha',
        items: [
          GameItem(id: 'ml_orange', title: 'Khasi Orange', subtitle: 'Sweet mountain citrus', category: 'fruit'),
          GameItem(id: 'ml_basket', title: 'Khoh (Cane Basket)', subtitle: 'Woven bamboo basket', category: 'craft'),
          GameItem(id: 'ml_turmeric', title: 'Lakadong Turmeric', subtitle: 'Golden turmeric root', category: 'spice'),
          GameItem(id: 'ml_bamboo', title: 'Bamboo Shoots', subtitle: 'Tender fresh shoots', category: 'vegetable'),
        ],
        routineSteps: [
          RoutineStepItem(id: 'ml_1', stepOrder: 1, title: 'Morning Sha Shiah (Red Tea)', iconName: 'free_breakfast'),
          RoutineStepItem(id: 'ml_2', stepOrder: 2, title: 'Tending the Garden', iconName: 'yard'),
          RoutineStepItem(id: 'ml_3', stepOrder: 3, title: 'Neighborhood Market Walk', iconName: 'storefront'),
        ],
      );
    }

    // Default Assam Pack
    return const ContentPack(
      regionId: 'assam',
      regionName: 'Assam',
      languageCode: 'as',
      items: [
        GameItem(id: 'as_tea', title: 'Chah (Assam Tea)', subtitle: 'Fresh garden tea leaves', category: 'beverage'),
        GameItem(id: 'as_gamosa', title: 'Gamosa', subtitle: 'Woven towel', category: 'craft'),
        GameItem(id: 'as_pitha', title: 'Til Pitha', subtitle: 'Crisp sesame rice rolls', category: 'snack'),
        GameItem(id: 'as_nemu', title: 'Kaji Nemu (Lemon)', subtitle: 'Aromatic juicy lemon', category: 'fruit'),
        GameItem(id: 'as_dhekia', title: 'Dhekia Xak', subtitle: 'Tender fiddlehead ferns', category: 'vegetable'),
      ],
      routineSteps: [
        RoutineStepItem(id: 'as_1', stepOrder: 1, title: 'Morning Red Tea (Ronga Chah)', iconName: 'free_breakfast'),
        RoutineStepItem(id: 'as_2', stepOrder: 2, title: 'Wash face with fresh water', iconName: 'water_drop'),
        RoutineStepItem(id: 'as_3', stepOrder: 3, title: 'Morning Diya & Prayer', iconName: 'self_improvement'),
        RoutineStepItem(id: 'as_4', stepOrder: 4, title: 'Midday Meal with Rice & Dal', iconName: 'restaurant'),
      ],
    );
  }
}
