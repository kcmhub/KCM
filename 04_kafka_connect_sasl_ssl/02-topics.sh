#!/bin/bash
# Admin: the 3 internal topics of Connect and the data topic of the demo (idempotent)
cd "$(dirname "$0")"
docker compose run --rm -T cli <<'CLI'
set -e
topic() { kafka-topics.sh --bootstrap-server broker-1:9092 --command-config /tuto/config/client.properties \
  --create --if-not-exists "$@"; }

# Internal topics: compacted, replication factor 3, created by the admin (the workers need no CREATE)
topic --topic connect-configs --partitions 1  --replication-factor 3 --config cleanup.policy=compact
topic --topic connect-offsets --partitions 25 --replication-factor 3 --config cleanup.policy=compact
topic --topic connect-status  --partitions 5  --replication-factor 3 --config cleanup.policy=compact

# Data topic
topic --topic demo-lines --partitions 3 --replication-factor 3
CLI
