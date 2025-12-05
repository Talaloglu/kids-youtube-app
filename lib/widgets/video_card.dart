import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/bookmark_provider.dart';

class VideoCard extends StatefulWidget {
  final Video video;
  final VoidCallback onTap;

  const VideoCard({super.key, required this.video, required this.onTap});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallWidth = constraints.maxWidth < 300;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? (isDark ? Colors.blue.shade400 : Colors.blue.shade200)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                width: 1.5,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: isSmallWidth
                      ? _buildStackedLayout(context)
                      : _buildSideBySideLayout(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStackedLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 4 / 3, child: _buildThumbnail(context)),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildVideoInfo(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSideBySideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 180, height: 135, child: _buildThumbnail(context)),
        const SizedBox(width: 16),
        Expanded(child: _buildVideoInfo(context)),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.video.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            ),
          ),
        ),

        // Favorites Button (Top Right)
        Positioned(
          top: 4,
          right: 4,
          child: Consumer<BookmarkProvider>(
            builder: (context, bookmarkProvider, _) {
              final isBookmarked = bookmarkProvider.isBookmarked(
                widget.video.id,
              );
              return GestureDetector(
                onTap: () => bookmarkProvider.toggleBookmark(widget.video),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBookmarked ? Icons.favorite : Icons.favorite_border,
                    color: isBookmarked ? Colors.red : Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),

        // Duration Badge (Bottom Right)
        if (widget.video.duration != null)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.video.duration!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata (Channel • Date) - Displayed ABOVE title
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.video.channelTitle} • ${widget.video.publishedAt}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Title
        Text(
          widget.video.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
