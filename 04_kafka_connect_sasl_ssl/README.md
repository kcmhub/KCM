# Kafka Connect 4.4.0 on a SASL_SSL cluster

A Connect cluster of 2 workers (distributed mode) on the SASL_SSL KRaft cluster of
[`03_kafka_kraft_sasl_ssl`](../03_kafka_kraft_sasl_ssl), with least privilege everywhere:

- One SCRAM user for the workers (`connect`) and one user per connector (`file-source`, `file-sink`)
- ACLs limited to what each principal needs, nothing more
- Basic auth on the Connect REST API
- Connector passwords read from files (`${file:...}`), never stored in the connector config

Demo passwords only: connect-secret, file-source-secret, file-sink-secret, kcm-connect-secret.
Requirements: Docker with the compose plugin, bash, curl, and the cluster of tutorial 03 up and running
(its `certs/` folder is reused).

## 1. Prepare

```bash
./00-prepare.sh
```

Checks that the `kcm-net` network and the tutorial 03 certificates exist, and creates `data/`,
the folder shared by the 2 workers (mounted on `/data`).

## 2. Users

```bash
./01-users.sh
```

Runs the Kafka CLI as `admin` to create the SCRAM-SHA-512 users `connect` (the workers), `file-source` and
`file-sink` (one per connector). In KCM: Security > Add Kafka user, and pick the mechanism `SCRAM_SHA_512`.

## 3. Topics

```bash
./02-topics.sh
```

Creates the internal topics `connect-configs`, `connect-offsets`, `connect-status` (compacted, replication factor 3)
and the data topic `demo-lines` (3 partitions, replication factor 3).
The workers do not need the CREATE permission, the admin creates the topics.

## 4. Start the workers without ACLs

```bash
docker compose up -d
docker logs kcm-tuto-connect-1 2>&1 | grep -A1 ERROR
```

The workers authenticate fine, but the user `connect` has no right yet:

```
ERROR [Worker clientId=connect-connect-1:8083, groupId=connect-cluster] Uncaught exception in herder work thread, exiting:
org.apache.kafka.common.errors.TopicAuthorizationException: Not authorized to access topics: [connect-offsets]
```

The worker exits and Docker restarts it again and again.

## 5. ACLs

```bash
./03-acls.sh
docker compose restart
```

| Principal   | Resource                                               | Pattern  | Operations  | Why                              |
|-------------|--------------------------------------------------------|----------|-------------|----------------------------------|
| connect     | Topic connect-configs, connect-offsets, connect-status | literal  | Read, Write | internal state of the cluster    |
| connect     | Group connect-cluster                                  | prefixed | Read        | the workers form one group       |
| file-source | Topic demo-lines                                       | literal  | Write       | the source produces the lines    |
| file-sink   | Topic demo-lines                                       | literal  | Read        | the sink consumes the lines      |
| file-sink   | Group connect-file-sink                                | prefixed | Read        | consumer group of the sink task  |

`connect` has no access to `demo-lines`: each connector runs with its own principal.

The 2 group ACLs are prefixed because the groups do not exist yet when the ACLs are created, and KCM only offers
existing groups for a literal group ACL. A prefixed ACL on `connect-cluster` covers the names that start with
`connect-cluster`. With the CLI only, `--resource-pattern-type literal` works too.

Not needed: CREATE (topics exist), Describe on the cluster, IdempotentWrite for the source.
Optional: Describe configs on the 3 internal topics. Without it the worker only logs an INFO line saying it
cannot verify that they are compacted.

In KCM: Security > the user > Edit ACLs, one ACL per operation (Host `*`), then Save.

## 6. The REST API is protected

```bash
curl -i localhost:8083/connectors
curl -i -u kcm:wrong localhost:8083/connectors
curl -i -u kcm:kcm-connect-secret localhost:8083/connectors
```

`401` twice, then `200` with `[]`. The workers listen on `127.0.0.1` only: 8083 for connect-1, 8084 for connect-2.
The account is defined in `secrets/rest-credentials.properties`, the login module in `config/connect-jaas.conf`.

## 7. Create the connectors

The passwords are in `secrets/`. The connector config only holds a placeholder.
Create the source through connect-1 and the sink through connect-2: a worker that is not the leader forwards the
request to the leader, and Basic auth keeps working.

