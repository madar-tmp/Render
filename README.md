# WireGuard VPN Server on Render

## 🚀 Quick Deploy

1. **Fork this repository** on GitHub

2. **Get Ngrok Token**:
   - Sign up at [ngrok.com](https://ngrok.com)
   - Get token from [dashboard.ngrok.com](https://dashboard.ngrok.com/get-started/your-authtoken)

3. **Deploy on Render**:
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click **"New Blueprint"**
   - Connect your forked repository
   - Add environment variable:
     - Key: `NGROK_AUTH_TOKEN`
     - Value: `your_token_here`
   - Click **"Apply"**

4. **Wait for deployment** (5-10 minutes)

## 📱 Connect Your Phone

After deployment:

1. **Get your config**:
   - Visit `https://your-app.onrender.com:8080/config/`
   - Find `peer_phone/peer_phone.conf`
   - Download or view the file

2. **Install WireGuard** app from Play Store/App Store

3. **Import config**:
   - Open WireGuard app
   - Tap "+" → "Import from file"
   - Select the downloaded .conf file
   - OR scan QR code from Render logs

4. **Connect** and enjoy!

## 🔧 Environment Variables

| Variable | Purpose |
|----------|---------|
| `NGROK_AUTH_TOKEN` | Your ngrok auth token (required) |
| `PEERS` | Client names (default: phone,laptop) |
| `TZ` | Timezone (default: Asia/Kolkata) |

## 📊 Check Status

- **Web UI**: `https://your-app.onrender.com:8080`
- **Render Logs**: See QR codes and connection info
- **WireGuard Configs**: Available at `/config/` endpoint

## ⚠️ Free Tier Limitations

- Render free tier sleeps after inactivity (WireGuard keeps it alive)
- ngrok free UDP tunnels expire after 8 hours (auto-reconnects)
- Limited bandwidth

## 🛑 Stopping the Server

Just delete the Blueprint from Render dashboard.