# Kafka (KRaft) with Docker Compose — **Starter Project (PLAINTEXT)**

This repository is a **beginner‑friendly starter project** to spin up a **Kafka KRaft** cluster over **PLAINTEXT** using Docker Compose (3 controllers + 3 brokers). It’s meant as an **initiation to Kafka**: understand roles (controller vs broker), listeners, advertised listeners, networking, and how client endpoints differ between host and containers.

> **Heads‑up:** PLAINTEXT is for local/dev only. For production, use TLS + SASL.

---

## 0) Prerequisites

* **Docker** or **Podman**
* A Docker network for cross‑container DNS:
  `docker network create kcm-net`

### Who is this for?

* Developers discovering Kafka locally
* DevOps/SREs needing a quick multi‑broker lab
* Students preparing to add security (TLS/SASL) later

### Website

* **KCM (Kafka Control Manager)** — inspect topics, lags, ACLs, ...

  [https://kcmhub.io](https://kcmhub.io)

Directory layout (suggested):

```
./
├─ docker-compose.yml
└─ README.md (this file)
```

---

### 0) Checkout the repo

```bash
git clone https://github.com/kcmhub/KCM.git # or your fork
cd KCM/01_kafka_broker
```

## 1) Compose file

The snippet below:

* exposes **host ports 9192/9292/9392** that map to **the same container ports**, so the advertised `PLAINTEXT_HOST` endpoints actually work from the host;
* protocol mapping :  `KAFKA_LISTENER_SECURITY_PROTOCOL_MAP` (adds `PLAINTEXT` + `PLAINTEXT_HOST`);

```yaml
version: '3.9'

networks:
  default:
    external:
      name: kcm-net

services:
  # -------------------------
  # Controllers (KRaft)
  # -------------------------
  controller-1:
    image: apache/kafka:latest
    container_name: controller-1
    ...

  controller-2:
    image: apache/kafka:latest
    container_name: controller-2
    ...

  controller-3:
    image: apache/kafka:latest
    container_name: controller-3
    ...

  # -------------------------
  # Brokers (PLAINTEXT)
  # -------------------------
  broker-1:
    image: apache/kafka:latest
    container_name: broker-1
    ports:
      - "9192:9192"   # PLAINTEXT_HOST (client access from host)
    environment:
      ...
      KAFKA_LISTENERS: PLAINTEXT://:9092,PLAINTEXT_HOST://:9192
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker-1:9092,PLAINTEXT_HOST://localhost:9192
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      ...

  broker-2:
    image: apache/kafka:latest
    container_name: broker-2
    ports:
      - "9292:9292"   # PLAINTEXT_HOST (client access from host)
    environment:
      ...
      KAFKA_LISTENERS: PLAINTEXT://:9092,PLAINTEXT_HOST://:9292
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker-2:9092,PLAINTEXT_HOST://localhost:9292
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      ...

  broker-3:
    image: apache/kafka:latest
    container_name: broker-3
    ports:
      - "9392:9392"   # PLAINTEXT_HOST (client access from host)
    environment:
      ...
      KAFKA_LISTENERS: PLAINTEXT://:9092,PLAINTEXT_HOST://:9392
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker-3:9092,PLAINTEXT_HOST://localhost:9392
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      ...

volumes:
  ...
```

> **Version pinning:** `apache/kafka:latest` changes over time. For reproducible setups, pin to a specific tag (e.g., `apache/kafka:3.9.0`).

---

## 2) Start the cluster

```bash
# Start controller quorum first
docker compose up -d controller-1 controller-2 controller-3

# Then start brokers
docker compose up -d broker-1 broker-2 broker-3
```

Check logs for broker‑1:

```bash
docker logs -f broker-1
```

Check all containers logs:

```bash
docker compose logs -f
```

---

## 3) Client endpoints

From the **host**:

* `localhost:9192` → broker-1 (PLAINTEXT\_HOST)
* `localhost:9292` → broker-2 (PLAINTEXT\_HOST)
* `localhost:9392` → broker-3 (PLAINTEXT\_HOST)

From **containers** on `kcm-net`:

* `broker-1:9092`, `broker-2:9092`, `broker-3:9092` (PLAINTEXT)

> The `PLAINTEXT_HOST` listeners are advertised as `localhost:9x92` for tools running on your host machine.

---

## 4) Validate with **KCM** (Kafka Control Manager)

Add a cluster in **KCM** with:

* **Bootstrap servers**: `localhost:9192,localhost:9292,localhost:9392` (from host) 
* **Security protocol**: `PLAINTEXT`

> For in‑network containers (same `kcm-net`), use `broker-1:9092,broker-2:9092,broker-3:9092`.
> You should use those endpoints if you already followed steps at [00_kcm_with_docker_compose](../README.md) to run KCM in a container.

---

## Troubleshooting

* **Clients hang or get `Connection to node -1 could not be established`**
  Your `bootstrap servers` may be wrong. Ensure each broker advertises its own DNS (`broker-N:9092`) for internal traffic and `localhost:9x92` for host traffic.

* **`Connection refused` from host**
  Check port mappings: they must expose the **same** container port as in `PLAINTEXT_HOST` (`9192:9092`, `9292:9092`, `9392:9092`).

* **Duplicate container names**
  e.g: Ensure `container_name` for `broker-2` is `broker-2` (not `broker-1`).

* **Unknown host `broker-N`**
  The `kcm-net` network must exist: `docker network create kcm-net`.

* **Inter‑broker communication fails**
  Verify `KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT` and that the `PLAINTEXT` listener is defined as `:9092` and advertised as `broker-N:9092`.

---

## Next steps

* Explore **KCM** (Kafka Control Manager) to visualize topics, consumer lags, ACLs and more:
  [https://github.com/kcmhub/KCM.git](https://github.com/kcmhub/KCM.git)
* Switch to **TLS + SASL** for realistic environments (use our secured compose as a follow‑up).
* Add **Kafka Connect**, **Schema Registry**, and your **KCM API/UI** services to the same network and point them at the brokers’ in‑network endpoints.

[next](../02_security_kafka_with%20sasl/README.md) &rarr; Secure Kafka with TLS + SASL (SCRAM)