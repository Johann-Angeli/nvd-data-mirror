# NVD Data Mirror

A lightweight Docker container serving National Vulnerability Database (NVD) feeds via NGINX. Designed specifically for offline, air-gapped, or restricted environments that require local access to NVD data—such as OWASP Dependency-Track deployments.

## 🚀 Features

* **NVD v2.0 Feeds**: Serves official NVD JSON feeds in version 2.0.
* **Air-Gapped Ready**: Delivers a local mirror for systems operating without direct internet access.
* **Regular Updates**: Image is rebuilt every 6 hours to stay aligned with NVD updates (which occur roughly every 2 hours).
* **Dependency-Track Support**: Acts as an offline feed source for OWASP Dependency-Track.

## 🛠️ Usage

### Docker Run

```bash
docker run -d -p 8080:8080 --name nvd-mirror arrakis75/nvd-data-mirror
```

Once running, the files are accessible over HTTP at http://localhost:8080.
Ex: https://localhost:8080/feeds/json/cve/2.0/nvdcve-2.0-modified.meta

### Docker Compose
```yaml
version: '3.8'

services:
  nvd-mirror:
    image: arrakis75/nvd-data-mirror
    container_name: nvd-mirror
    ports:
      - "8080:8080"
    restart: unless-stopped
```

## ⚠️ Known Limitations & Scope
* **HTTP Only**: The web server exposes feeds over HTTP without built-in TLS/HTTPS encryption. If HTTPS is needed, place a reverse proxy (e.g., NGINX, Traefik, Caddy) in front of this container.

* **No API Emulation**: This image hosts raw NVD feed files only. It does not emulate or proxy the NVD REST APIs.

## 🔗 Docker images
Generated images can be found on Docker Hub:

* [arrakis75/nvd-data-mirror](https://hub.docker.com/r/arrakis75/nvd-data-mirror)
