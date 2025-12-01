import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';

class FavoritesProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Video> _favorites = [];
  bool _isLoaded = false;

  List<Video> get favorites => _favorites;
  bool get isLoaded => _isLoaded;

  // Load favorites from storage
  Future<void> loadFavorites() async {
    if (_isLoaded) return;

    _favorites = await _storageService.loadFavorites();
    _isLoaded = true;
    notifyListeners();
  }

  // Add a favorite
  Future<void> addFavorite(Video video) async {
    if (!_favorites.any((v) => v.id == video.id)) {
      _favorites.insert(0, video); // Add to beginning
      await _storageService.saveFavorites(_favorites);
      notifyListeners();
    }
  }

  // Remove a favorite
  Future<void> removeFavorite(String videoId) async {
    _favorites.removeWhere((v) => v.id == videoId);
    await _storageService.saveFavorites(_favorites);
    notifyListeners();
  }

  // Check if a video is favorited
  bool isFavorited(String videoId) {
    return _favorites.any((v) => v.id == videoId);
  }

  // Toggle favorite
  Future<void> toggleFavorite(Video video) async {
    if (isFavorited(video.id)) {
      await removeFavorite(video.id);
    } else {
      await addFavorite(video);
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    _favorites.clear();
    await _storageService.saveFavorites(_favorites);
    notifyListeners();
  }
}
