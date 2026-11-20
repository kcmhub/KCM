#!/bin/bash
# Format the storage of every node with the same cluster id
set -eo pipefail
cd "$(dirname "$0")"
CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qg

# fmt <service> <extra kafka-storage args>: one short line, full output only on failure
fmt() {
  local svc=$1 out; shift
  out=$(docker compose run --rm --no-deps --entrypoint /opt/kafka/bin/kafka-storage.sh "$svc" \
    format --config /etc/kafka/tuto/server.properties --cluster-id $CLUSTER_ID "$@" 2>&1) \
    || { echo "$out" >&2; echo "$svc: format FAILED" >&2; exit 1; }
  echo "$out" | grep '^Formatting' | sed "s/^/$svc: /"
}

# Controller: single-node dynamic quorum + the SCRAM users
fmt controller-1 --standalone \
  --add-scram 'SCRAM-SHA-512=[name="admin",password="admin-secret"]' \
  --add-scram 'SCRAM-SHA-512=[name="kcm",password="kcm-secret"]'

# Brokers: join the existing quorum, no SCRAM needed here
for b in broker-1 broker-2 broker-3; do
  fmt $b --no-initial-controllers
done
echo "Done: 4 nodes formatted, SCRAM users admin and kcm created."
