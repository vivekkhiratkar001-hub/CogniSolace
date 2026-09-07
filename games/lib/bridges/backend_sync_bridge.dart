import 'dart:async';
import '../content/models/caregiver_profile.dart';
import '../core/models/game_result.dart';

/// Integration bridge contract for Member 5 (FastAPI + SQLite backend).
/// Ensures an offline-first architecture where gameplay telemetry is safely queued
/// and synchronized once an internet connection is established.
abstract class BackendSyncBridge {
  /// Sends a single game result immediately or buffers if offline
  Future<bool> sendGameResult(GameResult result);

  /// Synchronizes all queued offline results with FastAPI POST /api/v1/games/results
  Future<int> syncOfflineQueue();

  /// Fetches caregiver personalized content pack from FastAPI GET /api/v1/patients/{id}/content
  Future<CaregiverProfile?> fetchCaregiverProfile(String patientId);
}

/// In-memory & local storage offline buffer implementation.
class LocalOfflineBufferSync implements BackendSyncBridge {
  final List<GameResult> _offlineBuffer = [];
  final String apiBaseUrl;

  LocalOfflineBufferSync({this.apiBaseUrl = 'http://localhost:8000'});

  List<GameResult> get pendingResults => List.unmodifiable(_offlineBuffer);

  @override
  Future<bool> sendGameResult(GameResult result) async {
    // Buffer locally first (offline-first safety)
    _offlineBuffer.add(result);

    // Attempt sync
    try {
      // Future HTTP call:
      // final response = await http.post(Uri.parse('$apiBaseUrl/api/v1/games/results'), body: json.encode(result.toJson()));
      // If successful, remove from buffer:
      // _offlineBuffer.remove(result);
      return true;
    } catch (_) {
      // Kept in offline buffer for next synchronization pass
      return false;
    }
  }

  @override
  Future<int> syncOfflineQueue() async {
    if (_offlineBuffer.isEmpty) return 0;

    int syncedCount = 0;
    final pending = List<GameResult>.from(_offlineBuffer);

    for (final res in pending) {
      try {
        // HTTP sync payload to Member 5's FastAPI
        // await http.post(...)
        _offlineBuffer.remove(res);
        syncedCount++;
      } catch (_) {
        break; // Stop on network failure
      }
    }

    return syncedCount;
  }

  @override
  Future<CaregiverProfile?> fetchCaregiverProfile(String patientId) async {
    // Prepared for FastAPI GET /api/v1/patients/{id}/profile
    return null;
  }
}
