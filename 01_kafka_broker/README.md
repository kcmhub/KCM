# Kafka (KRaft) with Docker Compose: **Starter Project (PLAINTEXT)** 🚀

This folder is a **beginner-friendly starter project** to spin up a **Kafka 4.4 KRaft** cluster over **PLAINTEXT** using Docker Compose (3 controllers + 3 brokers). It is the simplest cluster to try KCM against, and an **initiation to Kafka**: roles (controller vs broker), listeners, advertised listeners, networking, and how client endpoints differ between the host and the containers.

> **Heads-up:** PLAINTEXT is for local/dev only. For a secured cluster, see [`03_kafka_kraft_sasl_ssl`](../03_kafka_kraft_sasl_ssl/README.md).

---

## 1) Prerequisites

* **Docker** or **Podman**
* A Docker network for cross-container DNS (the same one KCM's quick start uses). The "already exists" error is harmless:

```bash
docker network create kcm-net
```

### Who is this for?

* Developers discovering Kafka locally
* DevOps/SREs needing a quick multi-broker lab
* Students preparing to add security (TLS/SASL) later

### Website

* **KCM (Kafka Cluster Manager)**: inspect topics, lags, ACLs, ...

  [https://kcmhub.io](https://kcmhub.io)

Directory layout:

```
./
├─ docker-compose.yml
└─ README.md (this file)
```

---

## 2) Get the files

```bash
git clone https://github.com/kcmhub/KCM.git # or your fork
cd KCM/01_kafka_broker
```

## 3) The compose file

See [`docker-compose.yml`](./docker-compose.yml). What it does:

* **3 controllers** (`controller-1..3`) and **3 brokers** (`broker-1..3`), all on the external network `kcm-net`;
* the image is **pinned to `apache/kafka:4.4.0`** in the compose file (`latest` changes over time, so keep a tag for reproducible setups);
* each broker has two listeners: `PLAINTEXT` (`broker-N:9092`, for containers and inter-broker traffic) and `PLAINTEXT_HOST` (`localhost:9192/9292/9392`, for tools on your host);
* only the `PLAINTEXT_HOST` ports are published, on `127.0.0.1` (`9192:9192`, `9292:9292`, `9392:9392`); controllers publish nothing;
* `KAFKA_LISTENER_SECURITY_PROTOCOL_MAP` maps `PLAINTEXT`, `PLAINTEXT_HOST` and `CONTROLLER` to the PLAINTEXT protocol.

---

## 4) Start the cluster

```bash
docker compose up -d
```

`depends_on` starts the brokers after the controllers. Check the logs:

```bash
docker logs -f broker-1
docker compose logs -f
```

> This example and [`03_kafka_kraft_sasl_ssl`](../03_kafka_kraft_sasl_ssl/README.md) use the **same container names** on `kcm-net`: run **one example at a time** (`docker compose down -v` first).

---

## 5) Client endpoints

From the **host**:

* `localhost:9192` → broker-1 (PLAINTEXT\_HOST)
* `localhost:9292` → broker-2 (PLAINTEXT\_HOST)
* `localhost:9392` → broker-3 (PLAINTEXT\_HOST)

From **containers** on `kcm-net`:

* `broker-1:9092`, `broker-2:9092`, `broker-3:9092` (PLAINTEXT)

> The `PLAINTEXT_HOST` listeners are advertised as `localhost:9x92` for tools running on your host machine.

Quick test with the Kafka CLI from the host (needs a Kafka client, or use a container with `--network host`):

```bash
docker run --rm --network host apache/kafka:4.4.0 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9192,localhost:9292,localhost:9392 --create --topic demo --partitions 3 --replication-factor 3
```

---

## 6) Connect KCM

Start KCM with the quick start in [`00_kcm_with_docker_compose`](../00_kcm_with_docker_compose) (same `kcm-net` network), then add a cluster in KCM with:

* **Bootstrap servers**: `broker-1:9092,broker-2:9092,broker-3:9092`
* **Security protocol**: `PLAINTEXT`

> `localhost:9192,localhost:9292,localhost:9392` only works for tools running directly on your host, not from the KCM container.

---

## Troubleshooting

* **Clients hang or get `Connection to node -1 could not be established`**
  Your `bootstrap servers` may be wrong. Containers use `broker-N:9092`, tools on the host use `localhost:9x92`.

* **`Connection refused` from host**
  Check the port mappings: they must expose the **same** port as the `PLAINTEXT_HOST` listener (`9192:9192`, `9292:9292`, `9392:9392`).

* **Unknown host `broker-N`**
  The `kcm-net` network must exist: `docker network create kcm-net`.

* **Container name already in use**
  Another example (for instance `03_kafka_kraft_sasl_ssl`) is running: `docker compose down -v` in that folder first.

* **Inter-broker communication fails**
  Verify `KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT` and that the `PLAINTEXT` listener is `:9092`, advertised as `broker-N:9092`.

---

## Next steps

* Explore **KCM** to visualize topics, consumer lags, ACLs and more:
  [https://github.com/kcmhub/KCM.git](https://github.com/kcmhub/KCM.git)
* Add **Kafka Connect**, **Schema Registry** and KCM to the same network and point them at the in-network endpoints.

[Next](../03_kafka_kraft_sasl_ssl/README.md) &rarr; Secure the cluster with SASL_SSL and SCRAM-SHA-512
