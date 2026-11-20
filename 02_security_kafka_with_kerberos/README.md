# Kafka 4.4.0 with Kerberos (SASL/GSSAPI)

A single Kafka broker (KRaft) that authenticates clients with Kerberos, plus a demo KDC, all started by
`docker compose up -d`:

- `kdc`: a MIT Kerberos KDC for the realm `KCM.LAN`, built from `kdc/`. At first start it creates the principals
  `kafka/broker1.kcm.lan`, `kcm-svc` and `client` and writes their keytabs in `keytabs/`
- `kafka`: `apache/kafka:4.4.0`, listener `SASL_PLAINTEXT` with GSSAPI on port 9093
- `cli`: a shell with the Kafka tools, already configured to authenticate as `client@KCM.LAN`

Everything is demo only: fixed KDC master password, keytabs readable by everyone, no TLS (`SASL_PLAINTEXT`).
In production use `SASL_SSL` with GSSAPI, a real KDC (or Active Directory) and keytabs with strict permissions.

To understand the concepts (principal, TGT, service ticket, keytab), read [KERBEROS.md](KERBEROS.md).
To use your own KDC on an Ubuntu VM instead of the container, see [KDC_ON_UBUNTU.md](KDC_ON_UBUNTU.md).

Requirements: Docker with the compose plugin.

## 1. Network

```bash
docker network inspect kcm-net >/dev/null 2>&1 || docker network create kcm-net
```

`kcm-net` is shared with KCM (same name as in the [KCM quick start](../00_kcm_with_docker_compose)), so KCM
reaches the KDC and the broker by name. Nothing happens if it already exists.

## 2. Start

```bash
docker compose up -d --build
docker compose ps
```

The broker waits for the KDC to be healthy (the healthcheck gets a ticket with `client.keytab`).
The first start builds the KDC image, which takes a minute.

## 3. Check the KDC and the broker

```bash
docker compose logs kdc
docker compose logs kafka | grep -E "Kafka Server started|ERROR"
ls -l keytabs
```

You should see the three principals in the KDC logs, `krb5kdc: starting...`, and `Kafka Server started` for the
broker. `keytabs/` contains `kafka-broker1.keytab`, `kcm-svc.keytab` and `client.keytab`.

## 4. Test with the CLI

```bash
docker compose run --rm cli
```

You get a shell (`cli $`) with `client.properties` in the current directory:

```bash
kafka-topics.sh --bootstrap-server broker1.kcm.lan:9093 --command-config client.properties \
  --create --topic demo --partitions 1

echo "hello kerberos" | kafka-console-producer.sh --bootstrap-server broker1.kcm.lan:9093 \
  --command-config client.properties --topic demo

kafka-console-consumer.sh --bootstrap-server broker1.kcm.lan:9093 --command-config client.properties \
  --topic demo --group demo-group --from-beginning --max-messages 1

kafka-consumer-groups.sh --bootstrap-server broker1.kcm.lan:9093 --command-config client.properties \
  --describe --group demo-group
```

Type `exit` to leave. The `TGT renewal thread has been interrupted` warnings at the end of each command are
harmless.

What `client.properties` does: `security.protocol=SASL_PLAINTEXT`, `sasl.mechanism=GSSAPI`,
`sasl.kerberos.service.name=kafka` (the first part of the broker principal `kafka/broker1.kcm.lan`) and a
`Krb5LoginModule` that logs in as `client@KCM.LAN` with `client.keytab`.

## Layout

| Item                | Value                                                        |
|---------------------|--------------------------------------------------------------|
| Realm               | `KCM.LAN`                                                    |
| KDC                 | `kdc.kcm.lan` (container `kcm-krb-kdc`)                      |
| Broker              | `broker1.kcm.lan` (container `kcm-krb-broker1`)              |
| Listeners           | INTERNAL 9092 (PLAINTEXT), SASL_PLAINTEXT 9093 (GSSAPI), CONTROLLER 9094 |
| Principals          | `kafka/broker1.kcm.lan@KCM.LAN`, `kcm-svc@KCM.LAN`, `client@KCM.LAN` |
| Keytabs             | `keytabs/kafka-broker1.keytab`, `keytabs/kcm-svc.keytab`, `keytabs/client.keytab` |

