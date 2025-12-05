import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../models/category_model.dart' as cat;
import '../services/youtube_service.dart';
import '../services/storage_service.dart';

class VideoProvider with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final StorageService _storageService = StorageService();

  List<Video> _videos = []; // For search results or specific category view
  final Map<String, List<Video>> _categoryVideos =
      {}; // For home screen sections
  bool _isLoading = false;
  String? _nextPageToken;
  cat.Category? _selectedCategory;
  String _searchQuery = '';

  List<Video> get videos => _videos;
  Map<String, List<Video>> get categoryVideos => _categoryVideos;
  bool get isLoading => _isLoading;
  bool get hasMore => _nextPageToken != null;
  cat.Category? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Load initial videos (Home Screen content)
  Future<void> loadInitialVideos() async {
    _isLoading = true;
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();

    try {
      // 1. Load from cache first for instant UI
      await Future.wait(
        cat.kidsCategories.map((category) async {
          final cachedVideos = await _storageService.loadCategoryVideos(
            category.id,
          );
          if (cachedVideos.isNotEmpty) {
            _categoryVideos[category.id] = cachedVideos;
          }
        }),
      );

      // If we have cached data, stop loading indicator but continue fetching in background
      if (_categoryVideos.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
      }

      // 2. Fetch fresh data from API
      await Future.wait(
        cat.kidsCategories.map((category) async {
          try {
            final result = await _youtubeService.getVideosByCategory(
              category.id,
            );
            final videos = result['videos'] as List<Video>;

            if (videos.isNotEmpty) {
              _categoryVideos[category.id] = videos;
              // 3. Update cache
              await _storageService.saveCategoryVideos(category.id, videos);
            }
          } catch (e) {
            print('Error loading videos for category ${category.name}: $e');
          }
        }),
      );
    } catch (e) {
      print('Error loading initial videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load videos by category (View All / Filter)
  Future<void> loadVideosByCategory(cat.Category category) async {
    _selectedCategory = category;
    _searchQuery = '';
    _isLoading = true;
    _videos = [];
    _nextPageToken = null;
    notifyListeners();

    try {
      final result = await _youtubeService.getVideosByCategory(category.id);
      _videos = result['videos'] as List<Video>;
      _nextPageToken = result['nextPageToken'];
    } catch (e) {
      print('Error loading category videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search videos
  Future<void> searchVideos(String query) async {
    _searchQuery = query;
    _selectedCategory = null;
    _isLoading = true;
    _videos = [];
    _nextPageToken = null;
    notifyListeners();

    try {
      final result = await _youtubeService.searchVideos(query);
      _videos = result['videos'] as List<Video>;
      _nextPageToken = result['nextPageToken'];
    } catch (e) {
      print('Error searching videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more videos (pagination for search or specific category)
  Future<void> loadMoreVideos() async {
    if (_isLoading || _nextPageToken == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> result;

      if (_selectedCategory != null) {
        result = await _youtubeService.getVideosByCategory(
          _selectedCategory!.id,
          pageToken: _nextPageToken,
        );
      } else if (_searchQuery.isNotEmpty) {
        result = await _youtubeService.searchVideos(
          _searchQuery,
          pageToken: _nextPageToken,
        );
      } else {
        // Should not happen in new layout, but fallback
        return;
      }

      final newVideos = result['videos'] as List<Video>;
      _videos.addAll(newVideos);
      _nextPageToken = result['nextPageToken'];
    } catch (e) {
      print('Error loading more videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear category filter
  void clearCategoryFilter() {
    _selectedCategory = null;
    // Don't reload everything, just reset view state
    notifyListeners();
  }

  // Refresh videos
  Future<void> refresh() async {
    if (_selectedCategory != null) {
      await loadVideosByCategory(_selectedCategory!);
    } else if (_searchQuery.isNotEmpty) {
      await searchVideos(_searchQuery);
    } else {
      await loadInitialVideos();
    }
  }
}
