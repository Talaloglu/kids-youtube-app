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

  // Channel Videos State
  List<Video> _channelVideos = [];
  bool _isLoadingChannel = false;

  // Similar Videos State
  List<Video> _similarVideos = [];
  bool _isLoadingSimilar = false;

  bool _isPlayerReady = false;

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

    _loadChannelVideos();
    _loadSimilarVideos();
  }

  Future<void> _loadChannelVideos() async {
    setState(() {
      _isLoadingChannel = true;
    });

    try {
      // Fetch 50 videos initially, should be enough for horizontal scroll
      final result = await _youtubeService.getChannelVideos(
        widget.video.channelTitle,
      );

      if (mounted) {
        setState(() {
          _channelVideos = result['videos'] as List<Video>;
          _isLoadingChannel = false;
        });
      }
    } catch (e) {
      print('Error loading channel videos: $e');
      if (mounted) {
        setState(() {
          _isLoadingChannel = false;
        });
      }
    }
  }

  Future<void> _loadSimilarVideos() async {
    setState(() {
      _isLoadingSimilar = true;
    });

    try {
      final result = await _youtubeService.getRelatedVideos(
        widget.video.title,
        excludeChannel: widget.video.channelTitle,
      );

      if (mounted) {
        setState(() {
          _similarVideos = result['videos'] as List<Video>;
          _isLoadingSimilar = false;
        });
      }
    } catch (e) {
      print('Error loading similar videos: $e');
      if (mounted) {
        setState(() {
          _isLoadingSimilar = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildHorizontalVideoList(
    BuildContext context,
    String title,
    List<Video> videos,
    bool isLoading,
  ) {
    if (videos.isEmpty && !isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240, // Fixed height for video card + details
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Container(
                      width: 200, // Fixed width for horizontal cards
                      margin: const EdgeInsets.only(right: 12),
                      child: VideoCard(
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player
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

                // Video Details
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
                          Icon(Icons.person, size: 16, color: Colors.grey),
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
                              color: Colors.grey,
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

                const Divider(thickness: 8),
                const SizedBox(height: 16),

                // Section 1: More from Channel
                _buildHorizontalVideoList(
                  context,
                  'More from ${widget.video.channelTitle}',
                  _channelVideos,
                  _isLoadingChannel,
                ),

                const SizedBox(height: 24),

                // Section 2: Similar Videos
                _buildHorizontalVideoList(
                  context,
                  'Similar Videos',
                  _similarVideos,
                  _isLoadingSimilar,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
