import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';

class HistoryProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Video> _history = [];
  bool _isLoaded = false;

  List<Video> get history => _history;
  bool get isLoaded => _isLoaded;

  // Load history from storage
  Future<void> loadHistory() async {
    if (_isLoaded) return;

    _history = await _storageService.loadHistory();
    _isLoaded = true;
    notifyListeners();
  }

  // Add video to history
  Future<void> addToHistory(Video video) async {
    // Remove if already exists to move it to the top
    _history.removeWhere((v) => v.id == video.id);

    // Add to beginning of list
    _history.insert(0, video);

    // Limit history size (e.g., keep last 50 videos)
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }

    await _storageService.saveHistory(_history);
    notifyListeners();
  }

  // Clear history
  Future<void> clearHistory() async {
    _history.clear();
    await _storageService.saveHistory(_history);
    notifyListeners();
  }
}
