# README — Kafka (KRaft) over **TLS (SASL\_SSL)** + **SCRAM-SHA-512** with Docker Compose

This guide has been updated to use the **generator script** that creates the CA and broker certificates in a Windows‑friendly way and falls back to **Docker or Podman** for `keytool` if needed. Validation is done using **KCM**. Kafka Connect is handled in a separate file.

---

## 0) Prerequisites

* **Docker** or **Podman** (only required if you do not have a local `keytool`).
* **OpenSSL** available on the host machine.
* **KCM** to validate the cluster (UI tests).

Directory layout (created along the steps):

```
./
├─ docker-compose.yml
├─ README.md (this file)
├─ generate-broker-certs.sh
├─ jaas.conf
├─ .tmp/                      (temp files, created by the script)
└─ certificates/
   ├─ ca/
   │  ├─ ca.key
   │  └─ ca.pem
   ├─ broker-1/
   │  ├─ kafka.keystore.jks
   │  ├─ kafka.truststore.jks
   │  └─ (optional) broker-1.key/.csr/.crt
   ├─ broker-2/ ...
   └─ broker-3/ ...
```

> **Network:** ensure the Docker network exists before running compose:
> `docker network create kcm-net`

---

## 1) Quick Start

```bash
# Step 1 — clone the repo
git clone https://github.com/etech-data/KCM.git

# Step 2 — go to the compose folder
cd KCM/kafka_brokers_docker_compose

# Step 3 — generate certificates (recommended)
chmod +x generate-broker-certs.sh
./generate-broker-certs.sh                 # ← run with NO arguments (default hosts broker-1..3; default STOREPASS=changeit)
# or customize:
# If you change the keystore/truststore password (STOREPASS), you MUST also update docker-compose:
#   - KAFKA_SSL_KEYSTORE_PASSWORD
#   - KAFKA_SSL_TRUSTSTORE_PASSWORD
# in each broker service to the same value.
# Example:
STOREPASS='yourStrongPass' ./generate-broker-certs.sh
# ...then set in docker-compose.yml (broker-1..3):
# KAFKA_SSL_KEYSTORE_PASSWORD: yourStrongPass
# KAFKA_SSL_TRUSTSTORE_PASSWORD: yourStrongPass
```

The script:

* writes outputs under `./certificates` and uses `./.tmp` for temporary files,
* creates a **Root CA** and signs **server certs** for each broker,
* builds **JKS keystore/truststore** per broker,
* uses local `keytool` if present; otherwise it **automatically runs keytool in a container** using **Docker** (first) or **Podman** (fallback),
* is **Windows/Git Bash friendly** (no path‑mangling issues).

> If an image pull is needed the first run may take a moment (e.g. `eclipse-temurin:21-jdk`).

---

## 2) Broker JAAS (inter‑broker SCRAM + temporary PLAIN admin)

Create `./jaas.conf` at the project root **with both modules**:

```properties
KafkaServer {
  org.apache.kafka.common.security.scram.ScramLoginModule required
  username="broker"
  password="broker-secret";

  org.apache.kafka.common.security.plain.PlainLoginModule required
  username="admin" password="admin-secret"
  user_admin="admin-secret";
};
```

> The SCRAM section is used for inter‑broker auth. The **PLAIN admin** is only for bootstrapping (creating SCRAM users) and should be removed later.

**Broker env reminder (bootstrap):** while you are creating users via the PLAIN admin, make sure brokers allow PLAIN in addition to SCRAM:

```properties
KAFKA_SASL_ENABLED_MECHANISMS=SCRAM-SHA-512,PLAIN
KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL=SCRAM-SHA-512
```

After users are created, revert to `SCRAM-SHA-512` only.

---

## 3) Start controllers & brokers

Make sure these files exist for each broker:

* `certificates/broker-N/kafka.keystore.jks`
* `certificates/broker-N/kafka.truststore.jks`
* `jaas.conf`

Then:

```bash
# Controller quorum
docker compose up -d controller-1 controller-2 controller-3

# Brokers (they will stabilize after the SCRAM user "broker" exists)
docker compose up -d broker-1 broker-2 broker-3
```

---

## 4) Create **SCRAM users** (broker, app) over TLS using the PLAIN admin

> Since the JAAS already contains the temporary `admin` (PLAIN) user and brokers allow `PLAIN` (see Section 2), jump straight to creating the **admin client properties** and run the commands below.

**A) Create `admin.props` (inside a broker container, e.g. `broker-1`)**

