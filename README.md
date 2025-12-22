# Messagenius Meetings - Custom Jitsi Web

Custom branded Jitsi Meet web interface with automated deployment to Hetzner Cloud Kubernetes cluster.

## 🚀 What This Repository Does

This repository automatically builds and deploys a custom Jitsi Meet web container to Hetzner Cloud whenever code is pushed to the `main` branch.

**Live Meeting Platform:** http://meetiing.duckdns.org:30080/

## 🏗️ How It Works

### **1. GitHub Actions CI/CD Pipeline**

When you push code to `main` branch, the automated pipeline runs:

git push → GitHub Actions → Build Docker → Push to Hub → Deploy Hetzner → Live


**Pipeline Steps:**
1. **Checkout Code** - Gets latest code from GitHub repository
2. **Setup Docker Buildx** - Prepares multi-platform Docker build environment
3. **Login to Docker Hub** - Authenticates to sanketnawale registry
4. **Build & Push Image** - Creates and uploads `sanketnawale/meetings-web:latest`
5. **Deploy to Hetzner** - Updates Kubernetes deployment on Hetzner Cloud

**Build Time:** ~2-3 minutes  
**Total Deployment:** ~5 minutes from push to live

### **2. Docker Image Build**

**Dockerfile Configuration:**

FROM jitsi/web:stable-10590

Custom assets
COPY css/ /usr/share/jitsi-meet/css/
COPY sounds/ /usr/share/jitsi-meet/sounds/
COPY images/ /usr/share/jitsi-meet/images/
COPY fonts/ /usr/share/jitsi-meet/fonts/
COPY static/ /usr/share/jitsi-meet/static/
COPY lang/ /usr/share/jitsi-meet/lang/

Application files
COPY app.js conference.js index.html title.html manifest.json pwa-worker.js /usr/share/jitsi-meet/

Configuration
COPY config.js interface_config.js /usr/share/jitsi-meet/



**Published to:** `sanketnawale/meetings-web:latest` on Docker Hub

**Image includes:**
- Custom Meetings branding
- Modified UI/UX
- **Calendar integration** (Google OAuth)
- Custom config and interface settings

### **3. Hetzner Cloud Deployment**

**Infrastructure:**
- **Kubernetes Cluster:** Hetzner Cloud
- **Namespace:** `jitsi`
- **Service Type:** NodePort (Port 30080)
- **Deployment:** `jitsi-web`
- **Domain:** `meetiing.duckdns.org` (Auto IP updates)

**Update mechanism in Hetzner:**
kubectl set image deployment/jitsi-web web=sanketnawale/meetings-web:latest -n jitsi
kubectl rollout restart deployment/jitsi-web -n jitsi


## 🔗 Using the Platform

### **Chrome Camera/Microphone Fix (HTTP Only)**

Visit: chrome://flags/

Search: "Insecure origins treated as secure"

Add: http://meetiing.duckdns.org:30080/

Enable → Relaunch Chrome


**Production URL:** http://meetiing.duckdns.org:30080/

### **For Organization Members**

**Start a new meeting:** http://meetiing.duckdns.org:30080/YourRoomName

**Quick start:**
1. Open: http://meetiing.duckdns.org:30080/
2. Enter room name (e.g., "team-standup")
3. Click "Start Meeting"
4. Share URL with participants

**Calendar Integration:**
Start room → ⋮ More → Settings → Integration → Calendar

Click "Google Calendar" → Auto-creates event

Invite participants via calendar

**Chrome Extention**

**🚀 [Download CRX → Drag to Chrome](https://github.com/sanketnawale/jidesha-fixed/raw/main/calendar.crx)**

## ✅ What's Fixed
- **Outlook 365** - No more Microsoft Live redirect  
- **Google Calendar** - Working
- **Ready-to-use CRX** - Install in 3 seconds

## 🔧 Install Steps
1. 👆 Click download link above
2. `chrome://extensions/` → **Developer mode** → **Drag CRX**
3. ✅ Done! Open Meet → Calendar buttons work

**Features:**
- ✅ HD video/audio conferencing
- ✅ Screen sharing
- ✅ Chat and reactions
- ✅ Recording capability
- ✅ Virtual backgrounds
- ✅ Lobby mode
- ✅ **Google Calendar integration**
- ✅ Chrome Plugin 

## 🛠️ Development & Deployment

### **Making Changes**

Clone repository
git clone https://github.com/Messagenius/Meeting.git
cd Meeting

Make changes (config.js, CSS, images, etc.)

Test locally (optional)
make dev # Opens http://localhost:8080

Commit & push
git add .
git commit -m "Update calendar integration"
git push origin main

Auto-deploys to meetiing.duckdns.org:30080/ (~5 min)


### **Monitor Deployment**

**GitHub Actions:** https://github.com/Messagenius/Meeting/actions

**Hetzner Kubernetes:**
kubectl get pods -n jitsi
kubectl rollout status deployment/jitsi-web -n jitsi
kubectl logs -f deployment/jitsi-web -n jitsi
kubectl describe pod <pod-name> -n jitsi | grep Image:

text

### **Manual Deployment (if needed)**
docker build -t sanketnawale/meetings-web:latest .
docker push sanketnawale/meetings-web:latest
kubectl set image deployment/jitsi-web web=sanketnawale/meetings-web:latest -n jitsi
kubectl rollout restart deployment/jitsi-web -n jitsi
