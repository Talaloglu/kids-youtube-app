import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../models/category_model.dart' as cat;
import '../services/youtube_service.dart';

class VideoProvider with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();

  List<Video> _videos = [];
  final Map<String, List<Video>> _categoryVideos = {};
  bool _isLoading = false;
  String? _nextPageToken;
  cat.Category? _selectedCategory;
  String _searchQuery = '';
  String _currentTab = 'series'; // series, shorts, all

  List<Video> get videos => _videos;
  Map<String, List<Video>> get categoryVideos => _categoryVideos;
  bool get isLoading => _isLoading;
  bool get hasMore => _nextPageToken != null;
  cat.Category? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get currentTab => _currentTab;

  // Set current tab
  void setTab(String tab) {
    _currentTab = tab;
    notifyListeners();
  }

  // Load initial content for home screen
  Future<void> loadInitialContent() async {
    _isLoading = true;
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();

    try {
      // Load content for each category based on current tab
      await Future.wait(
        cat.adultCategories.map((category) async {
          try {
            final result = await _youtubeService.getVideosByCategory(
              category.id,
              shortsOnly: _currentTab == 'shorts',
            );
            _categoryVideos[category.id] = result['videos'] as List<Video>;
          } catch (e) {
            print('Error loading videos for category ${category.name}: $e');
          }
        }),
      );
    } catch (e) {
      print('Error loading initial content: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load videos by category
  Future<void> loadVideosByCategory(cat.Category category) async {
    _selectedCategory = category;
    _searchQuery = '';
    _isLoading = true;
    _videos = [];
    _nextPageToken = null;
    notifyListeners();

    try {
      final result = await _youtubeService.getVideosByCategory(
        category.id,
        shortsOnly: _currentTab == 'shorts',
      );
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
      Map<String, dynamic> result;
      if (_currentTab == 'series') {
        result = await _youtubeService.searchSeries(query);
      } else if (_currentTab == 'shorts') {
        result = await _youtubeService.searchShorts(query);
      } else {
        result = await _youtubeService.searchVideos(query);
      }
      _videos = result['videos'] as List<Video>;
      _nextPageToken = result['nextPageToken'];
    } catch (e) {
      print('Error searching videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more videos (pagination)
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
          shortsOnly: _currentTab == 'shorts',
        );
      } else if (_searchQuery.isNotEmpty) {
        if (_currentTab == 'series') {
          result = await _youtubeService.searchSeries(
            _searchQuery,
            pageToken: _nextPageToken,
          );
        } else if (_currentTab == 'shorts') {
          result = await _youtubeService.searchShorts(
            _searchQuery,
            pageToken: _nextPageToken,
          );
        } else {
          result = await _youtubeService.searchVideos(
            _searchQuery,
            pageToken: _nextPageToken,
          );
        }
      } else {
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
    notifyListeners();
  }

  // Refresh content
  Future<void> refresh() async {
    if (_selectedCategory != null) {
      await loadVideosByCategory(_selectedCategory!);
    } else if (_searchQuery.isNotEmpty) {
      await searchVideos(_searchQuery);
    } else {
      await loadInitialContent();
    }
  }
}
