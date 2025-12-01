import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class YouTubeService {
  // Backend API URL
  // For physical device: Use your computer's local IP (e.g., 'http://192.168.1.100:3003')
  // For emulator: Use 'http://10.0.2.2:3003'
  // For localhost testing: Use 'http://localhost:3003'
  // TODO: Replace with your computer's IP address
  static const String _backendUrl = 'http://192.168.1.103:3003';

  // Search for series (10-60 minute videos)
  Future<Map<String, dynamic>> searchSeries(
    String query, {
    String? pageToken,
  }) async {
    try {
      final page = pageToken ?? '1';
      final url = Uri.parse(
        '$_backendUrl/api/series',
      ).replace(queryParameters: {'q': query, 'page': page});

      print('Fetching series from backend: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = _parseVideosFromBackend(data['videos'] as List<dynamic>);

        print('Fetched ${videos.length} series videos from backend');

        return {'videos': videos, 'nextPageToken': data['nextPageToken']};
      } else {
        print('Backend API Error: ${response.statusCode}');
        return {'videos': <Video>[], 'nextPageToken': null};
      }
    } catch (e) {
      print('Error fetching series from backend: $e');
      return {'videos': <Video>[], 'nextPageToken': null};
    }
  }

  // Search for shorts (< 5 minute videos)
  Future<Map<String, dynamic>> searchShorts(
    String query, {
    String? pageToken,
  }) async {
    try {
      final page = pageToken ?? '1';
      final url = Uri.parse(
        '$_backendUrl/api/shorts',
      ).replace(queryParameters: {'q': query, 'page': page});

      print('Fetching shorts from backend: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = _parseVideosFromBackend(data['videos'] as List<dynamic>);

        print('Fetched ${videos.length} shorts from backend');

        return {'videos': videos, 'nextPageToken': data['nextPageToken']};
      } else {
        print('Backend API Error: ${response.statusCode}');
        return {'videos': <Video>[], 'nextPageToken': null};
      }
    } catch (e) {
      print('Error fetching shorts from backend: $e');
      return {'videos': <Video>[], 'nextPageToken': null};
    }
  }

  // General search (all videos)
  Future<Map<String, dynamic>> searchVideos(
    String query, {
    String? pageToken,
  }) async {
    try {
      final page = pageToken ?? '1';
      final url = Uri.parse(
        '$_backendUrl/api/search',
      ).replace(queryParameters: {'q': query, 'page': page});

      print('Fetching videos from backend: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = _parseVideosFromBackend(data['videos'] as List<dynamic>);

        print('Fetched ${videos.length} videos from backend');

        return {'videos': videos, 'nextPageToken': data['nextPageToken']};
      } else {
        print('Backend API Error: ${response.statusCode}');
        return {'videos': <Video>[], 'nextPageToken': null};
      }
    } catch (e) {
      print('Error fetching videos from backend: $e');
      return {'videos': <Video>[], 'nextPageToken': null};
    }
  }

  // Get videos by category
  Future<Map<String, dynamic>> getVideosByCategory(
    String category, {
    String? pageToken,
    bool shortsOnly = false,
  }) async {
    // Map category IDs to Arabic search terms
    final categoryQueries = {
      'drama': 'مسلسل دراما عربي',
      'comedy': 'كوميديا عربي مضحك',
      'action': 'أكشن عربي',
      'romance': 'رومانسية عربي',
      'thriller': 'إثارة تشويق عربي',
      'documentary': 'وثائقي عربي',
      'talk_shows': 'برنامج حواري عربي',
      'news': 'أخبار عربية',
      'sports': 'رياضة عربية',
      'music': 'موسيقى أغاني عربية',
    };

    final query = categoryQueries[category] ?? category;

    if (shortsOnly) {
      return searchShorts(query, pageToken: pageToken);
    } else {
      return searchSeries(query, pageToken: pageToken);
    }
  }

  // Get channel videos (for series episodes)
  Future<Map<String, dynamic>> getChannelVideos(
    String channelId, {
    String? pageToken,
  }) async {
    try {
      final page = pageToken ?? '1';
      final url = Uri.parse(
        '$_backendUrl/api/channel/$channelId',
      ).replace(queryParameters: {'page': page});

      print('Fetching channel videos: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = _parseVideosFromBackend(data['videos'] as List<dynamic>);

        print('Fetched ${videos.length} videos from channel');

        return {'videos': videos, 'nextPageToken': data['nextPageToken']};
      } else {
        print('Channel API Error: ${response.statusCode}');
        return {'videos': <Video>[], 'nextPageToken': null};
      }
    } catch (e) {
      print('Error fetching channel videos: $e');
      return {'videos': <Video>[], 'nextPageToken': null};
    }
  }

  // Parse videos from backend response
  List<Video> _parseVideosFromBackend(List<dynamic> videosData) {
    final List<Video> videos = [];

    for (var videoData in videosData) {
      try {
        videos.add(
          Video(
            id: videoData['id'] as String,
            title: videoData['title'] as String,
            thumbnailUrl: videoData['thumbnailUrl'] as String,
            channelTitle: videoData['channelTitle'] as String,
            channelId: videoData['channelId'] as String? ?? '',
            publishedAt: videoData['publishedAt'] as String,
            description: videoData['description'] as String,
            category: videoData['category'] as String? ?? 'general',
            videoUrl: videoData['videoUrl'] as String,
            duration: videoData['duration'] as String?,
            isShort: videoData['isShort'] as bool? ?? false,
            episodeNumber: videoData['episodeNumber'] as int?,
          ),
        );
      } catch (e) {
        print('Error parsing video: $e');
      }
    }

    return videos;
  }
}
