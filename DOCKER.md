# Docker Deployment Guide for vpn-ui

Run **vpn-ui** seamlessly with Docker and Docker Compose. Multi-arch images (`linux/amd64` and `linux/arm64`) are published automatically on the GitHub Container Registry.

---

## Quick Start with Docker Compose

### 1. Create a `docker-compose.yml`

```yaml
services:
  vpn-ui:
    image: ghcr.io/sharky-01/vpn-ui:latest
    container_name: vpn-ui
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - ./db/:/etc/vpn-ui/
      - ./cert/:/root/cert/
    environment:
      - TZ=UTC
      - XRAY_VMESS_AEAD_FORCED=false
      - XUI_ENABLE_FAIL2BAN=true
    tty: true
```

### 2. Launch the Panel

```bash
docker compose up -d
```

Access the panel web interface at `http://<your-server-ip>:2053`.

---

## Running with Docker CLI

```bash
docker run -d \
  --name vpn-ui \
  --restart unless-stopped \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -v $(pwd)/db:/etc/vpn-ui \
  -v $(pwd)/cert:/root/cert \
  -e TZ=UTC \
  -e XUI_ENABLE_FAIL2BAN=true \
  ghcr.io/sharky-01/vpn-ui:latest
```

---

## Environment Variables

| Variable | Default | Description |
| :--- | :---: | :--- |
| `VPNUI_PORT` | `2053` | Default web interface port |
| `VPNUI_USER` | *random* | Initial admin username (set on first boot) |
| `VPNUI_PASSWORD` | *random* | Initial admin password (set on first boot) |
| `VPNUI_PATH` | `/` | Base URL path for the web interface |
| `XUI_ENABLE_FAIL2BAN` | `true` | Enable built-in Fail2ban protection |
| `XRAY_VMESS_AEAD_FORCED` | `false` | Force VMess AEAD |
| `TZ` | `UTC` | Server timezone (e.g., `Asia/Tehran`, `UTC`) |

---

## Data Volumes & Persistence

* **Database & Configurations:** Mounted to `/etc/vpn-ui/` (holds `vpn-ui.db`, logs, and configuration drop-ins).
* **SSL Certificates:** Mounted to `/root/cert/` for custom SSL/TLS certificates.

---

## Building the Image Locally

```bash
docker build -t vpn-ui:local .
```
