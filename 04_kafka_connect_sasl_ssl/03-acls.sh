#!/bin/bash
# Admin: least-privilege ACLs (idempotent). The same ACLs can be created in KCM (Security > Edit ACLs).
cd "$(dirname "$0")"
docker compose run --rm -T cli <<'CLI'
set -e
BS=broker-1:9092
CFG=/tuto/config/client.properties
acl() { kafka-acls.sh --bootstrap-server $BS --command-config $CFG --add --force "$@"; }

# Workers (user connect): read and write the 3 internal topics, join the group connect-cluster
for t in connect-configs connect-offsets connect-status; do
  acl --allow-principal User:connect --operation Read --operation Write --topic $t
done
acl --allow-principal User:connect --operation Read --group connect-cluster --resource-pattern-type prefixed

# Connector file-source: write to demo-lines
acl --allow-principal User:file-source --operation Write --topic demo-lines

# Connector file-sink: read demo-lines with the consumer group connect-file-sink
acl --allow-principal User:file-sink --operation Read --topic demo-lines
acl --allow-principal User:file-sink --operation Read --group connect-file-sink --resource-pattern-type prefixed

for u in connect file-source file-sink; do
  kafka-acls.sh --bootstrap-server $BS --command-config $CFG --list --principal User:$u
done
CLI
