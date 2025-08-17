# Kafka Cluster Manager (KCM) 🧠📊

Kafka Cluster Manager (KCM) is a lightweight DevOps-oriented platform to **monitor, manage and interact with Apache Kafka clusters** via a modern UI and powerful REST API.

Built with **Spring Boot 3**, **Angular**, **PostgreSQL**, and **Redis**, KCM helps teams gain insights, visibility, and control over Kafka environments.

---

## 🚀 Quickstart with Docker Compose

```bash
git clone https://github.com/etech-data/KCM.git
cd KCM/kcm_with_docker_compose
docker network create kcm-net
docker compose up -d
```

Access:

* 🖥️ UI: [http://localhost](http://localhost)

---

## ⚙️ Configuration via Environment Variables

You can override defaults using a `.env` file or directly in your environment.

| Variable                     | Default                            | Description                                 |
| ---------------------------- | ---------------------------------- | ------------------------------------------- |
| `KCM_APP_NAME`               | `kcm-manager`                      | Application name                            |
| `KCM_DEFAULT_USER_ENABLED`   | `true`                             | Enable default user                         |
| `KCM_DEFAULT_PASSWORD`       | `admin`                            | Default user password                       |
| `KCM_LICENSE_PATH`           | `/license/license.json`            | Path to license JSON                        |
| `KCM_LICENSE_KAFKA_TOPIC`    | `__kcm_license`                    | Kafka topic used to distribute license info |
| `KCM_LICENSE_SIGNATURE_PATH` | `/license/license.sig`             | Path to license signature                   |
| `KCM_LICENSE_HISTORY_DIR`    | `/license/license-history`         | Directory to store license usage history    |
| `KCM_ENCRYPT_PRIVATE_KEY`    | `/app/keys/private.pem`            | Private key path for encryption             |
| `KCM_ENCRYPT_PUBLIC_KEY`     | `/app/keys/public.pem`             | Public key path for encryption              |
| `KCM_JWT_PERSISTENCE_MODE`   | `JDBC`                             | JWT persistence method                      |
| `KCM_JWT_TOKEN_VALIDITY`     | `86400`                            | JWT token validity in seconds               |
| `KCM_JWT_PRIVATE_KEY`        | `/app/keys/private.pem`            | JWT private key path                        |
| `KCM_JWT_PUBLIC_KEY`         | `/app/keys/public.pem`             | JWT public key path                         |
| `KCM_APP_FILES_PATH`         | `/data`                            | Default file storage path                   |
| `KCM_DB_URL`                 | `jdbc:postgresql://db:5432/kcm_db` | PostgreSQL JDBC URL                         |
| `KCM_DB_USER`                | `kcm_user`                         | PostgreSQL user                             |
| `KCM_DB_PWD`                 | `kcm_password`                     | PostgreSQL password                         |
| `KCM_ADMIN_CLIENT_ID`        | `kc-admin-client`                  | Kafka admin client ID                       |
| `KCM_REDIS_HOST`             | `redis`                            | Redis hostname                              |
| `KCM_REDIS_PORT`             | `6379`                             | Redis port                                  |

---

## 📦 Docker Images

| Service  | Image                                                               |
| -------- | ------------------------------------------------------------------- |
| Backend  | [`kafkaetech/kcm-api`](https://hub.docker.com/r/kafkaetech/kcm-api) |
| Frontend | [`kafkaetech/kcm-ui`](https://hub.docker.com/r/kafkaetech/kcm-ui)   |

---

## 🔐 License

This project is **not open source**. It is licensed under a **Proprietary Evaluation License**.

* 🛠️ Use is free for non-commercial evaluation
* 🚫 Commercial use requires a license
* 📬 Contact us: [contact@elite-group.fr](mailto:contact@elite-group.fr) to request your free evaluation license

See [`LICENSE.txt`](./LICENSE.txt) for full terms.

---

## 📬 Links

* 🔗 [UI Docker Image](https://hub.docker.com/r/kafkaetech/kcm-ui)
* 🔗 [API Docker Image](https://hub.docker.com/r/kafkaetech/kcm-api)
* 🌍 [Official Website](https://www.kcmhub.io)
* 📁 [Repository](https://github.com/etech-data/KCM)

---

## 🤝 Contributing / Feedback

You can open issues or feedback directly on our GitHub repo. We also welcome feature suggestions, bug reports, and license requests.

📮 For private requests or free license keys, please contact [contact@elite-group.fr](mailto:contact@elite-group.fr).

---

**© 2024-2025 ELITE-TECH. All rights reserved.**