```bash
curl -u kcm:kcm-connect-secret -X POST -H "Content-Type: application/json" \
  -d @connectors/file-source.json localhost:8083/connectors

curl -u kcm:kcm-connect-secret -X POST -H "Content-Type: application/json" \
  -d @connectors/file-sink.json localhost:8084/connectors
```

Check the state and that the password is not exposed:

```bash
curl -s -u kcm:kcm-connect-secret localhost:8083/connectors?expand=status
curl -s -u kcm:kcm-connect-secret localhost:8083/connectors/file-source/config
```

You should see `RUNNING`, and in the config the placeholder `${file:/secrets/file-source.properties:password}` instead of the password.

The sink also has `admin.override.sasl.jaas.config`: without it, `GET /connectors/file-sink/offsets` fails, because the
admin client of the worker would use the user `connect`, which cannot read the group `connect-file-sink`.

## 8. Test the flow

```bash
echo "hello kafka connect" >> data/input.txt
echo "second line" >> data/input.txt
sleep 5
cat data/output.txt
```

`file-source` writes the lines of `input.txt` to `demo-lines`, `file-sink` writes them to `output.txt`.
Check the topic and the consumer group with the CLI:

```bash
docker compose run --rm cli
```

```bash
kafka-console-consumer.sh --bootstrap-server broker-1:9092 \
  --command-config /tuto/config/client.properties --topic demo-lines --from-beginning --timeout-ms 5000

kafka-consumer-groups.sh --bootstrap-server broker-1:9092 \
  --command-config /tuto/config/client.properties --describe --group connect-file-sink
```

The final `TimeoutException` is just the end of the 5 second wait. The sink commits its offsets every minute,
so `CURRENT-OFFSET` shows `-` at first.

Type `exit` to leave the shell.

## 9. Lose a worker

Find where the connectors run, then stop that worker (here connect-2):

```bash
curl -s -u kcm:kcm-connect-secret localhost:8083/connectors?expand=status
docker stop kcm-tuto-connect-2
```

Poll through the other worker:

```bash
curl -s -u kcm:kcm-connect-secret localhost:8083/connectors?expand=status
```

With `scheduled.rebalance.max.delay.ms=10000` the leader waits 10 seconds for the worker to come back before it
moves its connectors (the default is 5 minutes). Measured here: about 12 seconds after `docker stop` was issued
when the stopped worker was not the leader, about 2 seconds when it was the leader (a new leader reassigns at once).
If the container is killed instead of stopped, add the 10 seconds of the session timeout.
Start it again:

```bash
docker start kcm-tuto-connect-2
```

The workers rebalance when it joins: a connector can move back to it. Lines appended to `data/input.txt`
during the failover reach `output.txt` anyway.

## Layout

| Container          | Host port      | Role                                  |
|--------------------|----------------|---------------------------------------|
| kcm-tuto-connect-1 | 127.0.0.1:8083 | Connect worker, REST + Basic auth     |
| kcm-tuto-connect-2 | 127.0.0.1:8084 | Connect worker, REST + Basic auth     |

Users: connect (workers), file-source, file-sink (connectors), kcm (REST API, Basic auth only, not a Kafka user).
Cluster: the brokers of tutorial 03 on `kcm-net` (`broker-1:9092` ...).

## Connect KCM

Start KCM with the quick start in [`00_kcm_with_docker_compose`](../00_kcm_with_docker_compose) and add the
Kafka cluster as in tutorial 03. Then add a Connect cluster to it:

- Connect URL: `http://connect-1:8083`
- Basic auth: username `kcm`, password `kcm-connect-secret`
- Internal topics: `connect-configs`, `connect-offsets`, `connect-status`

KCM talks to the worker of that URL, which forwards to the leader when needed. If that worker is down, KCM cannot
read the Connect cluster until it is back: that is why step 9 stops connect-2.

A connector can also be created in KCM: Add connector, switch to JSON, paste the content of `config`
from `connectors/*.json` with its `name`, then Update. KCM shows the override keys masked (`****`).

## Reset

```bash
./reset.sh
```

Removes the `kcm-tuto-connect` containers, `data/`, the topics `connect-configs`, `connect-offsets`,
`connect-status` and `demo-lines`, the 3 users, their ACLs (literal or prefixed groups) and the groups `connect-file-sink` and `connect-cluster`.
The cluster of tutorial 03 stays untouched.
