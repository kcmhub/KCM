# Kafka 4.4.0 KRaft with SASL_SSL

A local cluster with 1 controller and 3 brokers (racks a, b, c):

- TLS with our own CA, one certificate per node
- SCRAM-SHA-512 for clients and brokers, SASL PLAIN between brokers and controller
- ACLs enforced (StandardAuthorizer), super users: admin, controller, kcm

Demo passwords only: admin-secret, kcm-secret, controller-secret, changeit.
Requirements: Docker with the compose plugin, bash and openssl.

## 1. Network

```bash
./00-network.sh
```

Creates the `kcm-net` Docker network, shared with KCM (nothing happens if it exists).

## 2. Certificates

```bash
./01-certs.sh
```

Creates the CA, one keystore per node (`*.p12`) and `truststore.jks` in `certs/`.
Node private keys are deleted once they are inside the keystores. Only `ca.key` stays (mode 600).

Check the chain and the hostname (SAN) of a broker certificate:

```bash
openssl verify -CAfile certs/ca.crt certs/broker-1.crt
openssl x509 -in certs/broker-1.crt -noout -ext subjectAltName
```

## 3. Format the storage

```bash
./02-format.sh
```

Runs `kafka-storage.sh format` on every node with the same cluster id and creates the
SCRAM users `admin` and `kcm` in the controller metadata.

## 4. Start the cluster

```bash
docker compose up -d
docker compose ps
```

## 5. Use the Kafka CLI

```bash
docker compose run --rm cli
```

You get a shell (`cli $`) with the Kafka tools, `config/` and `certs/` mounted in `/tuto`.

```bash
kafka-metadata-quorum.sh --bootstrap-server broker-1:9092 \
  --command-config /tuto/config/client.properties describe --status

kafka-topics.sh --bootstrap-server broker-1:9092 \
  --command-config /tuto/config/client.properties --list
```

A wrong password is refused. Here the admin password is replaced on the fly in a copy of the config:

```bash
kafka-topics.sh --bootstrap-server broker-1:9092 \
  --command-config <(sed 's/admin-secret/wrong/' /tuto/config/client.properties) --list
```

Type `exit` to leave the shell.

## Layout

| Node         | node.id | Rack   | Listener                     |
|--------------|---------|--------|------------------------------|
| controller-1 | 1       |        | CONTROLLER 9093 (SASL PLAIN) |
| broker-1     | 101     | rack-a | INTERNAL 9092 (SCRAM-512)    |
| broker-2     | 102     | rack-b | INTERNAL 9092 (SCRAM-512)    |
| broker-3     | 103     | rack-c | INTERNAL 9092 (SCRAM-512)    |

Users: admin (brokers and CLI), kcm (for KCM), controller (quorum, PLAIN).

## Connect KCM

Start KCM with the quick start in [`00_kcm_with_docker_compose`](../00_kcm_with_docker_compose): it joins the
same `kcm-net` network, so it reaches the brokers by name. Sign in, create an environment, then add a cluster:

- Bootstrap servers: `broker-1:9092,broker-2:9092,broker-3:9092`
- Security protocol: SASL_SSL, mechanism SCRAM-SHA-512
- Username `kcm`, password `kcm-secret`
- Truststore: upload `certs/truststore.jks`, password `changeit`

## Reset

```bash
./reset.sh
```

Removes the `kcm-tuto` containers and volumes and the generated `certs/`.
