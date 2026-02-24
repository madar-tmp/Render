# WireGuard VPN Server on Render

## Deployment Instructions

### 1. Fork this repository
Click the Fork button on GitHub

### 2. Get your Ngrok token
- Sign up at https://ngrok.com
- Get token from https://dashboard.ngrok.com/get-started/your-authtoken

### 3. Deploy on Render
1. Go to https://dashboard.render.com
2. Click "New Blueprint"
3. Connect this repository
4. Add environment variable:
   - Key: `NGROK_AUTH_TOKEN`
   - Value: Your ngrok token
5. Click "Apply"

### 4. Get your WireGuard config
After deployment, check:
- Render logs for QR codes
- Or visit `https://your-app.onrender.com/config/`

### 5. Connect from phone
1. Install WireGuard app
2. Scan QR code or import .conf file
3. Enable connection