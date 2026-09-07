import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cognisolace_games/games.dart';
import 'package:cognisolace_games/main.dart';

void main() {
  testWidgets('CogniSolace Games Catalog Smoke Test - All 5 Games and Difficulty Options Present', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CogniSolaceGamesTestApp(key: Key('app_smoke')));
    await tester.pumpAndSettle();

    expect(find.text('Cognitive Games'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(GameDifficulty.medium.displayName, 'Medium');
    expect(GameDifficulty.hard.displayName, 'Hard');
    expect(find.text('Know My People'), findsOneWidget);
    expect(find.text('Memory of Home'), findsOneWidget);
    expect(find.text('Daily Market'), findsOneWidget);
    expect(find.text('My Day'), findsOneWidget);
    expect(find.text('Pattern Path'), findsOneWidget);
  });

  testWidgets('Know My People - Multi-round progress, non-revealing hint, retry feedback, and round advancement', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CogniSolaceGamesTestApp(key: Key('app_know_my_people')));
    await tester.pumpAndSettle();

    // 1. Launch Know My People
    final cardFinder = find.text('Know My People');
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(KnowMyPeopleView), findsOneWidget);
    expect(find.text('Listen Instructions'), findsOneWidget);

    // Verify dementia-friendly progress indicator and hint button
    expect(find.text('Question 1 of 10'), findsNWidgets(2));
    final hintBtnFinder = find.byTooltip('Need a hint?');
    expect(hintBtnFinder, findsOneWidget);

    // Inactivity timer test: pump 15 seconds, verify hint does NOT show automatically
    await tester.pump(const Duration(seconds: 15));
    expect(find.textContaining('Hint:'), findsNothing);

    // Manual hint button tap: non-revealing hint appears
    await tester.tap(hintBtnFinder);
    await tester.pump();
    expect(find.text('Hint: This person is someone from your family.'), findsOneWidget);

    // 2. Select wrong answer (Sujata - Daughter)
    final wrongFinder = find.text('Sujata (Daughter (Suwali))');
    await tester.ensureVisible(wrongFinder);
    await tester.tap(wrongFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify retry feedback appears and success overlay is NOT shown
    expect(find.text("That's not quite right. Try again."), findsOneWidget);
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsNothing);

    // 3. Select correct answer (Raju - Son)
    final correctFinder = find.text('Raju (Son (Lara))');
    await tester.ensureVisible(correctFinder);
    await tester.tap(correctFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify positive feedback overlay appears
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);

    // Tap Continue -> advances to Question 2 of 10
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Question 2 of 10'), findsNWidgets(2));
    expect(find.byType(KnowMyPeopleView), findsOneWidget);
  });

  testWidgets('Know My People - Multi-round session completion shows summary screen and triggers onFinish', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = LocalContentRepository();
    final scenario = await repo.generateScenario(
      gameId: 'know_my_people',
      difficulty: GameDifficulty.easy,
      regionId: 'NER_AS_01',
    );

    bool finished = false;
    GameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: KnowMyPeopleView(
          patientId: 'P001',
          scenario: scenario,
          sessionConfig: const GameSessionConfig(questionCount: 2),
          onFinish: () => finished = true,
          onResult: (res) => result = res,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Round 1: Target Raju
    expect(find.text('Question 1 of 2'), findsNWidgets(2));
    await tester.tap(find.text('Raju (Son (Lara))'));
    await tester.pumpAndSettle();
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Round 2: Sujata
    expect(find.text('Question 2 of 2'), findsNWidgets(2));
    await tester.tap(find.text('Sujata (Daughter (Suwali))'));
    await tester.pumpAndSettle();
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Session Completion Summary Screen
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('You completed 2 questions.'), findsOneWidget);
    expect(find.text('Correct Answers'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('Total Attempts'), findsOneWidget);
    expect(find.text('Hints Used'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Back to Menu'), findsOneWidget);

    // Verify telemetry result captured
    expect(result, isNotNull);
    final rounds = result!.metadata['rounds'] as List<dynamic>;
    expect(rounds.length, 2);
    expect(rounds[0]['round_index'], 1);
    expect(rounds[0]['is_solved'], true);
    expect(rounds[1]['round_index'], 2);
    expect(rounds[1]['is_solved'], true);

    // Tap Back to Menu
    await tester.tap(find.text('Back to Menu'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('Memory of Home - Memorize, Recall, Retry feedback, and Round Advancement', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CogniSolaceGamesTestApp(key: Key('app_memory_of_home')));
    await tester.pumpAndSettle();

    // 1. Launch Memory of Home
    final cardFinder = find.text('Memory of Home');
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(MemoryOfHomeView), findsOneWidget);
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(find.text('Memorize what is on the table:'), findsOneWidget);
    expect(find.text("I'm Ready"), findsOneWidget);

    // 2. Tap "I'm Ready" to proceed to recall phase
    final readyFinder = find.text("I'm Ready");
    await tester.ensureVisible(readyFinder);
    await tester.tap(readyFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Which one is missing?'), findsOneWidget);

    // 3. Tap wrong answer ('Gamosa')
    final wrongFinder = find.widgetWithText(DementiaButton, 'Gamosa');
    await tester.ensureVisible(wrongFinder);
    await tester.tap(wrongFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify retry feedback appears and success overlay is NOT shown
    expect(find.text("That's not quite right. Try again."), findsOneWidget);
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsNothing);

    // 4. Tap correct answer ('Chah (Assam Tea)')
    final correctFinder = find.widgetWithText(DementiaButton, 'Chah (Assam Tea)');
    await tester.ensureVisible(correctFinder);
    await tester.tap(correctFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify success overlay appears
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);

    // Dismiss overlay and advance to Question 2 of 5
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Question 2 of 5'), findsOneWidget);
    expect(find.byType(MemoryOfHomeView), findsOneWidget);
  });

  testWidgets('Memory of Home - Multi-round session completion shows SessionResultScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = LocalContentRepository();
    final scenario = await repo.generateScenario(
      gameId: 'memory_of_home',
      difficulty: GameDifficulty.easy,
      regionId: 'NER_AS_01',
    );

    bool finished = false;
    GameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: MemoryOfHomeView(
          patientId: 'P001',
          scenario: scenario,
          sessionConfig: const GameSessionConfig(questionCount: 2),
          onFinish: () => finished = true,
          onResult: (res) => result = res,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Round 1
    expect(find.text('Question 1 of 2'), findsOneWidget);
    await tester.tap(find.text("I'm Ready"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DementiaButton, 'Chah (Assam Tea)'));
    await tester.pumpAndSettle();
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Round 2
    expect(find.text('Question 2 of 2'), findsOneWidget);
    await tester.tap(find.text("I'm Ready"));
    await tester.pumpAndSettle();
    // In round 2, pick the missing item option
    final buttonCount = find.byType(DementiaButton).evaluate().length;
    for (int b = 0; b < buttonCount; b++) {
      if (find.text('Wonderful! (Bhal Hoise!)').evaluate().isNotEmpty) break;
      await tester.tap(find.byType(DementiaButton).at(b));
      await tester.pumpAndSettle();
    }
    if (find.text('Wonderful! (Bhal Hoise!)').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    // Session completion screen
    expect(find.byType(SessionResultScreen), findsOneWidget);
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('You completed 2 questions.'), findsOneWidget);
    expect(find.text('Back to Menu'), findsOneWidget);

    expect(result, isNotNull);
    final rounds = result!.metadata['rounds'] as List<dynamic>;
    expect(rounds.length, 2);

    await tester.tap(find.text('Back to Menu'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('Daily Market - Multi-round session, item collection, and SessionResultScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = LocalContentRepository();
    final scenario = await repo.generateScenario(
      gameId: 'daily_market',
      difficulty: GameDifficulty.easy,
      regionId: 'NER_AS_01',
    );

    bool finished = false;
    GameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: DailyMarketView(
          patientId: 'P001',
          scenario: scenario,
          sessionConfig: const GameSessionConfig(questionCount: 2),
          onFinish: () => finished = true,
          onResult: (res) => result = res,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Round 1
    expect(find.text('Question 1 of 2'), findsOneWidget);
    final target1 = scenario.targets.first.title;
    final targetFinder = find.text(target1);
    await tester.ensureVisible(targetFinder);
    await tester.tap(targetFinder);
    await tester.pumpAndSettle();
    expect(find.text('Shopping Done! (Bahut Bhal!)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Round 2
    expect(find.text('Question 2 of 2'), findsOneWidget);
    // Tap available market cards
    final cards = find.byType(GestureDetector);
    expect(cards, findsWidgets);
    for (int i = 0; i < cards.evaluate().length; i++) {
      await tester.tap(cards.at(i), warnIfMissed: false);
      await tester.pumpAndSettle();
      if (find.text('Shopping Done! (Bahut Bhal!)').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Shopping Done! (Bahut Bhal!)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Session completion screen
    expect(find.byType(SessionResultScreen), findsOneWidget);
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('Back to Menu'), findsOneWidget);

    expect(result, isNotNull);
    final rounds = result!.metadata['rounds'] as List<dynamic>;
    expect(rounds.length, 2);

    await tester.tap(find.text('Back to Menu'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('My Day - Multi-round routine sequencing, retry feedback, and SessionResultScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = LocalContentRepository();
    final scenario = await repo.generateScenario(
      gameId: 'my_day',
      difficulty: GameDifficulty.easy,
      regionId: 'NER_AS_01',
    );

    bool finished = false;
    GameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: MyDayView(
          patientId: 'P001',
          scenario: scenario,
          sessionConfig: const GameSessionConfig(questionCount: 2),
          onFinish: () => finished = true,
          onResult: (res) => result = res,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Round 1
    expect(find.text('Question 1 of 2'), findsOneWidget);
    final step1 = scenario.targets[0].title;
    final step2 = scenario.targets[1].title;

    // Tap step 2 first (wrong) -> retry feedback
    await tester.tap(find.text(step2));
    await tester.pumpAndSettle();
    expect(find.text("That's not quite right. Try again."), findsOneWidget);

    // Tap step 1 (correct)
    await tester.tap(find.text(step1));
    await tester.pumpAndSettle();
    expect(find.text("That's not quite right. Try again."), findsNothing);

    // Tap step 2 (correct)
    await tester.tap(find.text(step2));
    await tester.pumpAndSettle();
    expect(find.text('Great Routine Recall!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Round 2
    expect(find.text('Question 2 of 2'), findsOneWidget);
    // Tap available routine cards until sequence is complete
    while (find.text('Great Routine Recall!').evaluate().isEmpty) {
      final inkwells = find.byType(InkWell);
      final count = inkwells.evaluate().length;
      if (count == 0) break;
      bool advanced = false;
      for (int k = 0; k < count; k++) {
        await tester.tap(find.byType(InkWell).at(k));
        await tester.pumpAndSettle();
        if (find.byType(InkWell).evaluate().length < count ||
            find.text('Great Routine Recall!').evaluate().isNotEmpty) {
          advanced = true;
          break;
        }
      }
      if (!advanced) break;
    }
    expect(find.text('Great Routine Recall!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Session completion screen
    expect(find.byType(SessionResultScreen), findsOneWidget);
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('Back to Menu'), findsOneWidget);

    expect(result, isNotNull);
    final rounds = result!.metadata['rounds'] as List<dynamic>;
    expect(rounds.length, 2);

    await tester.tap(find.text('Back to Menu'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('Pattern Path - Sequence inspect, Wrong answer retry, and Success', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CogniSolaceGamesTestApp(key: Key('app_pattern_path')));
    await tester.pumpAndSettle();

    // 1. Launch Pattern Path
    final cardFinder = find.text('Pattern Path');
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(PatternPathView), findsOneWidget);
    expect(find.text('Listen Instructions'), findsOneWidget);
    expect(find.text('Question 1 of 6'), findsOneWidget);
    expect(find.text('Follow the pattern path:'), findsOneWidget);
    expect(find.text('What Next?'), findsOneWidget);

    // 2. Select wrong answer ('Square')
    final wrongFinder = find.widgetWithText(DementiaButton, 'Square');
    await tester.ensureVisible(wrongFinder);
    await tester.tap(wrongFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify retry feedback appears
    expect(find.text("That's not quite right. Try again."), findsOneWidget);
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsNothing);

    // 3. Select correct answer ('Circle')
    final correctFinder = find.widgetWithText(DementiaButton, 'Circle');
    await tester.ensureVisible(correctFinder);
    await tester.tap(correctFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify success overlay appears
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);

    // Dismiss overlay and advance to Question 2 of 6
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Question 2 of 6'), findsOneWidget);
    expect(find.byType(PatternPathView), findsOneWidget);
  });

  testWidgets('Pattern Path - Multi-round session completion shows SessionResultScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = LocalContentRepository();
    final scenario = await repo.generateScenario(
      gameId: 'pattern_path',
      difficulty: GameDifficulty.easy,
      regionId: 'NER_AS_01',
    );

    bool finished = false;
    GameResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: PatternPathView(
          patientId: 'P001',
          scenario: scenario,
          sessionConfig: const GameSessionConfig(questionCount: 2),
          onFinish: () => finished = true,
          onResult: (res) => result = res,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Round 1: Target Circle
    expect(find.text('Question 1 of 2'), findsOneWidget);
    await tester.tap(find.widgetWithText(DementiaButton, 'Circle'));
    await tester.pumpAndSettle();
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Round 2: Target Square (since Easy rotates shapes)
    expect(find.text('Question 2 of 2'), findsOneWidget);
    await tester.tap(find.widgetWithText(DementiaButton, 'Square'));
    await tester.pumpAndSettle();
    expect(find.text('Wonderful! (Bhal Hoise!)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Session completion screen
    expect(find.byType(SessionResultScreen), findsOneWidget);
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('Back to Menu'), findsOneWidget);

    expect(result, isNotNull);
    final rounds = result!.metadata['rounds'] as List<dynamic>;
    expect(rounds.length, 2);

    await tester.tap(find.text('Back to Menu'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('Back arrow confirmation dialog - Stay and Exit behavior', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CogniSolaceGamesTestApp(key: Key('app_back_arrow')));
    await tester.pumpAndSettle();

    final cardFinder = find.text('Know My People');
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(KnowMyPeopleView), findsOneWidget);

    // Tap back button
    await tester.tap(find.byTooltip('Back to Menu'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('Take a Break?'), findsOneWidget);
    expect(find.text('Stay Here'), findsOneWidget);
    expect(find.text('Exit / Break'), findsOneWidget);

    // Tap 'Stay Here' -> remains in game
    await tester.tap(find.text('Stay Here'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Take a Break?'), findsNothing);
    expect(find.byType(KnowMyPeopleView), findsOneWidget);

    // Tap back button again
    await tester.tap(find.byTooltip('Back to Menu'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap 'Exit / Break' -> returns to Catalog
    await tester.tap(find.text('Exit / Break'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Take a Break?'), findsNothing);
    expect(find.byType(KnowMyPeopleView), findsNothing);
    expect(find.byType(CognitiveGamesCatalog), findsOneWidget);
  });
}
