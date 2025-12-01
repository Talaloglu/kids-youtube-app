import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';

class StorageService {
  static const String _bookmarksKey = 'kids_youtube_bookmarks';
  static const String _themeKey = 'kids_youtube_theme';
  static const String _historyKey = 'kids_youtube_history';
  static const String _categoriesKey = 'kids_youtube_categories';
  static const String _categoryVideosKeyPrefix = 'kids_youtube_cat_videos_';
  static const String _searchHistoryKey = 'kids_youtube_search_history';

  // Save bookmarks
  Future<void> saveBookmarks(List<Video> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = bookmarks.map((v) => v.toJson()).toList();
      await prefs.setString(_bookmarksKey, json.encode(bookmarksJson));
    } catch (e) {
      print('Error saving bookmarks: $e');
    }
  }

  // Load bookmarks
  Future<List<Video>> loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksString = prefs.getString(_bookmarksKey);

      if (bookmarksString != null) {
        final List<dynamic> bookmarksJson = json.decode(bookmarksString);
        return bookmarksJson.map((json) => Video.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
    }

    return [];
  }

  // Save theme preference (true = dark, false = light)
  Future<void> saveThemePreference(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Load theme preference
  Future<bool> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_themeKey) ?? false; // Default to light theme
    } catch (e) {
      print('Error loading theme: $e');
      return false;
    }
  }

  // Save watch history
  Future<void> saveHistory(List<Video> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = history.map((v) => v.toJson()).toList();
      await prefs.setString(_historyKey, json.encode(historyJson));
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  // Load watch history
  Future<List<Video>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_historyKey);

      if (historyString != null) {
        final List<dynamic> historyJson = json.decode(historyString);
        return historyJson.map((json) => Video.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading history: $e');
    }

    return [];
  }

  // Save search history
  Future<void> saveSearchHistory(List<String> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  // Load search history
  Future<List<String>> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      print('Error loading search history: $e');
      return [];
    }
  }

  // Save category videos (Caching)
  Future<void> saveCategoryVideos(String categoryId, List<Video> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = videos.map((v) => v.toJson()).toList();
      await prefs.setString(
        '$_categoryVideosKeyPrefix$categoryId',
        json.encode(videosJson),
      );
    } catch (e) {
      print('Error saving category videos cache: $e');
    }
  }

  // Load category videos (Caching)
  Future<List<Video>> loadCategoryVideos(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosString = prefs.getString(
        '$_categoryVideosKeyPrefix$categoryId',
      );

      if (videosString != null) {
        final List<dynamic> videosJson = json.decode(videosString);
        return videosJson.map((json) => Video.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading category videos cache: $e');
    }
    return [];
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarksKey);
      await prefs.remove(_historyKey);
      await prefs.remove(_searchHistoryKey);
      // We don't clear cache here usually, but maybe we should?
      // For now let's keep cache as it improves performance
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}
