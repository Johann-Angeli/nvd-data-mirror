ARG NVD_BASE_URL="https://nvd.nist.gov/feeds/json/cve"
ARG FEED_VERSION="2.0"
ARG START_YEAR=2002

FROM alpine:3.19 AS downloader

RUN apk add --no-cache curl bash

ARG NVD_BASE_URL
ARG FEED_VERSION
ARG START_YEAR

WORKDIR /data

# Script pour télécharger les archives JSON (ex: flux annuels ou exports)
# Note : Adapte les URLs selon les flux JSON exacts ciblés
RUN set -e; \
    mkdir -p cves; \
    for year in modified recent $(seq ${START_YEAR} $(date +%Y)); do \
      echo "Téléchargement des CVEs pour ${year}..."; \
      for ext in json.gz json.zip meta; do \
        filename="nvdcve-${FEED_VERSION}-${year}.${ext}"; \
        echo "Téléchargement de ${filename}..."; \
        curl -sSL "${NVD_BASE_URL}/${FEED_VERSION}/${filename}" -o "cves/${filename}" || true; \
      done; \
    done

# --- Étape 2 : Image finale NGINX ---
FROM nginx:alpine

ARG FEED_VERSION

# Copie de la configuration NGINX
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copie des données téléchargées
COPY --from=downloader /data/cves /usr/share/nginx/html/feeds/json/cve/${FEED_VERSION}/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]