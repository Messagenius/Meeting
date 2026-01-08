#!/bin/bash

# ==============================================
# Jitsi Meet Kubernetes Deployment Script
# ==============================================

set -e

# CONFIGURATION - CHANGE THESE VALUES
# ==============================================
PUBLIC_HOST="meetabc.com"
PUBLIC_IP="server ip"          # ← CHANGE THIS to your server IP or domain
NAMESPACE="jitsi"
WEB_PORT=80
JVB_PORT=30300

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jitsi Meet Kubernetes Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Public Address: ${YELLOW}${PUBLIC_IP}${NC}"
echo -e "Web Port: ${YELLOW}${WEB_PORT}${NC}"
echo -e "JVB UDP Port: ${YELLOW}${JVB_PORT}${NC}"
echo ""

# Delete existing namespace
echo -e "${YELLOW}Deleting existing namespace...${NC}"
microk8s kubectl delete namespace ${NAMESPACE} --ignore-not-found=true
sleep 5

# Create namespace
echo -e "${GREEN}Creating namespace...${NC}"
microk8s kubectl create namespace ${NAMESPACE}

# Generate secrets
echo -e "${GREEN}Generating secrets...${NC}"
microk8s kubectl create secret generic jitsi-config -n ${NAMESPACE} \
  --from-literal=JICOFO_COMPONENT_SECRET=$(openssl rand -hex 16) \
  --from-literal=JICOFO_AUTH_PASSWORD=$(openssl rand -hex 16) \
  --from-literal=JVB_AUTH_PASSWORD=$(openssl rand -hex 16)

# Deploy Jitsi
echo -e "${GREEN}Deploying Jitsi Meet...${NC}"
microk8s kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: jvb-config
  namespace: ${NAMESPACE}
data:
  custom-sip-communicator.properties: |
    org.jitsi.videobridge.ENABLE_STATISTICS=true
    org.jitsi.videobridge.STATISTICS_TRANSPORT=muc
    org.jitsi.videobridge.rest.private.jetty.port=8080
    org.jitsi.videobridge.rest.private.jetty.host=0.0.0.0
    org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=127.0.0.1
    org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=${PUBLIC_IP}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
  namespace: ${NAMESPACE}
data:
  config.js: |
    var config = {
        hosts: {
            domain: 'meet.jitsi',
            muc: 'muc.meet.jitsi',
            focus: 'focus.meet.jitsi'
        },
        bosh: '//meetxyz.com/http-bind',
        websocket: null,
        openBridgeChannel: 'datachannel',
        p2p: { enabled: false },
        enableNoAudioDetection: true,
        enableNoisyMicDetection: true,
        channelLastN: -1,
        constraints: {
            video: {
                height: { ideal: 360, max: 720, min: 180 }
            }
        },
        // == Disable mobile app detection===
        mobileAppPromo: false,
        // Deep link settings (prevents app prompts)
        appScheme: false,
        disableDeepLinking: true,   // ← Force web UI
        enableWelcomePage: true,    // ← Show first page
        disableAudioLevels: false,
        startAudioOnly: false,
        startWithAudioMuted: false,
        startWithVideoMuted: false,
        // === WHITEBOARD INTEGRATION ===
        whiteboard: {
        enabled: true,
        collabServerBaseUrl: 'http://excalidraw.${NAMESPACE}.svc.cluster.local:3002'      
        },
        // === CALENDAR INTEGRATION ===
        enableCalendarIntegration: true,
        googleApiApplicationClientID: "590796445758-2stknbg4evs62cm8kmsenm3v42ftva0p.apps.googleusercontent.com"
    };
  fix-config.sh: |
    #!/bin/bash
    sleep 3
    cp /tmp/config-override/config.js /config/config.js
    echo "Config overridden successfully"
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: ${NAMESPACE}
spec:
  type: ClusterIP
  selector:
    k8s-app: jitsi
  ports:
  - name: http
    port: 80
    targetPort: 80
   # nodePort: 80
# ADD THIS INGRESS after services
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jitsi-web
  namespace: ${NAMESPACE}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: meetxyz.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
---
apiVersion: v1
kind: Service
metadata:
  name: jvb-udp
  namespace: ${NAMESPACE}
spec:
  type: NodePort
  externalTrafficPolicy: Cluster
  selector:
    k8s-app: jitsi
  ports:
  - port: ${JVB_PORT}
    protocol: UDP
    targetPort: ${JVB_PORT}
    nodePort: ${JVB_PORT}
---
apiVersion: v1
kind: Service
metadata:
  name: excalidraw
  namespace: ${NAMESPACE}
