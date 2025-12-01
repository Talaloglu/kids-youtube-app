# Supabase Edge Functions Deployment Guide

## 1. Setup Supabase Project

1.  Go to [Supabase Dashboard](https://supabase.com/dashboard).
2.  Create a new project.
3.  Go to **Project Settings** -> **API**.
4.  Copy the **Project Reference ID** (it's the subdomain of your project URL, e.g., `abcdefghijklm`).

## 2. Get Access Token

1.  Go to [Supabase Access Tokens](https://supabase.com/dashboard/account/tokens).
2.  Generate a new token. Save it immediately.

## 3. Configure GitHub Secrets

1.  Go to your GitHub Repository.
2.  **Settings** -> **Secrets and variables** -> **Actions**.
3.  Add New Repository Secret:
    *   Name: `SUPABASE_ACCESS_TOKEN`
    *   Value: (The token you generated)
4.  Add New Repository Secret:
    *   Name: `SUPABASE_PROJECT_ID`
    *   Value: (The Project Reference ID)

## 4. Deploy

*   Push your code to the `main` branch.
*   The GitHub Action will automatically deploy the function.

## 5. Update Flutter App

1.  After deployment, go to Supabase Dashboard -> **Edge Functions**.
2.  Copy the URL for `adult-series-api`.
3.  Update `lib/services/youtube_service.dart` in your Flutter app:

```dart
static const String _backendUrl = 'https://<project-ref>.supabase.co/functions/v1/adult-series-api';
```