```bash
docker exec -it broker-1 bash -lc 'cat >/tmp/admin.props <<EOF
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="admin" password="admin-secret";
ssl.truststore.location=/var/private/ssl/kafka.truststore.jks
ssl.truststore.password=changeit
EOF'
```

**B) Create the SCRAM users via TLS + PLAIN**

```bash
docker exec -it broker-1 bash -lc \
  "/opt/kafka/bin/kafka-configs.sh --bootstrap-server broker-1:9092 \
    --command-config /tmp/admin.props \
    --alter --entity-type users --entity-name broker \
    --add-config 'SCRAM-SHA-512=[iterations=4096,password=broker-secret]'"

docker exec -it broker-1 bash -lc \
  "/opt/kafka/bin/kafka-configs.sh --bootstrap-server broker-1:9092 \
    --command-config /tmp/admin.props \
    --alter --entity-type users --entity-name app \
    --add-config 'SCRAM-SHA-512=[iterations=4096,password=app-secret]'"
```

**C) Revert to SCRAM-only (recommended)**

* Remove `PLAIN` from `KAFKA_SASL_ENABLED_MECHANISMS` (back to `SCRAM-SHA-512` only) for all brokers.
* Keep `KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL=SCRAM-SHA-512`.
* Optionally, remove the `PlainLoginModule` block from `jaas.conf` once bootstrap is complete.
* Recreate brokers:

```bash
docker compose up -d --force-recreate broker-1 broker-2 broker-3
```

---

## 5) Validate with **KCM** (Kafka Control Manager)

Use **KCM** as the testing tool instead of CLI utilities.

In KCM, add a cluster with:

* **Bootstrap servers**: `broker-1:9092,broker-2:9092,broker-3:9092`
* **Security protocol**: `SASL_SSL`
* **SASL mechanism**: `SCRAM-SHA-512`
* **Username/Password**: e.g. `app` / `app-secret`
* **TrustStore**: upload the kafka.truststore.jks file from any broker (e.g. `certificates/broker-1/kafka.truststore.jks`).

---

## 6) (Optional) Enable **ACLs**

Add to broker env (or `server.properties`) and restart:

```properties
authorizer.class.name=org.apache.kafka.metadata.authorizer.StandardAuthorizer
allow.everyone.if.no.acl.found=false
```

Apply ACLs with `kafka-acls.sh` for your principals and topics.

---

## Windows & Podman notes

* The generator script is **Windows‑aware** and avoids Git Bash path conversion problems.
* If you still hit an argument conversion error, try running from **PowerShell** or **WSL**, or prefix a command with:

  ```bash
  MSYS2_ARG_CONV_EXCL='*' MSYS_NO_PATHCONV=1 <your command>
  ```
* On Windows + Podman, the script uses a plain `-v "$PWD:/work"` mount (no `:Z` SELinux flag).

---

## Troubleshooting

* **`Authentication failed due to invalid credentials`**
  The SCRAM user is missing or the password mismatches. Verify users:

  ```bash
  docker exec -it broker-1 bash -lc \
    'kafka-configs.sh --bootstrap-server broker-1:9092 --describe --entity-type users'
  ```
* **Hostname/SAN mismatch**
  SANs must include both **`localhost`** and **`broker-N`** (and `127.0.0.1`).
* **`No JAAS configuration section named KafkaServer`**
  Wrong section name/path. The section must be **`KafkaServer`** and the file is mounted to `/etc/kafka/jaas.conf` in containers.
* **`invalid option type "\Program Files\Git\work;Z"` with Podman**
  The script already avoids `:Z` on Windows. If you changed the run line, remove `:Z` and ensure quotes around `"$PWD:/work"`.
* **OpenSSL subject errors under Git Bash**
  The script doesn’t use `-subj`; it writes config files instead. If you roll your own commands, avoid `-subj` or disable MSYS path conversion.

---

## Appendix M — Manual certificate creation (alternative to the script)

You can still create everything manually (useful for debugging or CI). Summary:

1. **Create CA** (key + self‑signed cert) using an OpenSSL config file.
2. For each broker: generate key + CSR with SANs (`broker-N`, `localhost`, `127.0.0.1`).
3. Sign the CSR with the CA.
4. Build a PKCS#12 bundle and import it into a **JKS keystore** with `keytool`.
5. Import the CA into a **JKS truststore**.

> The generator script automates the exact sequence above and writes to the same locations under `./certificates`.
