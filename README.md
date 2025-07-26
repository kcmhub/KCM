# Kafka Cluster Manager (KCM)

**Kafka Cluster Manager (KCM)** is a full-featured self-hosted solution to manage and monitor Apache Kafka environments through a secure, modern, and intuitive web interface.

> 🔧 Built for developers, DevOps, and SREs looking to simplify Kafka operations.

---

## ✨ Features

* 🔍 Explore topics, consumer groups, and lag in real time
* ⚙️ Manage Kafka Connect connectors
* 🧠 Organize access with role-based permissions
* 🔐 Built-in license system and encryption support
* 📊 Track metrics with Redis & PostgreSQL backends
* 🌐 Modern Angular frontend, fully responsive

---

## 🚀 Quickstart (Docker)

> Requires: Docker + Docker Compose

### 1. Clone the repository

```bash
git clone https://github.com/kafkaetech/kcm-docker.git
cd kcm-docker
```

### 2. Prepare required runtime files

Make sure the following files and folders exist:

```
.
├── runtime-config.json
├── nginx.conf
└── data/
    ├── keys/
    │   ├── private.pem
    │   └── public.pem
    └── files/
```

### 3. Start the stack

```bash
docker-compose up -d
```

### 4. Access the UI

* 🌐 [http://localhost](http://localhost)
* 🔐 Default login: `admin` / `admin` (can be overridden via env variables)

---

## 📆 Docker Images

* **Backend API**
  [`kafkaetech/kcm-api`](https://hub.docker.com/r/kafkaetech/kcm-api)

* **Frontend UI**
  [`kafkaetech/kcm-ui`](https://hub.docker.com/r/kafkaetech/kcm-ui)

---

## 🥉 Requirements

* Running Kafka cluster (self-managed or cloud)
* Optional: Kafka Connect, Schema Registry

---

## 📄 Licensing

KCM includes a built-in licensing mechanism. You can:

* Provide a static license file (`license.json` + `license.sig`)
* Or enable license syncing via Kafka topic (`__kcm_license`)

Need help generating a license? Contact [contact@elite-group.fr](mailto:contact@elite-group.fr)

---

## 📬 Get in Touch

* 🌍 Website: [https://kafkaetech.com](https://kafkaetech.com)
* 💙 GitHub: [https://github.com/kafkaetech](https://github.com/kafkaetech)
* 📧 Email: [contact@elite-group.fr](mailto:contact@elite-group.fr)

---

> 🚀 Made with ❤️ by the ELITE-TECH team
