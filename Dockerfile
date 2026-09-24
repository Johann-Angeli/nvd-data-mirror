ARG NVD_BASE_URL="https://nvd.nist.gov/feeds/json/cve"
ARG FEED_VERSION="2.0"
ARG START_YEAR=2002

# --- Step 1 : Create a downloader to download nvd feeds ---
FROM alpine:3.19 AS downloader

RUN apk add --no-cache curl bash

ARG NVD_BASE_URL
ARG FEED_VERSION
ARG START_YEAR

WORKDIR /data

RUN set -e; \
    mkdir -p cves; \
    for year in modified recent $(seq ${START_YEAR} $(date +%Y)); do \
      echo "Downloading CVEs data for year ${year}..."; \
      for ext in json.gz json.zip meta; do \
        filename="nvdcve-${FEED_VERSION}-${year}.${ext}"; \
        echo "Downloading ${filename}..."; \
        curl -sSL "${NVD_BASE_URL}/${FEED_VERSION}/${filename}" -o "cves/${filename}" || true; \
      done; \
    done

# --- Step 2 : Create final NGINX image (Chainguard Distroless) ---
FROM cgr.dev/chainguard/nginx:latest

ARG FEED_VERSION

# Copy NGINX configuration for non-root user (65532:65532)
COPY --chown=65532:65532 nginx.conf /etc/nginx/nginx.conf

# Copy CVEs data accessible for non-root user (65532:65532)
COPY --chown=65532:65532 --from=downloader /data/cves /usr/share/nginx/html/feeds/json/cve/${FEED_VERSION}/

# Chainguard is non-root and listen on port 8080
EXPOSE 8080