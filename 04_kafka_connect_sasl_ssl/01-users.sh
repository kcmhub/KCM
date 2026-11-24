#!/bin/bash
# Admin: one SCRAM-SHA-512 user for the workers, one per connector (idempotent).
# Runs the Kafka CLI in the cli container. The same users can be created in KCM (Security > Add Kafka user).
cd "$(dirname "$0")"
docker compose run --rm -T cli <<'CLI'
set -e
for u in connect file-source file-sink; do
  kafka-configs.sh --bootstrap-server broker-1:9092 --command-config /tuto/config/client.properties --alter \
    --add-config "SCRAM-SHA-512=[password=$u-secret]" --entity-type users --entity-name $u
done
CLI
