const express = require('express');
const cors = require('cors');
const youtubeSearch = require('youtube-search-api');

const app = express();
const PORT = process.env.PORT || 3003; // Different port from kids app (3002)

// Enable CORS for all origins
app.use(cors());

// Cache for storing search continuation tokens
const searchCache = new Map();

// Helper function to convert seconds to readable duration format
const formatDuration = (seconds) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
        return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
};

// Parse ISO 8601 duration (PT1H2M10S) or time string to seconds
const parseDuration = (duration) => {
    if (!duration) return 0;

    // Try ISO 8601 format first
    const isoMatch = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
    if (isoMatch) {
        const hours = parseInt(isoMatch[1] || 0);
        const minutes = parseInt(isoMatch[2] || 0);
        const seconds = parseInt(isoMatch[3] || 0);
        return hours * 3600 + minutes * 60 + seconds;
    }

    // Try simple time format (HH:MM:SS or MM:SS)
    const parts = duration.split(':').map(p => parseInt(p) || 0);
    if (parts.length === 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length === 2) {
        return parts[0] * 60 + parts[1];
    }

    return 0;
};

// Extract episode number from title
const extractEpisodeNumber = (title) => {
    // Match patterns like: E01, EP1, Episode 1, الحلقة 1, etc.
    const patterns = [
        /(?:E|EP|Episode)\s*(\d+)/i,
        /الحلقة\s*(\d+)/,
        /حلقة\s*(\d+)/,
        /#(\d+)/,
        /\[(\d+)\]/,
        /\((\d+)\)/
    ];

    for (const pattern of patterns) {
        const match = title.match(pattern);
        if (match) {
            return parseInt(match[1]);
        }
    }

    return null;
};

// Search for series (10-60 minute videos)
app.get('/api/series', async (req, res) => {
    try {
        const { q, page = 1 } = req.query;

        if (!q) {
            return res.status(400).json({ error: 'Query parameter "q" is required' });
        }

        console.log(`[Series API] Searching for: ${q}, page: ${page}`);

        let searchResults;
        const pageNum = parseInt(page);

        // For page 1, do a fresh search
        if (pageNum === 1) {
            console.time('YouTube Search');
            // Prioritize Arabic series content
            const searchQuery = 'مسلسل عربي ' + q + ' series episode';
            console.log(`[Series API] Enhanced search query: ${searchQuery}`);

            searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);
            console.timeEnd('YouTube Search');

            // Cache the continuation token for next page
            if (searchResults.nextPage) {
                const cacheKey = `${q}_series_continuation`;
                searchCache.set(cacheKey, searchResults.nextPage);
            }
        } else {
            // For subsequent pages, use the continuation token
            const cacheKey = `${q}_series_continuation`;
            const continuation = searchCache.get(cacheKey);

            if (continuation) {
                searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                // Update cache with new continuation token
                if (searchResults.nextPage) {
                    searchCache.set(cacheKey, searchResults.nextPage);
                }
            } else {
                return res.json({ videos: [], nextPageToken: undefined });
            }
        }

        // Filter and format videos for series (10-60 minutes)
        const seriesVideos = (searchResults.items || [])
            .filter(item => item.type === 'video')
            .map(video => {
                const durationSeconds = parseDuration(
                    video.length?.simpleText ||
                    video.lengthText ||
                    video.duration ||
                    ''
                );

                // Filter: 10-60 minutes (600-3600 seconds)
                if (durationSeconds < 600 || durationSeconds > 3600) return null;

                const episodeNumber = extractEpisodeNumber(video.title || '');

                return {
                    id: video.id,
                    title: video.title,
                    thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                    channelTitle: video.channelTitle || 'Unknown',
                    channelId: video.channelId || '',
                    publishedAt: video.publishedTime || 'Recently',
                    description: video.description || '',
                    category: 'series',
                    videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                    duration: formatDuration(durationSeconds),
                    episodeNumber: episodeNumber,
                    isShort: false
                };
            })
            .filter(v => v !== null);

        console.log(`[Series API] Found ${seriesVideos.length} series videos (10-60min) from ${searchResults.items?.length || 0} total results`);

        const nextPageToken = searchResults.nextPage ? (pageNum + 1).toString() : undefined;

        res.json({
            videos: seriesVideos,
            nextPageToken
        });

    } catch (error) {
        console.error('[Series API] Search error:', error);
        res.status(500).json({
            error: 'Failed to search series',
            message: error.message
        });
    }
});

