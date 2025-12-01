# Adult Series & Shorts App

A Flutter mobile application for adults to watch Arabic series and short videos from YouTube.

## Features

- 📺 **Series** - Watch Arabic series (10-60 minute episodes)
- ⚡ **Shorts** - Quick videos under 5 minutes
- 🔍 **Search** - Find specific content
- ❤️ **Favorites** - Save your favorite videos
- 📜 **Watch History** - Track what you've watched
- 🌓 **Dark Mode** - Dark theme by default
- ♾️ **Unlimited Content** - Backend proxy bypasses YouTube API limits

## Categories

1. 🎭 Drama - مسلسلات درامية
2. 😂 Comedy - كوميديا
3. 🎬 Action - أكشن
4. 💕 Romance - رومانسية
5. 🔍 Thriller - إثارة وتشويق
6. 📚 Documentary - وثائقي
7. 🎤 Talk Shows - برامج حوارية
8. 📰 News - أخبار
9. ⚽ Sports - رياضة
10. 🎵 Music - موسيقى

## Architecture

```
Flutter App → Backend API (Node.js) → YouTube (unlimited)
```

- **Frontend**: Flutter with Provider state management
- **Backend**: Express.js on port 3003
- **Content**: Arabic-prioritized series and shorts

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Node.js (for backend API)

### Installation

#### 1. Install Flutter Dependencies

```bash
cd adult_series_app
flutter pub get
```

#### 2. Install Backend Dependencies

```bash
cd api
npm install
```

### Running the App

#### Step 1: Start the Backend API

```bash
cd api
npm run dev
```

The backend will run on `http://localhost:3003`

#### Step 2: Run the Flutter App

In a new terminal:

```bash
cd adult_series_app
flutter run
```

## Project Structure

```
adult_series_app/
├── api/                  # Backend proxy server (Node.js)
│   ├── index.js         # Express server with series/shorts endpoints
│   ├── package.json     # Backend dependencies
│   └── README.md        # Backend documentation
├── lib/
│   ├── models/          # Data models (Video, Series, Category)
│   ├── services/        # API services and storage
│   ├── providers/       # State management (Provider pattern)
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable widgets
│   ├── theme/           # App theming (dark/light)
│   └── main.dart        # App entry point
├── assets/
│   ├── images/
│   └── icons/
└── pubspec.yaml
```

## Backend API

The backend uses `youtube-search-api` to:
- Bypass YouTube API quota limits
- Filter content by duration (series: 10-60 min, shorts: <5 min)
- Prioritize Arabic content
- Detect episode numbers automatically

See [api/README.md](api/README.md) for backend documentation.

## Deployment

### Deploy Backend

Deploy the `api/` folder to:
- **Render** (recommended)
- **Vercel**
- **Railway**

### Update Flutter App

After deploying backend, update `lib/services/youtube_service.dart`:

```dart
static const String _backendUrl = 'https://your-deployed-backend.com';
```

Then build and deploy the Flutter app.

## Dependencies

### Flutter
- `provider` - State management
- `http` - HTTP requests
- `shared_preferences` - Local storage
- `youtube_player_flutter` - Video playback
- `cached_network_image` - Image caching
- `google_fonts` - Custom fonts (Poppins, Inter)

### Backend (Node.js)
- `express` - Web server
- `cors` - CORS support
- `youtube-search-api` - YouTube search without API key

## License

This project is created for educational purposes.
