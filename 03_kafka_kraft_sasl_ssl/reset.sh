#!/bin/bash
# Remove ONLY the kcm-tuto stack, its volumes and the generated certificates
cd "$(dirname "$0")"
docker compose down -v --remove-orphans
rm -rf certs
