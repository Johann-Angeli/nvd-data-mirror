# NVD Data Mirror

A lightweight Docker container serving EPSS scores and National Vulnerability Database (NVD) feeds via NGINX.<br>
Designed specifically for offline, air-gapped, or restricted environments that require local access to NVD data—such as
OWASP Dependency-Track deployments.

## 🚀 Features

* **NVD v2.0 Feeds**: Serves official NVD JSON feeds in version 2.0.
* **EPSS Scores**: Serves official EPSS score from **[epss.empiricalsecurity.com](https://epss.empiricalsecurity.com)**.
* **Air-Gapped Ready**: Delivers a local mirror for systems operating without direct internet access.
* **Regular Updates**: Image is rebuilt every 6 hours to stay aligned with NVD updates (which occur roughly every 2
  hours).
* **Dependency-Track Support**: Acts as an offline feed source for OWASP Dependency-Track.

## 🛠️ Usage

### Docker Run

⚠️ Before using it, you need to override name resolution of your client to redirect **nvd.nist.gov** and/or *
*epss.empiricalsecurity.com** to your docker image.

```bash
docker run -d -p 443:8443 --name vul-data-mirror arrakis75/nvd-data-mirror
```

Once running, the files are accessible over HTTP at https://epss.empiricalsecurity.com or https://nvd.nist.gov.
<br>Ex: https://nvd.nist.gov/feeds/json/cve/2.0/nvdcve-2.0-modified.meta

### Docker Compose for **Dependency-Track**

This Docker Compose file works with the default Dependency-Track configuration out of the box.<br>
This file is based on the official Docker Compose file provided by Dependency-Track ([see here](https://raw.githubusercontent.com/DependencyTrack/docs/main/docs/tutorials/docker-compose.quickstart.yml)).<br>

_Note: All modifications are highlighted with comments._

```yaml
name: Dependency-Track

services:
  apiserver:
    image: ghcr.io/dependencytrack/apiserver:5.1.1
    depends_on:
      postgres:
        condition: service_healthy
    deploy:
      resources:
        limits:
          memory: 2g
    environment:
      DT_DATASOURCE_URL: "jdbc:postgresql://postgres:5432/dtrack"
      DT_DATASOURCE_USERNAME: "dtrack"
      DT_DATASOURCE_PASSWORD: "dtrack"
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - "apiserver-data:/data"
      # Mount CA chain
      - "./pki/ca-chain.pem:/tmp/ca-chain.pem:ro"
    # Force NVD and EPSS redirection to local mirror
    extra_hosts:
      - "nvd.nist.gov:host-gateway"
      - "epss.empiricalsecurity.com:host-gateway"
    # Import mirror CA chain on startup
    entrypoint: >
      /bin/sh -c "
      keytool -delete -alias vuln-data-mirror-ca-chain -cacerts -storepass changeit 2>/dev/null || true &&
      keytool -importcert -noprompt -trustcacerts -alias vuln-data-mirror-ca-chain -file /tmp/ca-chain.pem -cacerts -storepass changeit &&
      exec java $$JAVA_OPTIONS -jar dependency-track-apiserver.jar
      "
    restart: unless-stopped

  frontend:
    image: ghcr.io/dependencytrack/frontend:5.1.1
    environment:
      API_BASE_URL: "http://localhost:8080"
    ports:
      - "127.0.0.1:8081:8080"
    restart: unless-stopped

  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_DB: "dtrack"
      POSTGRES_USER: "dtrack"
      POSTGRES_PASSWORD: "dtrack"
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}" ]
      interval: 5s
      timeout: 3s
      retries: 3
    volumes:
      - "postgres-data:/var/lib/postgresql"

  # Start the vulnerability data mirror
  vuln-data-mirror:
    image: arrakis75/nvd-data-mirror:latest
    ports:
      - "127.0.0.1:443:8443"
    restart: unless-stopped

volumes:
  apiserver-data: { }
  postgres-data: { }
```

## ⚠️ Known Limitations & Warnings

* **Note on TLS & DNS configuration**: The image uses TLS SNI to expose multiple websites over TLS. As a result:
  * Web resources must be queried using their official URLs (e.g.,**nvd.nist.gov** and **epss.empiricalsecurity.com**). 
  * Client name resolution must be overridden (e.g., using extra_hosts in Docker Compose) to redirect traffic to the running container instance.
* **No API Emulation**: This image hosts raw NVD feed files only. It does not emulate or proxy the NVD REST APIs.

## 🔗 Docker images

Generated images can be found on Docker Hub:

* [arrakis75/nvd-data-mirror](https://hub.docker.com/r/arrakis75/nvd-data-mirror)
