#!/bin/bash
# Demo KDC for the realm KCM.LAN. DEMO ONLY: fixed master password, readable keytabs.
set -euo pipefail

REALM="KCM.LAN"
MASTER_PASSWORD="demo-master-password"   # DEMO value, never reuse
KEYTABS=/keytabs
DB=/var/lib/krb5kdc

mkdir -p /etc/krb5kdc "$DB" "$KEYTABS"

cat > /etc/krb5kdc/kdc.conf <<CONF
[kdcdefaults]
  kdc_ports = 88
  kdc_tcp_ports = 88

[realms]
  $REALM = {
    database_name = $DB/principal
    key_stash_file = /etc/krb5kdc/stash
    acl_file = /etc/krb5kdc/kadm5.acl
    max_life = 24h 0m 0s
    max_renewable_life = 7d 0h 0m 0s
    master_key_type = aes256-cts
    supported_enctypes = aes256-cts:normal aes128-cts:normal
  }
CONF
echo "*/admin@$REALM *" > /etc/krb5kdc/kadm5.acl

# Create the database only once (idempotent on restart)
if [ ! -f "$DB/principal" ]; then
  echo "Creating the Kerberos database for $REALM"
  kdb5_util create -s -r "$REALM" -P "$MASTER_PASSWORD"
  rm -f "$KEYTABS"/*.keytab   # old keytabs would not match the new database
fi

addprinc() {
  kadmin.local -q "getprinc $1" 2>&1 | grep -q "^Principal: $1" \
    || kadmin.local -q "addprinc -randkey $1"
}

export_keytab() {  # export_keytab <file> <principal>
  if [ ! -f "$KEYTABS/$1" ]; then
    kadmin.local -q "ktadd -k $KEYTABS/$1 $2"
  fi
}

addprinc "kafka/broker1.kcm.lan@$REALM"
addprinc "kcm-svc@$REALM"
addprinc "client@$REALM"
export_keytab kafka-broker1.keytab "kafka/broker1.kcm.lan@$REALM"
export_keytab kcm-svc.keytab "kcm-svc@$REALM"
export_keytab client.keytab "client@$REALM"

# Demo only: the Kafka image runs as uid 1000 and must read the keytabs
chown 1000:1000 "$KEYTABS"/*.keytab
chmod 644 "$KEYTABS"/*.keytab

echo "Principals:"
kadmin.local -q "listprincs" | grep -E "^(kafka|kcm-svc|client)"
echo "Starting krb5kdc for $REALM"
exec krb5kdc -n