// Search for shorts (< 5 minute videos)
app.get('/api/shorts', async (req, res) => {
    try {
        const { q, page = 1 } = req.query;

        if (!q) {
            return res.status(400).json({ error: 'Query parameter "q" is required' });
        }

        console.log(`[Shorts API] Searching for: ${q}, page: ${page}`);

        let searchResults;
        const pageNum = parseInt(page);

        if (pageNum === 1) {
            console.time('YouTube Search');
            // Prioritize Arabic short content
            const searchQuery = 'فيديو قصير ' + q + ' shorts';
            console.log(`[Shorts API] Enhanced search query: ${searchQuery}`);

            searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);
            console.timeEnd('YouTube Search');

            if (searchResults.nextPage) {
                const cacheKey = `${q}_shorts_continuation`;
                searchCache.set(cacheKey, searchResults.nextPage);
            }
        } else {
            const cacheKey = `${q}_shorts_continuation`;
            const continuation = searchCache.get(cacheKey);

            if (continuation) {
                searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                if (searchResults.nextPage) {
                    searchCache.set(cacheKey, searchResults.nextPage);
                }
            } else {
                return res.json({ videos: [], nextPageToken: undefined });
            }
        }

        // Filter and format videos for shorts (< 5 minutes)
        const shortsVideos = (searchResults.items || [])
            .filter(item => item.type === 'video')
            .map(video => {
                const durationSeconds = parseDuration(
                    video.length?.simpleText ||
                    video.lengthText ||
                    video.duration ||
                    ''
                );

                // Filter: < 5 minutes (< 300 seconds)
                if (durationSeconds >= 300 || durationSeconds < 10) return null;

                return {
                    id: video.id,
                    title: video.title,
                    thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                    channelTitle: video.channelTitle || 'Unknown',
                    channelId: video.channelId || '',
                    publishedAt: video.publishedTime || 'Recently',
                    description: video.description || '',
                    category: 'shorts',
                    videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                    duration: formatDuration(durationSeconds),
                    isShort: true
                };
            })
            .filter(v => v !== null);

        console.log(`[Shorts API] Found ${shortsVideos.length} shorts (<5min) from ${searchResults.items?.length || 0} total results`);

        const nextPageToken = searchResults.nextPage ? (pageNum + 1).toString() : undefined;

        res.json({
            videos: shortsVideos,
            nextPageToken
        });

    } catch (error) {
        console.error('[Shorts API] Search error:', error);
        res.status(500).json({
            error: 'Failed to search shorts',
            message: error.message
        });
    }
});

// General search (all videos, no duration filter)
app.get('/api/search', async (req, res) => {
    try {
        const { q, page = 1 } = req.query;

        if (!q) {
            return res.status(400).json({ error: 'Query parameter "q" is required' });
        }

        console.log(`[Search API] Searching for: ${q}, page: ${page}`);

        let searchResults;
        const pageNum = parseInt(page);

        if (pageNum === 1) {
            console.time('YouTube Search');
            // Prioritize Arabic content
            const searchQuery = 'عربي ' + q + ' arabic';
            console.log(`[Search API] Enhanced search query: ${searchQuery}`);

            searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);
            console.timeEnd('YouTube Search');

            if (searchResults.nextPage) {
                const cacheKey = `${q}_search_continuation`;
                searchCache.set(cacheKey, searchResults.nextPage);
            }
        } else {
            const cacheKey = `${q}_search_continuation`;
            const continuation = searchCache.get(cacheKey);

            if (continuation) {
                searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                if (searchResults.nextPage) {
                    searchCache.set(cacheKey, searchResults.nextPage);
                }
            } else {
                return res.json({ videos: [], nextPageToken: undefined });
            }
        }

        // Format all videos (no duration filter)
        const allVideos = (searchResults.items || [])
            .filter(item => item.type === 'video')
            .map(video => {
                const durationSeconds = parseDuration(
                    video.length?.simpleText ||
                    video.lengthText ||
                    video.duration ||
                    ''
                );

                const isShort = durationSeconds > 0 && durationSeconds < 300;

                return {
                    id: video.id,
                    title: video.title,
                    thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                    channelTitle: video.channelTitle || 'Unknown',
                    channelId: video.channelId || '',
                    publishedAt: video.publishedTime || 'Recently',
                    description: video.description || '',
                    category: 'general',
                    videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                    duration: formatDuration(durationSeconds),
                    isShort: isShort
                };
            });

        console.log(`[Search API] Found ${allVideos.length} videos from ${searchResults.items?.length || 0} total results`);

        const nextPageToken = searchResults.nextPage ? (pageNum + 1).toString() : undefined;

        res.json({
            videos: allVideos,
            nextPageToken
        });

    } catch (error) {
        console.error('[Search API] Search error:', error);
        res.status(500).json({
            error: 'Failed to search videos',
            message: error.message
        });
    }
});

