# Kafka Cluster Manager (KCM) 🧠📊

Kafka Cluster Manager (KCM) is a lightweight DevOps-oriented platform to **monitor, manage and interact with Apache Kafka clusters** via a modern UI and powerful REST API.

KCM helps teams gain insights, visibility, and control over Kafka environments.

---

## 🚀 Quickstart with Docker Compose

```bash
git clone https://github.com/kcmhub/KCM.git
cd KCM/00_kcm_with_docker_compose
docker network create kcm-net
docker compose up -d
```

Access:

* 🖥️ UI: [http://localhost](http://localhost)

At the first start the API generates its two key pairs in `00_kcm_with_docker_compose/data/keys` (`jwt/` signs the
sessions, `encryption/` protects the secrets stored in the database). Back up this directory with the database, and
never share it. Set `KCM_DEFAULT_PASSWORD` before the first start, or change the `admin` password right away.

### ⚠️ Upgrade from 1.2.0 or earlier: regenerate the keys and change your secrets

Up to 1.2.0 this repository shipped a key pair in `data/keys` (`private.pem` / `public.pem`), used both to sign
the sessions and to encrypt the stored secrets. **That pair is public: consider it compromised.** Anyone could sign
a session accepted by an install that used it. From 1.2.1 the API refuses to start with it as JWT pair.

1. Update this repository (`git pull`) and keep your `data/keys/private.pem` where it is for now.
2. `docker compose pull && docker compose up -d`. At startup the API:
   * generates two new pairs in `data/keys/jwt` and `data/keys/encryption`;
   * reads the old pair through `KCM_ENCRYPT_PREVIOUS_PRIVATE_KEY` and re-encrypts every stored secret with the new
     encryption pair (log line `Key change: N secret(s) re-encrypted with the current key`).

   Every user signs in again (sessions signed with the old key are refused).
3. Check the API log (`docker logs kcm-api`): no line `secret(s) in ... encrypted with another key`.
4. Delete the old pair: `data/keys/private.pem` and `data/keys/public.pem`.
5. **Change the secrets stored in KCM at their source**, then enter them again in KCM: Kafka SASL passwords and
   JAAS configurations, Schema Registry, Kafka Connect and ksqlDB credentials, SSO client secrets, Git and
   Confluent Cloud credentials. With the old public key, anyone holding a copy of the database could read them.
6. Change the `admin` password if it is still the default one.

If your `docker-compose.yml` is a modified copy, apply the changes of the environment section below
(`KCM_KEYS_GENERATE_IF_MISSING`, `KCM_JWT_*`, `KCM_ENCRYPT_*`, `KCM_ENCRYPT_PREVIOUS_PRIVATE_KEY`) and mount
`./data/keys` writable (no `:ro`).

---

## ☸️ Kubernetes with Helm

The Helm chart is a public OCI artifact on Docker Hub: `oci://registry-1.docker.io/kafkaetech/kcm` (chart version = KCM version, Helm 3.8+).

```bash
# JWT key pair of the API, created once before the install
mkdir -p keys
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out keys/private.pem
openssl pkey -in keys/private.pem -pubout -out keys/public.pem
kubectl create namespace kcm
kubectl -n kcm create secret generic kcm-api-keys --from-file=keys

# KCM with the embedded PostgreSQL and Redis
helm upgrade --install kcm oci://registry-1.docker.io/kafkaetech/kcm --version 1.2.0 -n kcm   --set ingress.host=kcm.example.com   --set ui.runtimeConfig.apiUrl=http://kcm.example.com   --set ui.runtimeConfig.wsUrl=ws://kcm.example.com   --set postgres.enabled=true --set redis.enabled=true
```

The chart has no default password: the `admin` password is generated at install, `helm install` prints the command to read it. Every value is documented by `helm show values oci://registry-1.docker.io/kafkaetech/kcm --version 1.2.0`; the environment variables below go under `api.env` (the passwords under `api.secret`).

---

## ⚙️ Configuration via Environment Variables

KCM can be fully configured via environment variables. The values below are the defaults used by the **production profile** when no value is provided.

### 🔸 Core application & security

| Variable                     | Default                 | Description                                                                                                                                                                                                       |
| ---------------------------- | ----------------------- |-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `KCM_APP_PORT`               | `9090`                  | HTTP port used by the KCM API inside the container.                                                                                                                                                               |
| `KCM_COOKIE_NAME`            | `KCM_AT`                | Name of the authentication cookie that stores the access token.                                                                                                                                                   |
| `KCM_COOKIE_DOMAIN`          | ``                      | Cookie domain. Example: `.kcmhub.io` when UI and API run on subdomains.                                                                                                                                           |
| `KCM_COOKIE_MAX_AGE_SECONDS` | `86400`                 | Lifetime of the authentication cookie in seconds.                                                                                                                                                                 |
| `KCM_REDIRECT_ALLOWLIST`     | `http://localhost:4200` | Comma-separated list of allowed **redirect origins** after login (format: `scheme://host[:port]`, no trailing slash). Paths are ignored during validation. Example: `https://app.kcmhub.io,http://localhost:4200` |
| `KCM_DEFAULT_REDIRECT`       | `http://localhost:4200` | Default post-login/logout redirect URL (should be one of the allowed origins or a safe same-origin path).                                                                                                         |
| `KCM_DEFAULT_USER_ENABLED`   | `true`                  | Whether to enable the built-in default admin user (intended for first setup or demos only).                                                                                                                       |
| `KCM_DEFAULT_PASSWORD`       | `admin`                 | Password of the default admin user when it is enabled.                                                                                                                                                            |

### 🔸 License management

| Variable                     | Default                    | Description                                                                                                               |
| ---------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `KCM_LICENSE_PATH`           | `/license/license.json`    | Path to the KCM license JSON file (typically mounted from the host, e.g. `/app/license`).                                 |
| `KCM_LICENSE_KAFKA_TOPIC`    | `__kcm_license`            | Kafka topic used to distribute license information across KCM instances.                                                  |
| `KCM_LICENSE_SIGNATURE_PATH` | `/license/license.sig`     | Path to the detached signature file used to verify license integrity.                                                     |
| `KCM_LICENSE_HISTORY_DIR`    | `/license/license-history` | Directory where license activation / usage history is stored.                                                             |
| `KCM_LICENSE_CRL_PATH`       | ``                         | Optional path to the license Certificate Revocation List (CRL). If set, CRL is used to check revoked or invalid licenses. |

### 🔸 Encryption keys

| Variable                           | Default (compose)                  | Description                                                                                                                                                                         |
| ---------------------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `KCM_KEYS_GENERATE_IF_MISSING`     | `true` (application: `false`)      | Since 1.2.1. Generates a missing JWT or encryption key pair at startup. An existing file is never replaced; a pair with only one of its two files stops the startup.                  |
| `KCM_ENCRYPT_PRIVATE_KEY`          | `/app/keys/encryption/private.pem` | Private key (PKCS#8 PEM) decrypting the secrets stored in the database. Distinct from the JWT pair since 1.2.1.                                                                       |
| `KCM_ENCRYPT_PUBLIC_KEY`           | `/app/keys/encryption/public.pem`  | Public key (X.509 PEM) encrypting the secrets stored in the database.                                                                                                                |
| `KCM_ENCRYPT_PREVIOUS_PRIVATE_KEY` | `/app/keys/private.pem` (application: empty) | Since 1.2.1. Private key of the previous encryption pair: the secrets it encrypted are still read and re-encrypted with the current pair at startup. Ignored when the file does not exist. |

### 🔸 JWT configuration

| Variable                   | Default                 | Description                                                              |
| -------------------------- | ----------------------- | ------------------------------------------------------------------------ |
| `KCM_JWT_ISSUER`           | `kcm`                   | Issuer (`iss`) claim used when generating JWT access tokens.             |
| `KCM_JWT_PERSISTENCE_MODE` | `JDBC`                  | Persistence strategy for JWT tokens (e.g. `JDBC`, `REDIS` if supported). |
| `KCM_JWT_TOKEN_VALIDITY`   | `86400`                 | JWT token validity period in seconds.                                    |
| `KCM_JWT_PRIVATE_KEY`      | `/app/keys/jwt/private.pem` | Private key used to sign JWT tokens (distinct from the encryption pair since 1.2.1). |
| `KCM_JWT_PUBLIC_KEY`       | `/app/keys/jwt/public.pem`  | Public key used to validate JWT signatures.                              |

### 🔸 File storage

| Variable             | Default | Description                                                                         |
| -------------------- | ------- | ----------------------------------------------------------------------------------- |
| `KCM_APP_FILES_PATH` | `/data` | Base directory for file storage (uploads, exports, temporary files) inside the app. |

### 🔸 PostgreSQL database

| Variable                           | Default                            | Description                                                              |
| ---------------------------------- | ---------------------------------- | ------------------------------------------------------------------------ |
| `KCM_DB_URL`                       | `jdbc:postgresql://db:5432/kcm_db` | JDBC URL for the PostgreSQL database.                                    |
| `KCM_DB_USER`                      | `kcm_user`                         | PostgreSQL username.                                                     |
| `KCM_DB_PWD`                       | `kcm_password`                     | PostgreSQL password.                                                     |
| `KCM_DB_HIKARI_MAX_POOL_SIZE`      | `20`                               | Maximum number of connections in the HikariCP connection pool.           |
| `KCM_DB_HIKARI_MIN_IDLE`           | `5`                                | Minimum number of idle connections in the pool.                          |
| `KCM_DB_HIKARI_IDLE_TIMEOUT`       | `600000`                           | Time in milliseconds before an idle connection is removed from the pool. |
| `KCM_DB_HIKARI_CONNECTION_TIMEOUT` | `30000`                            | Maximum time in milliseconds to wait for a connection from the pool.     |
| `KCM_DB_HIKARI_MAX_LIFETIME`       | `1800000`                          | Maximum lifetime in milliseconds of a connection in the pool.            |
| `KCM_DB_HIKARI_POOL_NAME`          | `KCMHikariCP`                      | Name of the HikariCP connection pool.                                    |

### 🔸 Redis cache

| Variable                  | Default | Description                                                            |
| ------------------------- | ------- | ---------------------------------------------------------------------- |
| `KCM_REDIS_CLUSTER_NODES` | ``      | Optional Redis cluster nodes definition (comma-separated `host:port`). |
| `KCM_REDIS_HOST`          | `redis` | Redis hostname.                                                        |
| `KCM_REDIS_PORT`          | `6379`  | Redis port.                                                            |
| `KCM_REDIS_DB`            | `0`     | Redis database index used by KCM.                                      |
| `KCM_REDIS_TIMEOUT`       | `2000`  | Redis connection timeout in milliseconds.                              |

### 🔸 Kafka admin client

| Variable              | Default           | Description                                         |
| --------------------- | ----------------- | --------------------------------------------------- |
| `KCM_ADMIN_CLIENT_ID` | `kc-admin-client` | Kafka `client.id` used by KCM for admin operations. |

### 🔸 Connector status history (since 1.1.0)

KCM samples the status of every connector and task of each Kafka Connect cluster and keeps the history (status history tab of a connector, availability column of the connectors list).

| Variable                                      | Default         | Description                                                                 |
| --------------------------------------------- | --------------- | --------------------------------------------------------------------------- |
| `KCM_CONNECT_STATUS_HISTORY_ENABLED`          | `true`          | Enables the sampling and the history.                                        |
| `KCM_CONNECT_STATUS_HISTORY_CRON`             | `0 2/5 * * * *` | Sampling schedule (Spring cron, 6 fields).                                   |
| `KCM_CONNECT_STATUS_HISTORY_INTERVAL_SECONDS` | `300`           | Sampling period in seconds. Keep it equal to the period of the cron above.  |
| `KCM_CONNECT_STATUS_HISTORY_RETENTION_DAYS`   | `30`            | Number of days the history is kept.                                          |

### 🔸 AI assistant, beta (since 1.1.0)

Analysis of a consumer group with a local model served by [Ollama](https://ollama.com). Disabled by default. While it is enabled, run a single kcm-api instance (analyses are kept in memory).

| Variable                        | Default                  | Description                                                   |
| ------------------------------- | ------------------------ | ------------------------------------------------------------- |
| `KCM_ASSISTANT_ENABLED`         | `false`                  | Enables the assistant.                                        |
| `KCM_ASSISTANT_OLLAMA_URL`      | `http://localhost:11434` | Ollama URL, reachable from the kcm-api container.             |
| `KCM_ASSISTANT_MODEL`           | `gemma3:4b`              | Model used for the analysis (must be pulled in Ollama).       |
| `KCM_ASSISTANT_TIMEOUT_SECONDS` | `120`                    | Maximum duration of one call to the model, in seconds.        |

---

## 📦 Docker Images

| Service  | Image                                                               |
| -------- | ------------------------------------------------------------------- |
| Backend  | [`kafkaetech/kcm-api`](https://hub.docker.com/r/kafkaetech/kcm-api) |
| Frontend | [`kafkaetech/kcm-ui`](https://hub.docker.com/r/kafkaetech/kcm-ui)   |
| Helm chart | [`kafkaetech/kcm`](https://hub.docker.com/r/kafkaetech/kcm) (`oci://registry-1.docker.io/kafkaetech/kcm`) |

---

## 🔐 License

This project is **not open source**. It is licensed under a **Proprietary Evaluation License**.

* 🛠️ Free for **non-commercial evaluation**.
* 🚫 **Commercial use** requires a paid [license](https://kcmhub.io/pricing.html).
* 📬 Questions? Contact **[contact@kcmhub.io](mailto:contact@kcmhub.io)**.
* 🎓 **Students** may receive a **free 6-month license** by emailing a valid student ID to the same address.

See [`LICENSE.txt`](./LICENSE.txt) for full terms.

---

## 📬 Links

* 🔗 [UI Docker Image](https://hub.docker.com/r/kafkaetech/kcm-ui)
* 🔗 [API Docker Image](https://hub.docker.com/r/kafkaetech/kcm-api)
* 🔗 [Helm chart](https://hub.docker.com/r/kafkaetech/kcm)
* 🌍 [Official Website](https://www.kcmhub.io)
* 📁 [Repository](https://github.com/kcmhub/KCM)

---

## 🤝 Contributing / Feedback

You can open issues or feedback directly on our GitHub repo. We also welcome feature suggestions, bug reports, and license requests.

📮 For private requests or free license keys, please contact [contact@kcmhub.io](mailto:contact@kcmhub.io).

---

**© 2024-2025 ELITE-TECH. All rights reserved.**
