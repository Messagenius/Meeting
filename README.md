# Messagenius Meetings - Custom Jitsi Web

Custom branded Jitsi Meet web interface with automated deployment to Hetzner Cloud Kubernetes cluster.

## 🚀 What This Repository Does

This repository automatically builds and deploys a custom Jitsi Meet web container to Hetzner Cloud whenever code is pushed to the `main` branch.

**Live Meeting Platform:** http://77.42.69.64:30080/

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
- Custom Messagenius branding
- Modified UI/UX
- Calendar integration
- Custom config and interface settings

### **3. Hetzner Cloud Deployment**

**Infrastructure:**
- **Kubernetes Cluster:** Hetzner Cloud
- **Namespace:** `jitsi`
- **Service Type:** NodePort (Port 30080)
- **Deployment:** `jitsi-web`

**Update mechanism in Hetzner:**
kubectl set image deployment/jitsi-web web=sanketnawale/meetings-web:latest -n jitsi
kubectl rollout restart deployment/jitsi-web -n jitsi


## 🔗 Using the Platform

### **Access Meeting Platform**

## TO Treat Insecure origins treated as secure
visit
chrome://flags/

and add url in  Insecure origins treated as secure enbale it and save relod the page , and access teh below url

**Production URL:**
http://77.42.69.64:30080/


### **For Organization Members**

**Start a new meeting:**
http://77.42.69.64:30080/YourRoomName



**Quick start:**
1. Open: http://77.42.69.64:30080/
2. Enter a room name (e.g., "team-standup")
3. Click "Start Meeting"
4. Share the URL with participants

**Features:**
- ✅ HD video/audio conferencing
- ✅ Screen sharing
- ✅ Chat and reactions
- ✅ Recording capability
- ✅ Virtual backgrounds
- ✅ Password protection
- ✅ Lobby mode
- ✅ Calendar integration

## 🛠️ Development & Deployment

### **Making Changes**

1. Clone repository
git clone https://github.com/Messagenius/Meeting.git
cd Meeting

2. Make your changes
Edit files: config.js, interface_config.js, CSS, images, etc.
3. Test locally (optional)
make dev

Opens at http://localhost:8080
4. Commit and push
git add .
git commit -m "Description of changes"
git push origin main

5. Automatic deployment happens!
- GitHub Actions builds Docker image
- Pushes to sanketnawale/meetings-web:latest
- Updates Hetzner Kubernetes deployment
- Live in ~5 minutes


### **Monitor Deployment**

**Check GitHub Actions:**
https://github.com/Messagenius/Meeting/actions

**Check Hetzner Kubernetes:**
View pods
kubectl get pods -n jitsi

Check deployment status
kubectl rollout status deployment/jitsi-web -n jitsi

View recent events
kubectl get events -n jitsi --sort-by='.lastTimestamp'

Check logs
kubectl logs -f deployment/jitsi-web -n jitsi

Verify image version
kubectl describe pod <pod-name> -n jitsi | grep Image:


### **Manual Deployment (if needed)**

Build image locally
docker build -t sanketnawale/meetings-web:latest .

Push to Docker Hub
docker push sanketnawale/meetings-web:latest

Update Hetzner deployment
kubectl set image deployment/jitsi-web web=sanketnawale/meetings-web:latest -n jitsi

Restart deployment
kubectl rollout restart deployment/jitsi-web -n jitsi