// Get videos from a specific channel (for series episodes)
app.get('/api/channel/:channelId', async (req, res) => {
    try {
        const { channelId } = req.params;
        const { page = 1 } = req.query;

        if (!channelId) {
            return res.status(400).json({ error: 'Channel ID is required' });
        }

        console.log(`[Channel API] Fetching channel videos: ${channelId}, page: ${page}`);

        const pageNum = parseInt(page);
        let searchResults;

        // Search for videos from this channel
        const searchQuery = `channel:${channelId}`;

        if (pageNum === 1) {
            searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);

            if (searchResults.nextPage) {
                const cacheKey = `${channelId}_channel_continuation`;
                searchCache.set(cacheKey, searchResults.nextPage);
            }
        } else {
            const cacheKey = `${channelId}_channel_continuation`;
            const continuation = searchCache.get(cacheKey);

            if (continuation) {
                searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                if (searchResults.nextPage) {
                    searchCache.set(cacheKey, searchResults.nextPage);
                }
            } else {
                return res.json({ videos: [], nextPageToken: undefined });
            }
        }

        const channelVideos = (searchResults.items || [])
            .filter(item => item.type === 'video')
            .map(video => {
                const durationSeconds = parseDuration(
                    video.length?.simpleText ||
                    video.lengthText ||
                    video.duration ||
                    ''
                );

                const episodeNumber = extractEpisodeNumber(video.title || '');

                return {
                    id: video.id,
                    title: video.title,
                    thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                    channelTitle: video.channelTitle || 'Unknown',
                    channelId: video.channelId || '',
                    publishedAt: video.publishedTime || 'Recently',
                    description: video.description || '',
                    category: 'series',
                    videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                    duration: formatDuration(durationSeconds),
                    episodeNumber: episodeNumber,
                    isShort: durationSeconds < 300
                };
            });

        console.log(`[Channel API] Found ${channelVideos.length} videos from channel: ${channelId}`);

        const nextPageToken = searchResults.nextPage ? (pageNum + 1).toString() : undefined;

        res.json({
            videos: channelVideos,
            nextPageToken
        });

    } catch (error) {
        console.error('[Channel API] Channel videos error:', error);
        res.status(500).json({
            error: 'Failed to fetch channel videos',
            message: error.message
        });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Adult Series & Shorts API',
        endpoints: {
            series: '/api/series?q=query&page=1',
            shorts: '/api/shorts?q=query&page=1',
            search: '/api/search?q=query&page=1',
            channel: '/api/channel/:channelId?page=1',
            health: '/api/health'
        },
        filters: {
            series: '10-60 minutes',
            shorts: '< 5 minutes',
            search: 'No filter'
        },
        features: {
            pagination: 'Unlimited results with youtube-search-api',
            episodeDetection: 'Automatic episode number extraction',
            arabicPriority: 'Arabic content prioritized in all searches'
        }
    });
});

// Export for Vercel serverless
module.exports = app;

// For local development
if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`🚀 Adult Series & Shorts API running on http://localhost:${PORT}`);
        console.log(`📺 Series endpoint: http://localhost:${PORT}/api/series?q=drama`);
        console.log(`⚡ Shorts endpoint: http://localhost:${PORT}/api/shorts?q=comedy`);
        console.log(`🔍 Search endpoint: http://localhost:${PORT}/api/search?q=action`);
        console.log(`🎯 Filters: Series (10-60min), Shorts (<5min)`);
        console.log(`♾️  Pagination: Unlimited results with youtube-search-api`);
    });
}
