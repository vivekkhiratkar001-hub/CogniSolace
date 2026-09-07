/// API Service for COGNISOLACE Flutter Frontend
///
/// Project: AI-Based Cognitive Gaming and Memory Assistance Platform
///          for Elderly Dementia Patients in North Eastern Region (NER)
///
/// Role: Member 1 - Flutter Frontend Developer
///
/// Purpose:
/// - Provides a clean, centralized abstraction layer for all API communication.
/// - All methods currently return safe dummy/mock data so the UI works immediately.
/// - Member 5 (FastAPI + SQLite backend) will provide the real endpoint URLs.
/// - Member 1 will swap the dummy returns with actual HTTP calls once the
///   backend is ready - no other files need to change.
///
/// IMPORTANT:
/// - No real HTTP requests are made here yet.
/// - No backend, database, ML, LLM, or RAG code belongs in this file.
/// - Change [baseUrl] to point to the real server when Member 5 is ready.

// ─────────────────────────────────────────────────────────────────────────────
// API RESPONSE WRAPPER
// A simple container that wraps every API result.
// [success] tells the UI whether the call worked.
// [data]    holds the actual result when successful.
// [error]   holds a human-readable message when something goes wrong.
// ─────────────────────────────────────────────────────────────────────────────
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  const ApiResponse.ok(this.data)
      : success = true,
        error = null;

  const ApiResponse.fail(this.error)
      : success = false,
        data = null;

  @override
  String toString() =>
      success ? 'ApiResponse.ok($data)' : 'ApiResponse.fail($error)';
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class ApiService {
  // -- Singleton pattern ──────────────────────────────────────────────────────
  // Only one instance of ApiService is created for the whole app.
  // Usage anywhere in the app:  ApiService().getUserProgress()
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // -- Configurable Base URL ─────────────────────────────────────────────────
  // Change this single line when Member 5s FastAPI server is ready.
  //
  // Common values:
  //   Local dev (Android emulator) : 'http://10.0.2.2:8000/api/v1'
  //   Local dev (physical device)  : 'http://192.168.x.x:8000/api/v1'
  //   Production server            : 'https://cognisolace.example.com/api/v1'
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // -- Simulated network delay ───────────────────────────────────────────────
  // Mimics a real server round-trip so the UI behaves realistically.
  // Remove / lower this when real HTTP calls are added.
  static const Duration _fakeDelay = Duration(milliseconds: 500);

  // ══════════════════════════════════════════════════════════════════════════
  // METHOD 1 -- Get User Progress
  // Backend endpoint (future): GET /api/v1/progress/{userId}
  //
  // Returns a summary of the elderly users cognitive activity this week.
  // Member 5 will store this data in SQLite and expose it via FastAPI.
  // ══════════════════════════════════════════════════════════════════════════
  Future<ApiResponse<Map<String, dynamic>>> getUserProgress() async {
    try {
      // Simulated delay (replace with real HTTP GET when backend is ready)
      await Future.delayed(_fakeDelay);

      // Dummy data - will be replaced by actual JSON from Member 5s API
      final Map<String, dynamic> dummyProgress = {
        'gamesPlayed': 12,
        'averageScore': '75%',
        'memoryPerformance': '80%',
        'todayActivity': 'Completed',
        'streakDays': 4,
        'lastUpdated': '2026-09-06',
        // Member 4 & 5 APIs will replace this with real computed values later
      };

      return ApiResponse.ok(dummyProgress);
    } catch (e) {
      // If anything unexpected happens, return a safe error response
      return const ApiResponse.fail(
        'Could not load your progress right now. Please try again.',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METHOD 2 -- Get Reminders
  // Backend endpoint (future): GET /api/v1/reminders/{userId}
  //
  // Returns the elderly users daily routine and medicine reminders.
  // Member 5 will manage reminders in the SQLite database.
  // ══════════════════════════════════════════════════════════════════════════
  Future<ApiResponse<List<Map<String, dynamic>>>> getReminders() async {
    try {
      await Future.delayed(_fakeDelay);

      // Dummy data - will be replaced by the users actual saved reminders
      final List<Map<String, dynamic>> dummyReminders = [
        {
          'id': 'rem_1',
          'emoji': '🌅',
          'time': '8:00 AM',
          'title': 'Morning Exercise',
          'category': 'Exercise',
          'isCompleted': false,
        },
        {
          'id': 'rem_2',
          'emoji': '💊',
          'time': '9:00 AM',
          'title': 'Medicine Reminder',
          'category': 'Medicine',
          'isCompleted': true,
        },
        {
          'id': 'rem_3',
          'emoji': '🍽️',
          'time': '1:00 PM',
          'title': 'Lunch Time',
          'category': 'Meal',
          'isCompleted': false,
        },
        {
          'id': 'rem_4',
          'emoji': '🚶',
          'time': '5:00 PM',
          'title': 'Evening Walk',
          'category': 'Exercise',
          'isCompleted': false,
        },
        {
          'id': 'rem_5',
          'emoji': '🌙',
          'time': '9:00 PM',
          'title': 'Sleep Reminder',
          'category': 'Rest',
          'isCompleted': false,
        },
        // Member 5 FastAPI endpoint will return real reminder records here
      ];

      return ApiResponse.ok(dummyReminders);
    } catch (e) {
      return const ApiResponse.fail(
        'Could not load your reminders right now. Please try again.',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METHOD 3 -- Send Assistant Message
  // Backend endpoint (future): POST /api/v1/assistant/chat
  //
  // Sends the users typed/spoken message to the AI assistant.
  // Member 4 (LLM/RAG pipeline) and Member 5 (FastAPI) will handle the
  // real AI response. For now, a safe dummy reply is returned.
  //
  // Parameters:
  //   [message] - The text the elderly user typed or dictated.
  //   [userId]  - Optional: identifies the patient for personalized replies.
  // ══════════════════════════════════════════════════════════════════════════
  Future<ApiResponse<String>> sendAssistantMessage(
    String message, {
    String userId = 'user_001',
  }) async {
    try {
      // Guard: do not send empty messages
      if (message.trim().isEmpty) {
        return const ApiResponse.fail('Please type a message first.');
      }

      await Future.delayed(_fakeDelay);

      // Dummy keyword-based responses (Member 4 LLM/RAG will replace this)
      final String lowerMessage = message.toLowerCase();
      final String dummyReply;

      if (lowerMessage.contains('medicine') || lowerMessage.contains('pill')) {
        dummyReply =
            'Yes! Your morning medicine was scheduled at 9:00 AM with warm water.';
      } else if (lowerMessage.contains('today') ||
          lowerMessage.contains('date') ||
          lowerMessage.contains('time')) {
        dummyReply =
            'Today is a peaceful day in the North Eastern Region. Your schedule is all on track!';
      } else if (lowerMessage.contains('family') ||
          lowerMessage.contains('who') ||
          lowerMessage.contains('people')) {
        dummyReply =
            'Your family loves you very much and is always thinking of you. You are not alone.';
      } else if (lowerMessage.contains('game') ||
          lowerMessage.contains('play')) {
        dummyReply =
            'You can tap "Play Game" on the home screen to start a fun memory game!';
      } else {
        dummyReply =
            'I heard you clearly. I am right here with you. Take all the time you need. 🌸';
      }

      // Future: POST $baseUrl/assistant/chat
      // Body: { "userId": userId, "message": message }

      return ApiResponse.ok(dummyReply);
    } catch (e) {
      return const ApiResponse.fail(
        'The assistant is resting right now. Please try again in a moment.',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METHOD 4 -- Send Game Result
  // Backend endpoint (future): POST /api/v1/games/result
  //
  // Sends the players game score to the backend for storage and analysis.
  // Member 2 (game logic) will call this after each session ends.
  // Member 5 will save the result in SQLite; Member 4s AI uses it for
  // adaptive difficulty recommendations.
  //
  // Parameters:
  //   [gameId]     - Identifier of the game played (e.g. 'memory_matching').
  //   [score]      - Points scored in this session.
  //   [difficulty] - Difficulty level played (e.g. 'Easy', 'Medium').
  //   [userId]     - The patients identifier.
  // ══════════════════════════════════════════════════════════════════════════
  Future<ApiResponse<Map<String, dynamic>>> sendGameResult({
    required String gameId,
    required int score,
    String difficulty = 'Easy',
    String userId = 'user_001',
  }) async {
    try {
      // Guard: score should not be negative
      if (score < 0) {
        return const ApiResponse.fail('Game score cannot be negative.');
      }

      await Future.delayed(_fakeDelay);

      // Dummy acknowledgement (Member 5 FastAPI will return real DB record)
      final Map<String, dynamic> dummyAck = {
        'status': 'saved',
        'gameId': gameId,
        'score': score,
        'difficulty': difficulty,
        'userId': userId,
        'savedAt': DateTime.now().toIso8601String(),
        'message': 'Well done! Your score has been saved successfully. 🎉',
        // Future: POST $baseUrl/games/result
        // Body: { "userId": userId, "gameId": gameId,
        //         "score": score, "difficulty": difficulty }
      };

      return ApiResponse.ok(dummyAck);
    } catch (e) {
      return const ApiResponse.fail(
        'Could not save your game result. Please try again.',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METHOD 5 -- Get Activity Recommendation
  // Backend endpoint (future): GET /api/v1/recommendations/{userId}
  //
  // Fetches a personalized activity suggestion for the elderly user.
  // Member 4s adaptive AI model analyzes past performance and generates
  // the recommendation; Member 5 exposes it via FastAPI.
  //
  // Parameters:
  //   [userId] - The patients identifier for personalized suggestions.
  // ══════════════════════════════════════════════════════════════════════════
  Future<ApiResponse<Map<String, dynamic>>> getActivityRecommendation({
    String userId = 'user_001',
  }) async {
    try {
      await Future.delayed(_fakeDelay);

      // Dummy recommendation (Member 4 AI model will generate real ones)
      final Map<String, dynamic> dummyRecommendation = {
        'type': 'game',
        'title': 'Try a Memory Matching Game 🧠',
        'description':
            'You have not played today yet. A short memory game will help '
            'keep your mind active and sharp!',
        'actionLabel': 'Play Now',
        'actionTarget': 'games_screen',
        'difficulty': 'Easy',
        'estimatedMinutes': 5,
        'reason':
            'Based on your weekly activity, a short gentle game is recommended.',
        // Member 4 & 5 APIs will replace this with real AI recommendations later
      };

      return ApiResponse.ok(dummyRecommendation);
    } catch (e) {
      return const ApiResponse.fail(
        'Could not load a recommendation right now. Please try again.',
      );
    }
  }
}
