# Wine Emulator Service Dockerfile
# Supports x86 to x64 Windows application translation
FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies first
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg2 \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add Wine repository and install Wine
RUN dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
    apt-get update && \
    apt-get install -y --install-recommends wine-stable || \
    apt-get install -y wine wine64 wine32 || \
    (echo "WARNING: Using system Wine packages" && apt-get install -y wine) && \
    rm -rf /var/lib/apt/lists/*

# Install VNC and display packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    supervisor \
    nginx \
    python3 \
    python3-pip \
    websockify \
    python3-numpy \
    cabextract \
    unzip \
    xauth \
    zenity \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC for web-based VNC access
RUN mkdir -p /opt/novnc /opt/websockify && \
    wget -qO- https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz -C /opt/novnc --strip-components=1 && \
    wget -qO- https://github.com/novnc/websockify/archive/v0.11.0.tar.gz | tar xz -C /opt/websockify --strip-components=1 && \
    ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# Configure Wine for x86 to x64 translation
# WINEARCH=win64 enables both 32-bit (x86) and 64-bit (x64) Windows applications
ENV WINEARCH=win64
ENV WINEPREFIX=/root/.wine
ENV DISPLAY=:0
ENV WINE_MONO_VERSION=7.4.0

# Create necessary directories
RUN mkdir -p /root/.wine /tmp/.X11-unix /var/log/supervisor /app

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create simple nginx config for noVNC
RUN echo 'server { \n\
    listen 8080; \n\
    location / { \n\
        root /opt/novnc; \n\
        index vnc.html index.html; \n\
    } \n\
}' > /etc/nginx/sites-available/default

# Expose ports
# 5900: VNC server
# 8080: noVNC web interface
EXPOSE 5900 8080

# Volume for Wine prefix (persistent application data)
VOLUME ["/root/.wine"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Start supervisor which manages all services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
