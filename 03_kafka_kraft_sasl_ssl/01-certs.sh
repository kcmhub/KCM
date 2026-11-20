#!/bin/bash
# Own CA + one certificate per node (SAN = hostname), run from this folder
set -e
cd "$(dirname "$0")"
mkdir -p certs && cd certs
PASS=changeit

# Run a command silently, show its output only if it fails
quiet() { local out; out=$("$@" 2>&1) || { echo "$out" >&2; return 1; }; }

# 1. Certificate authority
quiet openssl req -x509 -newkey rsa:2048 -nodes -days 825 \
  -keyout ca.key -out ca.crt -subj "/CN=Tuto Kafka CA"
echo "CA created: ca.crt (public) and ca.key (private)"

# 2. One keystore per node, signed by the CA
for node in controller-1 broker-1 broker-2 broker-3; do
  quiet openssl req -newkey rsa:2048 -nodes -keyout $node.key -out $node.csr \
    -subj "/CN=$node"
  quiet openssl x509 -req -in $node.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 825 -out $node.crt \
    -extfile <(printf "subjectAltName=DNS:$node,DNS:localhost")
  quiet openssl pkcs12 -export -in $node.crt -inkey $node.key -certfile ca.crt \
    -name $node -out $node.p12 -passout pass:$PASS
  echo "$node: certificate signed, keystore $node.p12"
done

# 3. Truststore with the CA only (JKS, keytool runs inside the Kafka image)
rm -f truststore.jks
quiet docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/certs -w /certs \
  --entrypoint keytool apache/kafka:4.4.0 \
  -importcert -noprompt -alias ca -file ca.crt \
  -keystore truststore.jks -storetype JKS -storepass $PASS
echo "truststore.jks: contains the CA only"

# Keep only the CA key: node private keys now live inside the keystores
rm -f *.csr *.srl *.crt.tmp controller-1.key broker-?.key
chmod 600 ca.key
chmod 644 *.p12 *.jks
echo "Done. Private keys removed, only ca.key is kept (mode 600)."
