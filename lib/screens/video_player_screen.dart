import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';
import '../providers/bookmark_provider.dart';
import '../services/youtube_service.dart';
import '../widgets/video_card.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final YouTubeService _youtubeService = YouTubeService();
  final ScrollController _scrollController = ScrollController();

  List<Video> _relatedVideos = [];
  String? _nextPageToken;
  bool _isLoadingRelated = false;
  bool _hasMoreRelated = true;
  bool _isPlayerReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Extract video ID from URL
    String? videoId;
    try {
      videoId = YoutubePlayer.convertUrlToId(widget.video.videoUrl);
    } catch (e) {
      print('Error parsing video URL: $e');
    }

    _controller =
        YoutubePlayerController(
          initialVideoId: videoId ?? '',
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            controlsVisibleAtStart: true,
          ),
        )..addListener(() {
          if (_controller.value.isReady && !_isPlayerReady) {
            setState(() {
              _isPlayerReady = true;
            });
          }
        });

    // Load related videos from same channel
    _loadRelatedVideos();

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      if (!_isLoadingRelated && _hasMoreRelated) {
        _loadMoreRelatedVideos();
      }
    }
  }

  Future<void> _loadRelatedVideos() async {
    setState(() {
      _isLoadingRelated = true;
      _errorMessage = null;
    });

    try {
      final result = await _youtubeService
          .getChannelVideos(widget.video.channelTitle)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your connection.',
              );
            },
          );

      final videos = result['videos'] as List<Video>;

      setState(() {
        _relatedVideos = videos;
        _nextPageToken = result['nextPageToken'] as String?;
        _hasMoreRelated = _nextPageToken != null && videos.isNotEmpty;
        _isLoadingRelated = false;

        // Show message if no videos found
        if (videos.isEmpty) {
          _errorMessage = 'No videos found from this channel';
        }
      });
    } catch (e) {
      print('Error loading related videos: $e');
      setState(() {
        _isLoadingRelated = false;
        _errorMessage = e.toString().contains('timeout')
            ? 'Connection timeout. Please try again.'
            : 'Failed to load videos. Please try again.';
      });
    }
  }

  Future<void> _loadMoreRelatedVideos() async {
    if (_nextPageToken == null) return;

    setState(() {
      _isLoadingRelated = true;
    });

    try {
      final result = await _youtubeService
          .getChannelVideos(
            widget.video.channelTitle,
            pageToken: _nextPageToken,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      final videos = result['videos'] as List<Video>;

      setState(() {
        _relatedVideos.addAll(videos);
        _nextPageToken = result['nextPageToken'] as String?;
        _hasMoreRelated = _nextPageToken != null && videos.isNotEmpty;
        _isLoadingRelated = false;
      });
    } catch (e) {
      print('Error loading more related videos: $e');
      setState(() {
        _isLoadingRelated = false;
        _hasMoreRelated = false; // Stop trying to load more on error
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final isBookmarked = bookmarkProvider.isBookmarked(widget.video.id);

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        progressColors: ProgressBarColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Watch Video'),
            actions: [
              // Watch on YouTube button (backup)
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Watch on YouTube',
                onPressed: () async {
                  final uri = Uri.parse(widget.video.videoUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.favorite : Icons.favorite_border,
                  color: isBookmarked ? Colors.red : null,
                ),
                onPressed: () {
                  bookmarkProvider.toggleBookmark(widget.video);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YouTube Player with loading state
                _isPlayerReady
                    ? player
                    : AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                // Video info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.video.channelTitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (widget.video.duration != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.video.duration!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.video.description.isNotEmpty
                            ? widget.video.description
                            : 'No description available',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),

                // Related Videos Section
                const Divider(thickness: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.video_library,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'More from ${widget.video.channelTitle}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),

                // Related Videos Grid
                if (_relatedVideos.isEmpty && _isLoadingRelated)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadRelatedVideos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_relatedVideos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No more videos from this channel',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount:
                          _relatedVideos.length + (_hasMoreRelated ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _relatedVideos.length) {
                          // Loading indicator at the end
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final video = _relatedVideos[index];
                        return VideoCard(
                          video: video,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VideoPlayerScreen(video: video),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                // Bottom padding
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
