#!/bin/bash
set -e

CERTIFICATE_FOLDER="nginx/certs"

mkdir -p ${CERTIFICATE_FOLDER}

CA_PRIVATE_KEY_FILE=${CERTIFICATE_FOLDER}/ca-private-key.pem
CA_PUBLIC_KEY_FILE=${CERTIFICATE_FOLDER}/ca-public-key.pem

# Check CA private and public keys
if [ ! -f "${CA_PRIVATE_KEY_FILE}" ]; then

  if [ -z "${CA_PRIVATE_KEY:-}" ]; then
    echo "Missing CA private key (file or env)"
    exit 1
  else
    echo "${CA_PRIVATE_KEY}" > ${CA_PRIVATE_KEY_FILE}
  fi

fi

if [ ! -f "${CA_PUBLIC_KEY_FILE}" ]; then

  if [ -z "${CA_PUBLIC_KEY:-}" ]; then
    echo "Missing CA public key (file or env)"
    exit 1
  else
    echo "${CA_PUBLIC_KEY}" > ${CA_PUBLIC_KEY_FILE}
  fi

fi
# End check

NVD_HOSTNAME="nvd.nist.gov"
EPSS_HOSTNAME="epss.empiricalsecurity.com"


openssl genrsa -out ${CERTIFICATE_FOLDER}/private-key.pem 2048

cat <<EOF > ${CERTIFICATE_FOLDER}/crt-req.cnf
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = req_ext

[req_distinguished_name]
CN = ${NVD_HOSTNAME}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${NVD_HOSTNAME}
DNS.2 = ${EPSS_HOSTNAME}
EOF

openssl req -new -key ${CERTIFICATE_FOLDER}/private-key.pem -out ${CERTIFICATE_FOLDER}/server.csr -config ${CERTIFICATE_FOLDER}/crt-req.cnf

cat <<EOF > ${CERTIFICATE_FOLDER}/v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${NVD_HOSTNAME}
DNS.2 = ${EPSS_HOSTNAME}
EOF

openssl x509 -req -in ${CERTIFICATE_FOLDER}/server.csr \
  -CA ${CA_PUBLIC_KEY_FILE} -CAkey ${CA_PRIVATE_KEY_FILE} -CAcreateserial \
  -out ${CERTIFICATE_FOLDER}/public-key.pem -days 365 -sha256 -extfile ${CERTIFICATE_FOLDER}/v3.ext

# Cleanup temporary files and secrets
rm -f ${CERTIFICATE_FOLDER}/server.csr ${CERTIFICATE_FOLDER}/crt-req.cnf ${CERTIFICATE_FOLDER}/v3.ext ${CERTIFICATE_FOLDER}/ca-*