# Adult Series & Shorts API

Backend API for the Adult Series & Shorts Flutter app. Provides unlimited YouTube content search with Arabic prioritization, series detection, and shorts filtering.

## Features

- 🎬 **Series Search** - 10-60 minute videos with episode detection
- ⚡ **Shorts Search** - Videos under 5 minutes
- 🔍 **General Search** - All videos, no duration filter
- 📺 **Channel Videos** - Get all videos from a specific channel
- 🌍 **Arabic Priority** - Arabic content prioritized in all searches
- ♾️ **Unlimited** - No API key needed, bypasses YouTube quota limits
- 📊 **Episode Detection** - Automatic episode number extraction

## Endpoints

### 1. Search Series
```
GET /api/series?q={query}&page={page}
```

**Example:**
```bash
curl "http://localhost:3003/api/series?q=drama&page=1"
```

**Response:**
```json
{
  "videos": [
    {
      "id": "video_id",
      "title": "Series Title - Episode 1",
      "thumbnailUrl": "https://...",
      "channelTitle": "Channel Name",
      "channelId": "channel_id",
      "publishedAt": "2 days ago",
      "description": "Description...",
      "category": "series",
      "videoUrl": "https://youtube.com/watch?v=...",
      "duration": "45:30",
      "episodeNumber": 1,
      "isShort": false
    }
  ],
  "nextPageToken": "2"
}
```

### 2. Search Shorts
```
GET /api/shorts?q={query}&page={page}
```

**Example:**
```bash
curl "http://localhost:3003/api/shorts?q=comedy&page=1"
```

### 3. General Search
```
GET /api/search?q={query}&page={page}
```

**Example:**
```bash
curl "http://localhost:3003/api/search?q=action&page=1"
```

### 4. Channel Videos
```
GET /api/channel/{channelId}?page={page}
```

**Example:**
```bash
curl "http://localhost:3003/api/channel/UC_channel_id?page=1"
```

### 5. Health Check
```
GET /api/health
```

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

Server runs on `http://localhost:3003`

## Production

```bash
npm start
```

## Deployment

### Vercel
```bash
vercel
```

### Render
1. Connect GitHub repository
2. Set build command: `npm install`
3. Set start command: `npm start`

### Railway
See `RAILWAY_DEPLOY.md` for detailed instructions

## Environment Variables

No environment variables required! The API uses `youtube-search-api` which doesn't need an API key.

## Filters

| Endpoint | Duration Filter | Content Priority |
|----------|----------------|------------------|
| `/api/series` | 10-60 minutes | Arabic series |
| `/api/shorts` | < 5 minutes | Arabic shorts |
| `/api/search` | No filter | Arabic content |
| `/api/channel/:id` | No filter | Channel-specific |

## Episode Detection

The API automatically detects episode numbers from video titles using patterns:
- `E01`, `EP1`, `Episode 1`
- `الحلقة 1`, `حلقة 1`
- `#1`, `[1]`, `(1)`

## Tech Stack

- **Express.js** - Web server
- **youtube-search-api** - YouTube search without API key
- **CORS** - Cross-origin support

## License

MIT
