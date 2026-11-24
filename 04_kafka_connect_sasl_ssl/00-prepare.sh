#!/bin/bash
# Docker network shared with tutorial 03 and KCM, and the folder shared by the 2 workers
cd "$(dirname "$0")"
docker network inspect kcm-net >/dev/null 2>&1 || docker network create kcm-net
[ -f ../03_kafka_kraft_sasl_ssl/certs/truststore.jks ] || { echo "Tutorial 03 certificates not found" >&2; exit 1; }
# The container user (uid 1000) must be able to write in ./data
mkdir -p data && chmod 777 data
echo "Ready."