spec:
  type: ClusterIP
  selector:
    k8s-app: jitsi
  ports:
  - name: http
    port: 3002
    targetPort: 3002
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jitsi
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: jitsi
  template:
    metadata:
      labels:
        k8s-app: jitsi
    spec:
    #  hostNetwork: true  # ← ADD HERE (pod level)
    #  dnsPolicy: ClusterFirstWithHostNet  # Required with hostNetwork
      containers:
      - name: jicofo
        image: sanketnawale/meet-jicofo:v1.0
        env:
        - {name: XMPP_SERVER, value: localhost}
        - {name: XMPP_DOMAIN, value: meet.jitsi}
        - {name: XMPP_AUTH_DOMAIN, value: auth.meet.jitsi}
        - {name: XMPP_MUC_DOMAIN, value: muc.meet.jitsi}
        - {name: XMPP_INTERNAL_MUC_DOMAIN, value: internal-muc.meet.jitsi}
        - {name: JICOFO_AUTH_USER, value: focus}
        - {name: JVB_BREWERY_MUC, value: jvbbrewery}
        - name: JICOFO_COMPONENT_SECRET
          valueFrom: {secretKeyRef: {name: jitsi-config, key: JICOFO_COMPONENT_SECRET}}
        - name: JICOFO_AUTH_PASSWORD
          valueFrom: {secretKeyRef: {name: jitsi-config, key: JICOFO_AUTH_PASSWORD}}      

      - name: prosody
        image: sanketnawale/meet-prosody:v1.0
        env:
        - {name: XMPP_DOMAIN, value: meet.jitsi}
        - {name: XMPP_AUTH_DOMAIN, value: auth.meet.jitsi}
        - {name: XMPP_MUC_DOMAIN, value: muc.meet.jitsi}
        - {name: XMPP_INTERNAL_MUC_DOMAIN, value: internal-muc.meet.jitsi}
        - {name: JVB_AUTH_USER, value: jvb}
        - {name: JICOFO_AUTH_USER, value: focus}
        - {name: ENABLE_AUTH, value: "0"}
        - name: JICOFO_COMPONENT_SECRET
          valueFrom: {secretKeyRef: {name: jitsi-config, key: JICOFO_COMPONENT_SECRET}}   
        - name: JVB_AUTH_PASSWORD
          valueFrom: {secretKeyRef: {name: jitsi-config, key: JVB_AUTH_PASSWORD}}
        - name: JICOFO_AUTH_PASSWORD
          valueFrom: {secretKeyRef: {name: jitsi-config, key: JICOFO_AUTH_PASSWORD}}      
        ports:
        - {containerPort: 5280}

      - name: web
        image: sanketnawale/meetings-web:v2.1
        imagePullPolicy: Always
        env:
        - {name: XMPP_DOMAIN, value: meet.jitsi}
        - {name: XMPP_BOSH_URL_BASE, value: "http://127.0.0.1:5280"}
        - {name: XMPP_MUC_DOMAIN, value: muc.meet.jitsi}
        - {name: DISABLE_HTTPS, value: "1"}
        - {name: ENABLE_XMPP_WEBSOCKET, value: "0"}
        - {name: ENABLE_CALENDAR, value: "true"}
        - {name: GOOGLE_API_APP_CLIENT_ID, value: "590796445758-2stknbg4evs62cm8kmsenm3v42ftva0p.apps.googleusercontent.com"}
        ports:
        - {containerPort: 80}
        lifecycle:
          postStart:
            exec:
              command: ["/bin/bash", "/tmp/config-override/fix-config.sh"]
        volumeMounts:
        - name: web-config
          mountPath: /tmp/config-override

      - name: jvb
        image: sanketnawale/meet-jvb:v1.0
        env:
        - {name: XMPP_SERVER, value: localhost}
        - {name: DOCKER_HOST_ADDRESS, value: "${PUBLIC_IP}"}
        - {name: XMPP_DOMAIN, value: meet.jitsi}
        - {name: XMPP_AUTH_DOMAIN, value: auth.meet.jitsi}
        - {name: XMPP_INTERNAL_MUC_DOMAIN, value: internal-muc.meet.jitsi}
        - {name: JVB_STUN_SERVERS, value: "stun.l.google.com:19302"}
        - {name: JVB_AUTH_USER, value: jvb}
        - {name: JVB_BREWERY_MUC, value: jvbbrewery}
        - {name: JVB_PORT, value: "${JVB_PORT}"}
        - {name: JVB_ADVERTISE_IPS, value: "${PUBLIC_IP}"}
        - {name: ENABLE_COLIBRI_WEBSOCKET, value: "false"}
        - name: JVB_AUTH_PASSWORD
          valueFrom: {secretKeyRef: {name: jitsi-config, key: JVB_AUTH_PASSWORD}}
        ports:
        - {containerPort: ${JVB_PORT}, protocol: UDP}
        volumeMounts:
        - name: jvb-config
          mountPath: /config/sip-communicator.properties
          subPath: custom-sip-communicator.properties
      - name: excalidraw
        image: jitsi/excalidraw-backend:latest
        env:
        - name: EXCALIDRAW_API_KEY
          value: "jitsi-whiteboard-secret"
        - name: PORT
          value: "3002"
        - name: PROMETHEUS_PORT
          value: "9091"
        ports:
        - containerPort: 3002
        - containerPort: 9091

      volumes:
      - name: web-config
        configMap:
          name: web-config
          defaultMode: 0755
      - name: jvb-config
        configMap:
          name: jvb-config
EOF