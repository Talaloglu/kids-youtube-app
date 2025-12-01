import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import youtubeSearch from "npm:youtube-search-api";

// CORS headers
const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Helper function to convert seconds to readable duration format
const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
        return `${hours}:${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
    }
    return `${minutes}:${secs.toString().padStart(2, "0")}`;
};

// Parse ISO 8601 duration or time string to seconds
const parseDuration = (duration: string | undefined): number => {
    if (!duration) return 0;

    // Try ISO 8601 format first
    const isoMatch = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
    if (isoMatch) {
        const hours = parseInt(isoMatch[1] || "0");
        const minutes = parseInt(isoMatch[2] || "0");
        const seconds = parseInt(isoMatch[3] || "0");
        return hours * 3600 + minutes * 60 + seconds;
    }

    // Try simple time format (HH:MM:SS or MM:SS)
    const parts = duration.split(":").map((p) => parseInt(p) || 0);
    if (parts.length === 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length === 2) {
        return parts[0] * 60 + parts[1];
    }

    return 0;
};

// Extract episode number from title
const extractEpisodeNumber = (title: string): number | null => {
    const patterns = [
        /(?:E|EP|Episode)\s*(\d+)/i,
        /الحلقة\s*(\d+)/,
        /حلقة\s*(\d+)/,
        /#(\d+)/,
        /\[(\d+)\]/,
        /\((\d+)\)/,
    ];

    for (const pattern of patterns) {
        const match = title.match(pattern);
        if (match) {
            return parseInt(match[1]);
        }
    }

    return null;
};

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const url = new URL(req.url);
        const path = url.pathname.replace(/\/$/, ""); // Remove trailing slash

        // Route handling
        // Supabase functions are usually deployed at /functions/v1/function-name
        // So the path might be just "/" or "/series" depending on how it's invoked.
        // We'll check the end of the path.

        const q = url.searchParams.get("q");
        const pageParam = url.searchParams.get("page") || "1";

        // Pagination logic: If pageParam is "1", it's initial. Otherwise it's a token.
        // However, the frontend might send "2" if we don't return a token.
        // But we WILL return a token.
        // If the client sends a number > 1 but it's NOT a token, we can't really support it without state.
        // We will assume if it's not "1", it's a token.

        let responseData = {};

        if (path.endsWith("/series")) {
            if (!q) throw new Error('Query parameter "q" is required');

            let searchResults;
            if (pageParam === "1") {
                const searchQuery = "مسلسل عربي " + q + " series episode";
                searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);
            } else {
                // Assume pageParam is the continuation token (serialized JSON)
                try {
                    // Try to parse it as JSON if we encoded it, or pass raw if library handles it
                    // The library returns an object for nextPage. We should probably serialize it.
                    const continuation = JSON.parse(atob(pageParam));
                    searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                } catch (e) {
                    // If parsing fails, maybe it's just a raw string or invalid
                    console.error("Failed to parse continuation token", e);
                    return new Response(JSON.stringify({ videos: [], nextPageToken: null }), {
                        headers: { ...corsHeaders, "Content-Type": "application/json" },
                    });
                }
            }

            const seriesVideos = (searchResults.items || [])
                .filter((item: any) => item.type === "video")
                .map((video: any) => {
                    const durationSeconds = parseDuration(
                        video.length?.simpleText || video.lengthText || video.duration || ""
                    );

                    if (durationSeconds < 600 || durationSeconds > 3600) return null;

                    return {
                        id: video.id,
                        title: video.title,
                        thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                        channelTitle: video.channelTitle || "Unknown",
                        channelId: video.channelId || "",
                        publishedAt: video.publishedTime || "Recently",
                        description: video.description || "",
                        category: "series",
                        videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                        duration: formatDuration(durationSeconds),
                        episodeNumber: extractEpisodeNumber(video.title || ""),
                        isShort: false,
                    };
                })
                .filter((v: any) => v !== null);

            // Serialize nextPage token for the client
            const nextPageToken = searchResults.nextPage
                ? btoa(JSON.stringify(searchResults.nextPage))
                : null;

            responseData = { videos: seriesVideos, nextPageToken };

        } else if (path.endsWith("/shorts")) {
            if (!q) throw new Error('Query parameter "q" is required');

            let searchResults;
            if (pageParam === "1") {
                const searchQuery = "فيديو قصير " + q + " shorts";
                searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);
            } else {
                try {
                    const continuation = JSON.parse(atob(pageParam));
                    searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                } catch (e) {
                    return new Response(JSON.stringify({ videos: [], nextPageToken: null }), {
                        headers: { ...corsHeaders, "Content-Type": "application/json" },
                    });
                }
            }

            const shortsVideos = (searchResults.items || [])
                .filter((item: any) => item.type === "video")
                .map((video: any) => {
                    const durationSeconds = parseDuration(
                        video.length?.simpleText || video.lengthText || video.duration || ""
                    );

                    if (durationSeconds >= 300 || durationSeconds < 10) return null;

                    return {
                        id: video.id,
                        title: video.title,
                        thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                        channelTitle: video.channelTitle || "Unknown",
                        channelId: video.channelId || "",
                        publishedAt: video.publishedTime || "Recently",
                        description: video.description || "",
                        category: "shorts",
                        videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                        duration: formatDuration(durationSeconds),
                        isShort: true,
                    };
                })
                .filter((v: any) => v !== null);

            const nextPageToken = searchResults.nextPage
                ? btoa(JSON.stringify(searchResults.nextPage))
                : null;

            responseData = { videos: shortsVideos, nextPageToken };

        } else if (path.endsWith("/search")) {
            if (!q) throw new Error('Query parameter "q" is required');

            let searchResults;
            if (pageParam === "1") {
                const searchQuery = "عربي " + q + " arabic";
                searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);
            } else {
                try {
                    const continuation = JSON.parse(atob(pageParam));
                    searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                } catch (e) {
                    return new Response(JSON.stringify({ videos: [], nextPageToken: null }), {
                        headers: { ...corsHeaders, "Content-Type": "application/json" },
                    });
                }
            }

            const allVideos = (searchResults.items || [])
                .filter((item: any) => item.type === "video")
                .map((video: any) => {
                    const durationSeconds = parseDuration(
                        video.length?.simpleText || video.lengthText || video.duration || ""
                    );
                    const isShort = durationSeconds > 0 && durationSeconds < 300;

                    return {
                        id: video.id,
                        title: video.title,
                        thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                        channelTitle: video.channelTitle || "Unknown",
                        channelId: video.channelId || "",
                        publishedAt: video.publishedTime || "Recently",
                        description: video.description || "",
                        category: "general",
                        videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                        duration: formatDuration(durationSeconds),
                        isShort: isShort,
                    };
                });

            const nextPageToken = searchResults.nextPage
                ? btoa(JSON.stringify(searchResults.nextPage))
                : null;

            responseData = { videos: allVideos, nextPageToken };

        } else if (path.includes("/channel/")) {
            // Extract channel ID from path
            // Path might be /adult-series-api/channel/CHANNEL_ID
            const parts = path.split("/");
            const channelId = parts[parts.length - 1]; // Last part

            if (!channelId) throw new Error("Channel ID is required");

            let searchResults;
            const searchQuery = `channel:${channelId}`;

            if (pageParam === "1") {
                searchResults = await youtubeSearch.GetListByKeyword(searchQuery, false, 50);
            } else {
                try {
                    const continuation = JSON.parse(atob(pageParam));
                    searchResults = await youtubeSearch.NextPage(continuation, false, 50);
                } catch (e) {
                    return new Response(JSON.stringify({ videos: [], nextPageToken: null }), {
                        headers: { ...corsHeaders, "Content-Type": "application/json" },
                    });
                }
            }

            const channelVideos = (searchResults.items || [])
                .filter((item: any) => item.type === "video")
                .map((video: any) => {
                    const durationSeconds = parseDuration(
                        video.length?.simpleText || video.lengthText || video.duration || ""
                    );
                    const episodeNumber = extractEpisodeNumber(video.title || "");

                    return {
                        id: video.id,
                        title: video.title,
                        thumbnailUrl: video.thumbnail?.thumbnails?.[0]?.url || `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
                        channelTitle: video.channelTitle || "Unknown",
                        channelId: video.channelId || "",
                        publishedAt: video.publishedTime || "Recently",
                        description: video.description || "",
                        category: "series",
                        videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
                        duration: formatDuration(durationSeconds),
                        episodeNumber: episodeNumber,
                        isShort: durationSeconds < 300,
                    };
                });

            const nextPageToken = searchResults.nextPage
                ? btoa(JSON.stringify(searchResults.nextPage))
                : null;

            responseData = { videos: channelVideos, nextPageToken };

        } else if (path.endsWith("/health") || path === "" || path === "/") {
            responseData = { status: "ok", timestamp: new Date().toISOString() };
        } else {
            return new Response("Not Found", { status: 404, headers: corsHeaders });
        }

        return new Response(JSON.stringify(responseData), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

    } catch (error: any) {
        console.error(error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }
});
