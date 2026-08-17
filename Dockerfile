# ========================================================
# Stage 1: Builder
# ========================================================
FROM golang:alpine AS builder

WORKDIR /src
ARG TARGETARCH
ARG TARGETOS

ENV GOTOOLCHAIN=auto

RUN apk --no-cache --update add \
    build-base \
    gcc \
    git \
    curl \
    bash \
    ca-certificates \
    unzip

# Copy dependency definitions
COPY go.mod go.sum ./

# Copy entire source tree
COPY . .

# Ensure modules are tidy and synchronized
RUN go mod tidy

# Download base geo data files (geoip.dat, geosite.dat) into corebundle/core
RUN mkdir -p corebundle/core && \
    curl -fsSL -o corebundle/core/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat && \
    curl -fsSL -o corebundle/core/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

# Compile the vpn-ui binary with CGO enabled (required for sqlite3)
RUN CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -v -ldflags="-s -w -X 'github.com/mhsanaei/3x-ui/v2/config.Version=v2.5.0'" -o /out/vpn-ui .

# ========================================================
# Stage 2: Runtime Image
# ========================================================
FROM alpine:3.21

LABEL maintainer="sharky-01"
LABEL org.opencontainers.image.source="https://github.com/sharky-01/vpn-ui"
LABEL org.opencontainers.image.description="vpn-ui - Modern Multi-Protocol VPN Management Panel"
LABEL org.opencontainers.image.licenses="GPL-3.0"

WORKDIR /app

# Install runtime dependencies
RUN apk --no-cache --update add \
    ca-certificates \
    tzdata \
    iptables \
    ip6tables \
    iproute2 \
    bash \
    curl \
    fail2ban \
    tini

# Create required directories
RUN mkdir -p /etc/vpn-ui /usr/local/vpn-ui/bin /root/cert /var/log/vpn-ui

# Copy compiled binary from builder stage
COPY --from=builder /out/vpn-ui /usr/local/vpn-ui/vpn-ui
RUN chmod +x /usr/local/vpn-ui/vpn-ui && \
    ln -sf /usr/local/vpn-ui/vpn-ui /usr/bin/vpn-ui

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Environment defaults
ENV VPNUI_DB_FOLDER=/etc/vpn-ui
ENV VPNUI_LOG_FOLDER=/var/log/vpn-ui
ENV TZ=UTC

VOLUME ["/etc/vpn-ui", "/root/cert"]
EXPOSE 2053

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
CMD ["/usr/local/vpn-ui/vpn-ui"]
