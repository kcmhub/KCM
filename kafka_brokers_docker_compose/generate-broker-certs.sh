#!/usr/bin/env bash
# Kafka TLS (SASL_SSL) keystores/truststores generator for KRaft brokers.
# - Uses local ./.tmp for temp files (Windows/Git Bash friendly)
# - keytool via local, else Docker, else Podman
# - Disables MSYS path conversion only for the container run (Windows)
set -euo pipefail

CA_COUNTRY="${CA_COUNTRY:-FR}"
CA_ORG="${CA_ORG:-KCM}"
CA_CN="${CA_CN:-KCM-Root-CA}"
CA_DAYS="${CA_DAYS:-3650}"
CERT_DAYS="${CERT_DAYS:-825}"
STOREPASS="${STOREPASS:-changeit}"

if [[ $# -gt 0 ]]; then HOSTS=("$@"); else HOSTS=(broker-1 broker-2 broker-3); fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
CERTS_DIR="certificates"; CA_DIR="$CERTS_DIR/ca"; TMP_DIR="$ROOT/.tmp"

die(){ echo "ERROR: $*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

echo "==> Checking prerequisites"
have openssl || die "openssl not found"

OS_UNAME="$(uname -s)"
MSYS_ENV=() # applied only to containerized keytool on Windows shells
case "$OS_UNAME" in MINGW*|MSYS*|CYGWIN*) MSYS_ENV=(env MSYS2_ARG_CONV_EXCL='*' MSYS_NO_PATHCONV=1);; esac

# Decide keytool runner
if have keytool; then
  echo "==> Using local keytool"
  KT=(keytool)
elif have docker; then
  echo "==> Local keytool not found; using Dockerized keytool (eclipse-temurin:21-jdk)"
  KT=("${MSYS_ENV[@]}" docker run --rm -v "$ROOT:/work" -w /work eclipse-temurin:21-jdk keytool)
elif have podman; then
  echo "==> Local keytool not found; using Podmanized keytool (eclipse-temurin:21-jdk)"
  # NOTE: no :Z on Windows; causes parsing errors. Plain bind mount is fine here.
  KT=("${MSYS_ENV[@]}" podman run --rm -v "$ROOT:/work" -w /work eclipse-temurin:21-jdk keytool)
else
  die "Neither 'keytool' nor 'docker'/'podman' found."
fi
kt(){ "${KT[@]}" "$@"; }

mkdir -p "$CA_DIR" "$TMP_DIR"
trap 'rm -f "$TMP_DIR"/ca.cnf "$TMP_DIR"/broker-*-csr.conf 2>/dev/null || true' EXIT

make_ca(){
  if [[ -f "$CA_DIR/ca.pem" && -f "$CA_DIR/ca.key" ]]; then
    echo "==> CA already exists, skipping: $CA_DIR/ca.pem"; return
  fi
  echo "==> Creating Root CA"
  openssl genrsa -out "$CA_DIR/ca.key" 4096
  cat > "$TMP_DIR/ca.cnf" <<EOF
[ req ]
default_bits       = 4096
prompt             = no
default_md         = sha256
x509_extensions    = v3_ca
distinguished_name = dn
[ dn ]
C  = ${CA_COUNTRY}
O  = ${CA_ORG}
CN = ${CA_CN}
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints     = critical, CA:true
keyUsage             = critical, keyCertSign, cRLSign
EOF
  openssl req -x509 -new -nodes -key "$CA_DIR/ca.key" -sha256 -days "$CA_DAYS" \
    -config "$TMP_DIR/ca.cnf" -out "$CA_DIR/ca.pem"
  echo "==> CA created: $CA_DIR/ca.pem"
}

gen_for_host(){
  local host="$1"; local hdir="$CERTS_DIR/$host"; mkdir -p "$hdir"
  echo "==> Generating key/CSR for $host"
  local csrconf="$TMP_DIR/${host}-csr.conf"
  cat > "$csrconf" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn
[ dn ]
C  = ${CA_COUNTRY}
O  = ${CA_ORG}
CN = ${host}
[ req_ext ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = ${host}
DNS.2 = localhost
IP.1  = 127.0.0.1
EOF
  openssl genrsa -out "$hdir/${host}.key" 2048
  openssl req -new -key "$hdir/${host}.key" -out "$hdir/${host}.csr" -config "$csrconf"

  echo "==> Signing server cert for $host"
  openssl x509 -req -in "$hdir/${host}.csr" -CA "$CA_DIR/ca.pem" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
    -out "$hdir/${host}.crt" -days "$CERT_DAYS" -sha256 -extensions req_ext -extfile "$csrconf"

  echo "==> Building PKCS12 and JKS keystore for $host"
  openssl pkcs12 -export -in "$hdir/${host}.crt" -inkey "$hdir/${host}.key" -certfile "$CA_DIR/ca.pem" \
    -out "$hdir/${host}.p12" -name kafka -passout pass:"$STOREPASS"

  kt -importkeystore -deststorepass "$STOREPASS" -destkeystore "$hdir/kafka.keystore.jks" \
     -srckeystore "$hdir/${host}.p12" -srcstoretype PKCS12 -srcstorepass "$STOREPASS" -alias kafka >/dev/null

  echo "==> Creating truststore (CA) for $host"
  kt -import -noprompt -alias kcm-ca -file "$CA_DIR/ca.pem" \
     -keystore "$hdir/kafka.truststore.jks" -storepass "$STOREPASS" >/dev/null

  chmod 600 "$hdir/${host}.key" || true
  echo "==> Done for $host:"
  echo "    - $hdir/kafka.keystore.jks"
  echo "    - $hdir/kafka.truststore.jks"
}

echo "==> Output directory: $CERTS_DIR"
make_ca
for h in "${HOSTS[@]}"; do gen_for_host "$h"; done

echo
echo "✅ All done."
echo "Next:"
echo "  1) docker network create kcm-net   (if not already)"
echo "  2) docker compose up -d controller-1 controller-2 controller-3"
echo "  3) docker compose up -d broker-1 broker-2 broker-3"
echo "  4) Create SCRAM users (see README step 6)"