No port is published on the host: the names `kdc.kcm.lan` and `broker1.kcm.lan` only exist for containers on
`kcm-net` (network aliases), and Kerberos needs those names, not IP addresses.

## Connect KCM

Start KCM with the quick start in [`00_kcm_with_docker_compose`](../00_kcm_with_docker_compose): it joins
`kcm-net`, so it resolves `kdc.kcm.lan` and `broker1.kcm.lan`.

1. KCM needs the Kerberos configuration (`krb5.conf`, which tells where the KDC of `KCM.LAN` is). Mount it in the
   KCM API container at `/etc/krb5.conf`: in `00_kcm_with_docker_compose`, add a `docker-compose.override.yml`

   ```yaml
   services:
     kcm-api:
       volumes:
         - ../02_security_kafka_with_kerberos/krb5.conf:/etc/krb5.conf:ro
   ```

   then run `docker compose up -d` again. KCM also has a Settings > Kerberos tab to upload `krb5.conf`; with
   KCM 1.5.1 that upload fails (HTTP 500), so use the mount for now.
2. Create an environment if needed, then add a cluster:
   - Bootstrap servers: `broker1.kcm.lan:9093`
   - Security protocol: `SASL_PLAINTEXT`, SASL mechanism: `GSSAPI`
   - Principal: `kcm-svc@KCM.LAN`
   - Service name: `kafka`
   - Use KeyTab checked, Kerberos Keytab: upload `keytabs/kcm-svc.keytab`. KCM stores it on its server and fills
     "Kerberos Keytab Location" with the path (for example `/app/files/KAFKA_CLUSTER/<id>/keytab.keytab`). If the
     keytab is already on the KCM server, leave the upload empty and type that path in the location field.
3. Create, then Test connection: `Connection OK` (tested with KCM 1.5.1 and Kafka 4.4.0). Without `krb5.conf`
   the test fails with `Unable to locate KDC for realm KCM.LAN`.

The bootstrap must be the FQDN. With an IP address the client asks for the service `kafka/<ip>`, which does
not exist in the KDC.

## Troubleshooting

- `Cannot locate KDC` or `Unable to locate KDC for realm KCM.LAN`: the client does not know `krb5.conf` (for KCM,
  see the Kerberos settings), or it cannot resolve `kdc.kcm.lan` (it must be on `kcm-net`).
- `Server not found in Kerberos database`: the client used another name than `broker1.kcm.lan` (an IP, a
  different alias). The service principal is built from the host name of the bootstrap server.
- `Clock skew too great`: the clocks of the client and the KDC differ by more than 5 minutes. On Docker Desktop,
  restart the engine if the VM clock drifted after a sleep.
- `Preauthentication failed` or `Checksum failed`: the keytab does not match the KDC database, for example
  after deleting the `kdc-data` volume but keeping old keytabs. Do a full reset (below).
- Keytab not readable: the Kafka image runs as uid 1000. The KDC container sets the keytabs to `1000:1000` with
  mode 644 (demo only). With keytabs from another source, make them readable by uid 1000.
- Realm in lowercase: realms are case sensitive. Write `KCM.LAN` in principals and `krb5.conf`, and the domain
  mapping in lowercase (`.kcm.lan`).
- More details: add `-Dsun.security.krb5.debug=true` to `KAFKA_OPTS` and run `docker compose up -d`.

## Reset

```bash
docker compose down -v --rmi local
rm -f keytabs/*.keytab
```

Removes the containers, the `kdc-data` and `kafka-data` volumes, the local KDC image and the generated
keytabs. If the `rm` is refused, the files belong to uid 1000: use `sudo rm`.
