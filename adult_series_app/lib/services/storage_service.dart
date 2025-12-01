import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _watchHistoryKey = 'watch_history';

  // Save favorites
  Future<void> saveFavorites(List<Video> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = favorites.map((v) => json.encode(v.toJson())).toList();
    await prefs.setStringList(_favoritesKey, jsonList);
  }

  // Load favorites
  Future<List<Video>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoritesKey) ?? [];
    return jsonList
        .map((jsonStr) => Video.fromJson(json.decode(jsonStr)))
        .toList();
  }

  // Save watch history
  Future<void> saveWatchHistory(List<Video> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((v) => json.encode(v.toJson())).toList();
    await prefs.setStringList(_watchHistoryKey, jsonList);
  }

  // Load watch history
  Future<List<Video>> loadWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_watchHistoryKey) ?? [];
    return jsonList
        .map((jsonStr) => Video.fromJson(json.decode(jsonStr)))
        .toList();
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
