# README — Kafka (KRaft) over **TLS (SASL\_SSL)** + **SCRAM-SHA-512** with Docker Compose

This step‑by‑step guide shows how to:

1. Clone the project and move to the right folder
2. Create a local **Certificate Authority (CA)**
3. Generate **server certificates** for `broker-1`, `broker-2`, `broker-3` (SANs include Docker hostname + `localhost`)
4. Build **JKS keystores/truststores** as required by the provided `docker-compose.yml`
5. Start **controllers** and **brokers**
6. Create **SCRAM users** (broker, app, etc.)
7. Validate the setup with **KCM** (Kafka Cluster Manager)
8. (Optional) Enable **ACLs** and review troubleshooting tips

> Scope: **Kafka Connect is handled in a separate file**. This README only covers KRaft controllers + brokers secured with TLS and SCRAM.

---

## 0) Prerequisites

* **OpenSSL** and **keytool** available on the host machine

    * If you don’t have `keytool`, you can use a JDK container:

      ```bash
      docker run --rm -v "$PWD:/work" -w /work eclipse-temurin:21-jdk keytool -help
      ```
* **Docker** & **Docker Compose** installed
* (Recommended) **KCM** for testing (runs from the same repository)

Expected structure (created along the steps):

```
./
├─ docker-compose.yml
├─ README.md (this file)
├─ jaas.conf
└─ certificates/
   ├─ ca/
   │  ├─ ca.key
   │  └─ ca.pem
   ├─ broker-1/
   │  ├─ kafka.keystore.jks
   │  ├─ kafka.truststore.jks
   │  └─ (optional) broker-1.key/.csr/.crt
   ├─ broker-2/ ...
   ├─ broker-3/ ...
```

> **Docker network**: ensure the network exists before running compose:
> `docker network create kcm-net`

---

## 1) Quick Start — Clone and go to the compose folder

```bash
# Step 1
git clone https://github.com/etech-data/KCM.git

# Step 2
cd KCM/kafka_brokers_docker_compose
```

From now on, generate certificates inside the local folder **`certificates/`**.

---

## 2) Create the **Root CA**

```bash
mkdir -p certificates/ca
# Private key (RSA 4096)
openssl genrsa -out certificates/ca/ca.key 4096

# Self-signed CA cert (10 years)
openssl req -x509 -new -nodes \
  -key certificates/ca/ca.key \
  -sha256 -days 3650 \
  -subj "/C=FR/O=KCM/CN=KCM-Root-CA" \
  -out certificates/ca/ca.pem
```

> Keep `certificates/ca/ca.key` secret and protected.

---

## 3) Generate **server certificates** for the brokers

Each broker needs:

* a private key + a certificate signed by the CA, with **SANs**:

    * `DNS = broker-N` (Docker hostname used by inter-broker and internal clients)
    * `DNS = localhost` (for clients connecting via `localhost:9493/9593/9693`)
* a **JKS keystore** (`kafka.keystore.jks`) containing the private key + server cert + CA chain
* a **JKS truststore** (`kafka.truststore.jks`) containing the **CA**

Script for `broker-1` → repeat with `HOST=broker-2` and `HOST=broker-3`:

```bash
set -euo pipefail
HOST=broker-1
mkdir -p certificates/$HOST

# 3.1 CSR config (adds SANs)
cat > /tmp/${HOST}-csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = FR
O = KCM
CN = ${HOST}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${HOST}
DNS.2 = localhost
EOF

# 3.2 Key & CSR
openssl genrsa -out certificates/${HOST}/${HOST}.key 2048
openssl req -new -key certificates/${HOST}/${HOST}.key \
  -out certificates/${HOST}/${HOST}.csr \
  -config /tmp/${HOST}-csr.conf

# 3.3 Sign with CA
openssl x509 -req -in certificates/${HOST}/${HOST}.csr \
  -CA certificates/ca/ca.pem -CAkey certificates/ca/ca.key -CAcreateserial \
  -out certificates/${HOST}/${HOST}.crt -days 825 -sha256 \
  -extensions req_ext -extfile /tmp/${HOST}-csr.conf

# 3.4 Build PKCS12 and convert to JKS keystore
#    Example password: changeit (replace in production)
openssl pkcs12 -export \
  -in certificates/${HOST}/${HOST}.crt \
  -inkey certificates/${HOST}/${HOST}.key \
  -certfile certificates/ca/ca.pem \
  -out certificates/${HOST}/${HOST}.p12 \
  -name kafka -passout pass:changeit

keytool -importkeystore \
  -deststorepass changeit \
  -destkeystore certificates/${HOST}/kafka.keystore.jks \
  -srckeystore certificates/${HOST}/${HOST}.p12 \
  -srcstoretype PKCS12 -srcstorepass changeit \
  -alias kafka

# 3.5 Create truststore with the CA
keytool -import -noprompt \
  -alias kcm-ca \
  -file certificates/ca/ca.pem \
  -keystore certificates/${HOST}/kafka.truststore.jks \
  -storepass changeit

chmod 600 certificates/${HOST}/${HOST}.key || true
```

Repeat for `broker-2` and `broker-3`.

---

## 4) **JAAS** file for brokers (inter-broker authentication)

Create `./jaas.conf` at the project root:

```properties
KafkaServer {
  org.apache.kafka.common.security.scram.ScramLoginModule required
  username="broker"
  password="broker-secret";
};
```

> The section name **must** be `KafkaServer`.

---

## 5) Start controllers then brokers

