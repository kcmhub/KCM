#!/bin/bash
# External network shared with the KCM stack (same name as the KCM quick start)
docker network inspect kcm-net >/dev/null 2>&1 || docker network create kcm-net
