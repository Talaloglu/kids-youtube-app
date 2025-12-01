# Deploy Adult Series API to Render

## Quick Deploy Steps

1. **Create a Render Account**
   - Go to https://render.com
   - Sign up with GitHub (free)

2. **Deploy from GitHub**
   - Push your code to GitHub (or use Render's dashboard upload)
   - In Render dashboard, click "New +" → "Web Service"
   - Connect your repository or use manual deploy

3. **Configure Service**
   - **Name**: `adult-series-api`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

4. **Deploy**
   - Click "Create Web Service"
   - Wait 2-3 minutes for deployment
   - Copy your service URL (e.g., `https://adult-series-api.onrender.com`)

5. **Update Flutter App**
   - Open `lib/services/youtube_service.dart`
   - Change line 11 to your Render URL:
   ```dart
   static const String _backendUrl = 'https://adult-series-api.onrender.com';
   ```
   - Hot restart the app (press R)

## Alternative: Quick Test with ngrok (Temporary)

If you want to test immediately without deploying:

1. **Download ngrok**: https://ngrok.com/download
2. **Run ngrok**:
   ```bash
   ngrok http 3003
   ```
3. **Copy the https URL** (e.g., `https://abc123.ngrok.io`)
4. **Update Flutter app** with that URL
5. **Hot restart**

The ngrok URL expires after a few hours but is perfect for testing.

---

**Which option would you prefer?**
- Deploy to Render (permanent, free)
- Use ngrok (temporary, quick test)
- Or I can help you troubleshoot the firewall more?