Make sure the following files are present for each broker before starting:

* `certificates/broker-N/kafka.keystore.jks`
* `certificates/broker-N/kafka.truststore.jks`
* `jaas.conf`

```bash
# 5.1 Start the controller quorum
docker compose up -d controller-1 controller-2 controller-3

# 5.2 Start the brokers (they will complain about auth until the SCRAM user "broker" exists)
docker compose up -d broker-1 broker-2 broker-3
```

Check logs (auth errors are expected until users are created):

```bash
docker logs -f broker-1 | sed -n 's/.*\(SASL\|SCRAM\|auth\).*/�/p'
```

---

## 6) Create **SCRAM users** (broker, app)

Run inside a broker container (e.g. `broker-1`):

```bash
docker exec -it broker-1 bash

# 6.1 Inter-broker user "broker"
kafka-configs.sh --bootstrap-server broker-1:9092 \
  --alter --entity-type users --entity-name broker \
  --add-config 'SCRAM-SHA-512=[iterations=4096,password=broker-secret]'

# 6.2 Application user example "app"
kafka-configs.sh --bootstrap-server broker-1:9092 \
  --alter --entity-type users --entity-name app \
  --add-config 'SCRAM-SHA-512=[iterations=4096,password=app-secret]'
exit
```

Once the `broker` user exists, brokers stabilize and the cluster is ready.

---

## 7) Validate with **KCM** (Kafka Control Manager)

Use **KCM** as the testing tool instead of CLI utilities.

1. Launch KCM (refer to the KCM documentation in the repo).
2. In KCM, **add a cluster** with:

    * **Bootstrap servers**: `localhost:9493,localhost:9593,localhost:9693`
    * **Security protocol**: `SASL_SSL`
    * **SASL mechanism**: `SCRAM-SHA-512`
    * **Username/Password**: e.g. `app` / `app-secret` (or any SCRAM user you created)
    * **Trust material**: provide the CA used to sign broker certs (e.g. point KCM to `certificates/ca/ca.pem` or mount it into the KCM container and configure its path)
3. Use KCM to fetch **metadata**, create a **test topic**, and produce/consume a message from the UI to confirm end‑to‑end.

> If KCM runs in Docker, mount the CA:
> `-v "$PWD/certificates/ca/ca.pem:/etc/ssl/certs/kcm-ca.pem:ro"` and configure KCM to trust that file.

---

## 8) (Optional) Enable **ACLs**

Add to broker environment (or `server.properties`) and redeploy:

```properties
authorizer.class.name=org.apache.kafka.metadata.authorizer.StandardAuthorizer
allow.everyone.if.no.acl.found=false
```

Then grant the minimal ACLs for your users using `kafka-acls.sh` (run inside a broker).

---

## Troubleshooting

* **`Authentication failed due to invalid credentials`**
  User missing or wrong password. Inspect users:

  ```bash
  docker exec -it broker-1 bash -lc \
    'kafka-configs.sh --bootstrap-server broker-1:9092 --describe --entity-type users'
  ```
* **Hostname/SAN mismatch**
  Ensure SANs include both **`localhost`** and **`broker-N`**.
* **`No JAAS configuration section named KafkaServer`**
  Wrong section name/path. The section must be **`KafkaServer`** and the file is mounted to `/etc/kafka/jaas.conf` in containers.
* **Invalid truststore / CA not found**
  Import the CA into all truststores and make sure KCM trusts the same CA.

---

## Appendix A — Temporary PLAINTEXT bootstrap (only if you cannot create SCRAM users)

If you’re stuck creating the `broker` user because inter-broker auth loops, you can temporarily expose a **PLAINTEXT** admin listener to create users, then go back to full `SASL_SSL`.

1. Temporarily add to each broker:

   ```properties
   KAFKA_LISTENERS=PLAINTEXT_ADMIN://:9094,SASL_SSL_INTERNAL://:9092,SASL_SSL_HOST://:9493
   KAFKA_ADVERTISED_LISTENERS=PLAINTEXT_ADMIN://broker-1:9094,SASL_SSL_INTERNAL://broker-1:9092,SASL_SSL_HOST://localhost:9493
   KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT_ADMIN:PLAINTEXT,SASL_SSL_INTERNAL:SASL_SSL,SASL_SSL_HOST:SASL_SSL
   ```
2. Start a single broker, create users via port `9094`, then remove the temporary listener and restart all brokers.

> Never leave this listener enabled in production.

---

## Useful broker env summary

```
KAFKA_SASL_ENABLED_MECHANISMS=SCRAM-SHA-512
KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL=SCRAM-SHA-512
KAFKA_INTER_BROKER_LISTENER_NAME=SASL_SSL_INTERNAL
KAFKA_SSL_KEYSTORE_LOCATION=/var/private/ssl/kafka.keystore.jks
KAFKA_SSL_KEYSTORE_PASSWORD=changeit
KAFKA_SSL_TRUSTSTORE_LOCATION=/var/private/ssl/kafka.truststore.jks
KAFKA_SSL_TRUSTSTORE_PASSWORD=changeit
KAFKA_OPTS=-Djava.security.auth.login.config=/etc/kafka/jaas.conf
```

---

**That’s it!** You now have a Kafka (KRaft) cluster encrypted with TLS and authenticated via **SASL/SCRAM-SHA-512**, and you can validate connectivity end‑to‑end using **KCM**. Replace example passwords, adjust cert lifetimes, and tune SANs for your environment.
