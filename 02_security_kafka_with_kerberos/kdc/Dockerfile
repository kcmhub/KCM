FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends krb5-kdc krb5-admin-server krb5-user \
 && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 88/tcp 88/udp
ENTRYPOINT ["/entrypoint.sh"]
