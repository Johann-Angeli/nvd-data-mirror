ARG FEED_VERSION="2.0"

# --- Step 1 : Create a downloader to download nvd feeds ---
FROM alpine:3.19 AS downloader

RUN apk add --no-cache curl bash

ARG FEED_VERSION

ARG NVD_FEEDS_BASE_URL="https://nvd.nist.gov/feeds"
ARG CVE_BASE_URL="json/cve"
ARG CPEMATCH_BASE_URL="json/cpematch"
ARG CPE_BASE_URL="json/cpe"
ARG VENDORS_BASE_URL="xml/cve/misc"

ARG START_YEAR=2002

ARG CVE_FILE_EXTENSIONS="json.gz json.zip meta"
ARG CPEMATCH_FILE_EXTENSIONS="tar.gz zip meta"
ARG CPE_FILE_EXTENSIONS=${CPEMATCH_FILE_EXTENSIONS}
ARG VENDORS_FILE_EXTENSIONS="xml.gz xml.zip meta"

WORKDIR /data

RUN set -e; \
    mkdir -p cves; \
    for year in modified recent $(seq ${START_YEAR} $(date +%Y)); do \
      echo "Downloading CVEs data for year ${year}..."; \
      for ext in ${CVE_FILE_EXTENSIONS}; do \
        filename="nvdcve-${FEED_VERSION}-${year}.${ext}"; \
        echo "Downloading ${filename}..."; \
        curl -sSL "${NVD_FEEDS_BASE_URL}/${CVE_BASE_URL}/${FEED_VERSION}/${filename}" -o "cves/${filename}" || true; \
      done; \
    done; \
    mkdir -p cpematch; \
    mkdir -p cpe; \
    mkdir -p vendors; \
    for ext in ${CPEMATCH_FILE_EXTENSIONS}; do \
      filename="nvdcpematch-${FEED_VERSION}.${ext}"; \
      echo "Downloading ${filename}..."; \
      curl -sSL "${NVD_FEEDS_BASE_URL}/${CPEMATCH_BASE_URL}/${FEED_VERSION}/${filename}" -o "cpematch/${filename}" || true; \
    done; \
    for ext in ${CPE_FILE_EXTENSIONS}; do \
      filename="nvdcpe-${FEED_VERSION}.${ext}"; \
      echo "Downloading ${filename}..."; \
      curl -sSL "${NVD_FEEDS_BASE_URL}/${CPE_BASE_URL}/${FEED_VERSION}/${filename}" -o "cpe/${filename}" || true; \
    done; \
    for ext in ${VENDORS_FILE_EXTENSIONS}; do \
      filename="vendorstatements.${ext}"; \
      echo "Downloading ${filename}..."; \
      curl -sSL "${NVD_FEEDS_BASE_URL}/${VENDORS_BASE_URL}/${filename}" -o "vendors/${filename}" || true; \
    done

# --- Step 2 : Create final NGINX image (Chainguard Distroless) ---
FROM cgr.dev/chainguard/nginx:latest

ARG FEED_VERSION

# Copy NGINX configuration for non-root user (65532:65532)
COPY --chown=65532:65532 nginx.conf /etc/nginx/nginx.conf

# Copy CVEs data accessible for non-root user (65532:65532)
COPY --chown=65532:65532 --from=downloader /data/cves /usr/share/nginx/html/feeds/json/cve/${FEED_VERSION}/
COPY --chown=65532:65532 --from=downloader /data/cpematch /usr/share/nginx/html/feeds/json/cpematch/${FEED_VERSION}
COPY --chown=65532:65532 --from=downloader /data/cpe /usr/share/nginx/html/feeds/json/cpe/${FEED_VERSION}
COPY --chown=65532:65532 --from=downloader /data/vendors /usr/share/nginx/html/feeds/xml/cve/misc

# Chainguard is non-root and listen on port 8080
EXPOSE 8080