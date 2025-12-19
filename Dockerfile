FROM jitsi/web:stable-10590

# Custom built assets
COPY css/ /usr/share/jitsi-meet/css/
#COPY libs/ /usr/share/jitsi-meet/libs/
COPY sounds/ /usr/share/jitsi-meet/sounds/
COPY images/ /usr/share/jitsi-meet/images/
COPY fonts/ /usr/share/jitsi-meet/fonts/
COPY static/ /usr/share/jitsi-meet/static/
COPY lang/ /usr/share/jitsi-meet/lang/

# Root files
COPY app.js conference.js index.html title.html manifest.json pwa-worker.js /usr/share/jitsi-meet/

# Override templates
COPY interface_config.js /defaults/interface_config.js
COPY config.js /defaults/config.js

# Force your config to be used - copy directly and make read-only
COPY config.js /usr/share/jitsi-meet/config.js
COPY interface_config.js /usr/share/jitsi-meet/interface_config.js
RUN chmod 444 /usr/share/jitsi-meet/config.js /usr/share/jitsi-meet/interface_config.js

RUN chown -R root:root /usr/share/jitsi-meet

EXPOSE 80 443