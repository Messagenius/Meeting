#!/bin/bash
set -e

# OCTO2 CONFIG
PUBLIC_IP="100.72.149.70"      # ← YOUR Tailscale IP
MAIN_IP="77.42.69.64"          # ← Main Hetzner server
NAMESPACE="jitsi-octo2"
JVB_PORT=30302                 # ← Unique port

GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'

echo -e "${GREEN}OCTO2 JVB Deploy${NC}"
echo "Main: ${YELLOW}${MAIN_IP}${NC} | This: ${YELLOW}${PUBLIC_IP}${NC}\n"

# Clean + namespace
microk8s kubectl delete ns ${NAMESPACE} --ignore-not-found=true
sleep 3
microk8s kubectl create ns ${NAMESPACE}

# SAME SECRETS as main server
microk8s kubectl create secret generic jitsi-config -n ${NAMESPACE} \
  --from-literal=JICOFO_COMPONENT_SECRET="c551843e4e2c34d71bdc5f129edd5036" \
  --from-literal=JICOFO_AUTH_PASSWORD="d454401783df86f8b4a13971198b01fd" \
  --from-literal=JVB_AUTH_PASSWORD="48b48c4edbbde7e972de6a52d0ed97ca"

# Deploy OCTO2 JVB only
microk8s kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: jvb-config
  namespace: ${NAMESPACE}
data:
  sip-communicator.properties: |
    org.jitsi.videobridge.xmpp.disable_certificate_verification=true
    org.jitsi.videobridge.xmpp.SECURITY_MODE=disabled
    org.jitsi.videobridge.octo.BIND_ADDRESS=0.0.0.0
    org.jitsi.videobridge.xmpp.hosts.usePlain=${MAIN_IP}:30222
    org.jitsi.videobridge.xmpp.disableTLS=true
    org.jitsi.videobridge.octo.PUBLIC_ADDRESS=${PUBLIC_IP}
    org.jitsi.videobridge.octo.BIND_PORT=8081
    org.jitsi.videobridge.octo.REGION=home
    org.jitsi.videobridge.REGION=home                # ← ADD THIS TOO!

---
apiVersion: v1
kind: Service
metadata:
  name: jvb
  namespace: ${NAMESPACE}
spec:
  type: NodePort
  ports:
  - port: ${JVB_PORT}
    protocol: UDP
    targetPort: ${JVB_PORT}
    nodePort: ${JVB_PORT}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jvb
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jvb
  template:
    metadata:
      labels:
        app: jvb
    spec:
      containers:
      - name: jvb
        image: sanketnawale/meet-jvb:v1.0
        env:
        - name: XMPP_SERVER
          value: "${MAIN_IP}"
        - name: XMPP_PORT
          value: "30222"
        - name: DOCKER_HOST_ADDRESS
          value: "${PUBLIC_IP}"
        - name: XMPP_DOMAIN
          value: meet.jitsi
        - name: XMPP_AUTH_DOMAIN
          value: auth.meet.jitsi
        - name: XMPP_INTERNAL_MUC_DOMAIN          # ✅ ADDED
          value: internal-muc.meet.jitsi          # ✅ ADDED
        - name: JVB_AUTH_USER                     # ✅ ADDED
          value: jvb                              # ✅ ADDED
        - name: JVB_BREWERY_MUC                   # ✅ ADDED
          value: jvbbrewery                       # ✅ ADDED
        - name: JVB_AUTH_PASSWORD
          valueFrom:
            secretKeyRef:
              name: jitsi-config
              key: JVB_AUTH_PASSWORD
        - name: JVB_PORT
          value: "${JVB_PORT}"
        - name: JVB_ADVERTISE_IPS
          value: "${PUBLIC_IP}"
        - name: XMPP_DISABLE_TLS                  # ✅ ADDED
          value: "true"                           # ✅ ADDED
        ports:
        - containerPort: ${JVB_PORT}
          protocol: UDP
        - containerPort: 8081
          protocol: TCP                           # ✅ FIXED
        volumeMounts:                               # ✅ ADDED
        - name: jvb-config
          mountPath: /config/sip-communicator.properties
          subPath: sip-communicator.properties
      volumes:                                    # ✅ ADDED
      - name: jvb-config
        configMap:
          name: jvb-config
EOF

echo -e "${GREEN}✅ OCTO2 LIVE!${NC}"
echo -e "Check: microk8s kubectl get pods -n jitsi-octo2"
echo -e "Logs:  microk8s kubectl logs -n jitsi-octo2 deployment/jvb -f"
echo -e "Firewall: sudo ufw allow ${JVB_PORT}/udp 8081/tcp"