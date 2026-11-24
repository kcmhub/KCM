#!/bin/bash
# Remove ONLY this tutorial: its containers, its data, and (if the cluster is up) its topics, users and ACLs.
# The cluster of tutorial 03 is left running.
cd "$(dirname "$0")"
docker compose down --remove-orphans
if docker ps --format '{{.Names}}' | grep -q '^kcm-tuto-broker-1$'; then
docker compose run --rm -T cli <<'CLI'
BS=broker-1:9092
CFG=/tuto/config/client.properties
rm_acl() { kafka-acls.sh --bootstrap-server $BS --command-config $CFG --remove --force "$@" >/dev/null; }

for t in connect-configs connect-offsets connect-status; do
  rm_acl --allow-principal User:connect --operation Read --operation Write --topic $t
done
for pt in literal prefixed; do
  rm_acl --allow-principal User:connect --operation Read --group connect-cluster --resource-pattern-type $pt
  rm_acl --allow-principal User:file-sink --operation Read --group connect-file-sink --resource-pattern-type $pt
done
rm_acl --allow-principal User:file-source --operation Write --topic demo-lines
rm_acl --allow-principal User:file-sink --operation Read --topic demo-lines

for u in connect file-source file-sink; do
  kafka-configs.sh --bootstrap-server $BS --command-config $CFG --alter \
    --delete-config SCRAM-SHA-512 --entity-type users --entity-name $u
done
for t in connect-configs connect-offsets connect-status demo-lines; do
  kafka-topics.sh --bootstrap-server $BS --command-config $CFG --delete --if-exists --topic $t
done
kafka-consumer-groups.sh --bootstrap-server $BS --command-config $CFG --delete --group connect-file-sink >/dev/null 2>&1
kafka-consumer-groups.sh --bootstrap-server $BS --command-config $CFG --delete --group connect-cluster >/dev/null 2>&1
true
CLI
fi
rm -rf data
