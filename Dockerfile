# Stage 1: Use official Jitsi web image as base
FROM jitsi/web:stable-10590

# Remove default Jitsi Meet files
RUN rm -rf /usr/share/jitsi-meet/*

# Stage 2: Copy your custom built files
COPY css/ /usr/share/jitsi-meet/css/
COPY libs/ /usr/share/jitsi-meet/libs/
COPY sounds/ /usr/share/jitsi-meet/sounds/
COPY images/ /usr/share/jitsi-meet/images/
COPY fonts/ /usr/share/jitsi-meet/fonts/
COPY static/ /usr/share/jitsi-meet/static/
COPY lang/ /usr/share/jitsi-meet/lang/

# Copy root files
COPY *.js /usr/share/jitsi-meet/
COPY *.html /usr/share/jitsi-meet/
COPY *.json /usr/share/jitsi-meet/
COPY pwa-worker.js /usr/share/jitsi-meet/

# Set correct permissions
RUN chown -R root:root /usr/share/jitsi-meet

EXPOSE 80 443
