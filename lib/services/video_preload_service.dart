import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Service to preload YouTube video stream URLs for faster playback
///
/// This service pre-fetches the actual video stream URL before the user
/// taps on a video, so when they do tap, playback can start instantly.
class VideoPreloadService {
  static final VideoPreloadService _instance = VideoPreloadService._internal();
  factory VideoPreloadService() => _instance;
  VideoPreloadService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  // Cache of preloaded video URLs: videoId -> stream URL
  final Map<String, String> _urlCache = {};

  // Set of video IDs currently being preloaded
  final Set<String> _loading = {};

  // Maximum cache size to prevent memory issues
  static const int _maxCacheSize = 20;

  /// Get the cached stream URL for a video, or null if not cached
  String? getCachedUrl(String videoId) {
    return _urlCache[videoId];
  }

  /// Check if a video URL is cached
  bool isCached(String videoId) {
    return _urlCache.containsKey(videoId);
  }

  /// Preload video stream URL in the background
  /// Returns immediately, the URL will be available via getCachedUrl later
  void preload(String videoId) {
    // Skip if already cached or loading
    if (_urlCache.containsKey(videoId)) {
      print('VideoPreload: $videoId already cached');
      return;
    }
    if (_loading.contains(videoId)) {
      print('VideoPreload: $videoId already loading');
      return;
    }

    print('VideoPreload: Starting preload for $videoId');
    _loading.add(videoId);

    // Preload in background
    _fetchStreamUrl(videoId)
        .then((url) {
          if (url != null) {
            // Manage cache size
            if (_urlCache.length >= _maxCacheSize) {
              // Remove oldest entry
              _urlCache.remove(_urlCache.keys.first);
            }
            _urlCache[videoId] = url;
            print(
              'VideoPreload: ✓ Cached $videoId (${_urlCache.length} total)',
            );
          } else {
            print('VideoPreload: ✗ No URL found for $videoId');
          }
          _loading.remove(videoId);
        })
        .catchError((e) {
          print('VideoPreload: ✗ Failed $videoId: $e');
          _loading.remove(videoId);
        });
  }

  /// Preload multiple videos (e.g., when a list appears)
  void preloadMany(List<String> videoIds) {
    // Only preload first few to avoid overwhelming network
    for (final id in videoIds.take(5)) {
      preload(id);
    }
  }

  /// Fetch the stream URL for a video
  Future<String?> _fetchStreamUrl(String videoId) async {
    try {
      // Get stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        // Use a faster client
        ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.android],
      );

      // Get muxed stream (audio+video combined) for fastest load
      // Muxed streams are limited to 720p but load much faster
      final muxedStreams = manifest.muxed.toList();

      if (muxedStreams.isNotEmpty) {
        // Sort by quality and pick 360p or lowest for fastest load
        muxedStreams.sort(
          (a, b) => a.videoQuality.index.compareTo(b.videoQuality.index),
        );

        // Prefer 360p for balance of quality and speed
        final stream = muxedStreams.firstWhere(
          (s) => s.videoQuality.index >= 360,
          orElse: () => muxedStreams.first,
        );

        return stream.url.toString();
      }

      // Fallback to video-only stream if no muxed
      if (manifest.video.isNotEmpty) {
        final videoStreams = manifest.video.toList();
        videoStreams.sort(
          (a, b) => a.videoQuality.index.compareTo(b.videoQuality.index),
        );
        return videoStreams.first.url.toString();
      }

      return null;
    } catch (e) {
      print('VideoPreloadService: Error fetching stream for $videoId: $e');
      return null;
    }
  }

  /// Get stream URL with caching - returns cached URL or fetches if needed
  Future<String?> getStreamUrl(String videoId) async {
    // Return cached URL if available
    if (_urlCache.containsKey(videoId)) {
      return _urlCache[videoId];
    }

    // Wait if currently loading
    if (_loading.contains(videoId)) {
      // Poll until loaded (max 10 seconds)
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_urlCache.containsKey(videoId)) {
          return _urlCache[videoId];
        }
        if (!_loading.contains(videoId)) {
          break; // Loading failed
        }
      }
    }

    // Fetch directly if not cached
    final url = await _fetchStreamUrl(videoId);
    if (url != null) {
      _urlCache[videoId] = url;
    }
    return url;
  }

  /// Clear the cache
  void clearCache() {
    _urlCache.clear();
    _loading.clear();
  }

  /// Dispose resources
  void dispose() {
    _yt.close();
    _urlCache.clear();
    _loading.clear();
  }
}
