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

| Variable                  | Default                 | Description                                                       |
| ------------------------- | ----------------------- | ----------------------------------------------------------------- |
| `KCM_ENCRYPT_PRIVATE_KEY` | `/app/keys/private.pem` | Path to the private key used for data encryption / decryption.    |
| `KCM_ENCRYPT_PUBLIC_KEY`  | `/app/keys/public.pem`  | Path to the public key used for data encryption where applicable. |

### 🔸 JWT configuration

| Variable                   | Default                 | Description                                                              |
| -------------------------- | ----------------------- | ------------------------------------------------------------------------ |
| `KCM_JWT_ISSUER`           | `kcm`                   | Issuer (`iss`) claim used when generating JWT access tokens.             |
| `KCM_JWT_PERSISTENCE_MODE` | `JDBC`                  | Persistence strategy for JWT tokens (e.g. `JDBC`, `REDIS` if supported). |
| `KCM_JWT_TOKEN_VALIDITY`   | `86400`                 | JWT token validity period in seconds.                                    |
| `KCM_JWT_PRIVATE_KEY`      | `/app/keys/private.pem` | Private key used to sign JWT tokens.                                     |
| `KCM_JWT_PUBLIC_KEY`       | `/app/keys/public.pem`  | Public key used to validate JWT signatures.                              |

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
* 🌍 [Official Website](https://www.kcmhub.io)
* 📁 [Repository](https://github.com/kcmhub/KCM)

---

## 🤝 Contributing / Feedback

You can open issues or feedback directly on our GitHub repo. We also welcome feature suggestions, bug reports, and license requests.

📮 For private requests or free license keys, please contact [contact@kcmhub.io](mailto:contact@kcmhub.io).

---

**© 2024-2025 ELITE-TECH. All rights reserved.**
