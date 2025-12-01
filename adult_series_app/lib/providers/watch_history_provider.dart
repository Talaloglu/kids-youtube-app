import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';

class WatchHistoryProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Video> _history = [];
  bool _isLoaded = false;

  List<Video> get history => _history;
  bool get isLoaded => _isLoaded;

  // Load watch history from storage
  Future<void> loadHistory() async {
    if (_isLoaded) return;

    _history = await _storageService.loadWatchHistory();
    _isLoaded = true;
    notifyListeners();
  }

  // Add video to watch history
  Future<void> addToHistory(Video video) async {
    // Remove if already exists
    _history.removeWhere((v) => v.id == video.id);

    // Add to beginning
    _history.insert(0, video);

    // Keep only last 100 videos
    if (_history.length > 100) {
      _history = _history.sublist(0, 100);
    }

    await _storageService.saveWatchHistory(_history);
    notifyListeners();
  }

  // Remove from history
  Future<void> removeFromHistory(String videoId) async {
    _history.removeWhere((v) => v.id == videoId);
    await _storageService.saveWatchHistory(_history);
    notifyListeners();
  }

  // Clear all history
  Future<void> clearHistory() async {
    _history.clear();
    await _storageService.saveWatchHistory(_history);
    notifyListeners();
  }

  // Check if video is in history
  bool isInHistory(String videoId) {
    return _history.any((v) => v.id == videoId);
  }
}
