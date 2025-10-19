# README — Install Kerberos (MIT) on Ubuntu 24.04 and generate keytabs for Kafka/KCM

This guide describes the steps to set up a MIT Kerberos KDC on Ubuntu 24.04, create the required principals, and export keytabs for a Kafka broker and for KCM. The example uses the internal domain kcm.lan and the REALM KCM.LAN with a broker broker1.kcm.lan and a KDC kdc.kcm.lan.

Note: All commands are intended to be run on the Ubuntu KDC machine. Commands requiring elevated privileges use `sudo` and may prompt you for your local sudo password.

---

## 0) Prerequisites (names and resolution)

- Linux machine/VM to install the KDC (Ubuntu 24.04 recommended). Run all commands below on this machine.
- REALM: `KCM.LAN` (uppercase)
- Domain: `kcm.lan`
- KDC: `kdc.kcm.lan`
- Broker: `broker1.kcm.lan`

Add entries to `/etc/hosts` on the Ubuntu machine (replace `<IP_VM_UBUNTU>`):

```bash
sudo sh -c 'cat >> /etc/hosts <<EOF
<IP_VM_UBUNTU>  kdc.kcm.lan kdc
<IP_VM_UBUNTU>  broker1.kcm.lan broker1
EOF'
```

Sync the clock (Kerberos is time-sensitive):

```bash
sudo apt update
sudo apt install -y chrony
sudo systemctl enable --now chrony
```

Interactive prompts:
- Sudo password may be requested.

---

## 1) Install the MIT Kerberos KDC

```bash
sudo apt update
sudo apt install -y krb5-kdc krb5-admin-server krb5-user
```

Interactive prompts (Debconf):
- Default Kerberos 5 realm: `KCM.LAN`
- Kerberos servers for your realm: `kdc.kcm.lan`
- Administrative server for your realm: `kdc.kcm.lan`

---

## 2) Configure `/etc/krb5.conf`

Edit the file to point to your KDC:

```ini
[libdefaults]
  default_realm = KCM.LAN
  dns_canonicalize_hostname = false
  rdns = false
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true

[realms]
  KCM.LAN = {
    kdc = kdc.kcm.lan
    admin_server = kdc.kcm.lan
  }

[domain_realm]
  .kcm.lan = KCM.LAN
  kcm.lan = KCM.LAN
```

No prompt; just save the file.

---

## 3) Initialize the Kerberos database

```bash
sudo krb5_newrealm
```

Interactive prompts:
- Set the KDC database master password twice (strong password). This is NOT the `admin/admin` password.

---

## 4) Allow the Kerberos admin

Authorize the admin principal in `/etc/krb5kdc/kadm5.acl` and restart services:

```bash
sudo sh -c 'echo "admin/admin@KCM.LAN *" > /etc/krb5kdc/kadm5.acl'
sudo systemctl restart krb5-kdc krb5-admin-server
```

Interactive prompts:
- Sudo password may be requested.

---

## 5) Create the admin and test authentication

Create the admin principal and get a TGT:

```bash
sudo kadmin.local -q "addprinc admin/admin"
kinit admin/admin
klist
```

Interactive prompts:
- You will set then use the `admin/admin@KCM.LAN` password.

---

## 6) Prepare the keytabs location (on the KDC)

```bash
sudo mkdir -p /etc/security/keytabs
sudo chown -R $(whoami):$(whoami) /etc/security/keytabs
sudo chmod 750 /etc/security/keytabs
```

Interactive prompts:
- Sudo password may be requested.

---

## 7) Create the Kafka broker principal and export the keytab (on the KDC)

```bash
kadmin -p admin/admin -q "addprinc -randkey kafka/broker1.kcm.lan@KCM.LAN"
sudo kadmin -p admin/admin -q "ktadd -k /etc/security/keytabs/kafka-broker1.keytab kafka/broker1.kcm.lan@KCM.LAN"
sudo chmod 600 /etc/security/keytabs/kafka-broker1.keytab
```

Interactive prompts:
- Provide `admin/admin@KCM.LAN` password when asked.

---

## 8) Create the KCM principal and export the keytab (on the KDC)

```bash
kadmin -p admin/admin -q "addprinc -randkey kcm-svc@KCM.LAN"
sudo kadmin -p admin/admin -q "ktadd -k /etc/security/keytabs/kcm.keytab kcm-svc@KCM.LAN"
sudo chmod 600 /etc/security/keytabs/kcm.keytab
```

Interactive prompts:
- Provide `admin/admin@KCM.LAN` password when asked.

---

## 9) Verification (on the KDC)

```bash
sudo klist -k -t -e /etc/security/keytabs/kafka-broker1.keytab
sudo klist -k -t -e /etc/security/keytabs/kcm.keytab
kinit -k -t /etc/security/keytabs/kcm.keytab kcm-svc@KCM.LAN
klist
kvno kafka/broker1.kcm.lan@KCM.LAN
```

---

## 10) Summary of paths and identities

- REALM: `KCM.LAN`
- KDC: `kdc.kcm.lan`
- Broker: `broker1.kcm.lan`
- Broker keytab: `/etc/security/keytabs/kafka-broker1.keytab`
- KCM keytab: `/etc/security/keytabs/kcm.keytab`
- Admin: `admin/admin@KCM.LAN`
- Broker principal: `kafka/broker1.kcm.lan@KCM.LAN`
- KCM principal: `kcm-svc@KCM.LAN`

---

## 11) Run with Docker Compose (GSSAPI listener)

Before starting the container:

1) Copy the broker keytab into this project folder

- On the KDC (Linux host), the broker keytab is at `/etc/security/keytabs/kafka-broker1.keytab`.
- Copy it into this folder at `./keytabs/kafka-broker1.keytab`.

Examples:
- Windows (cmd.exe):
  ```cmd
  scp youruser@kdc.kcm.lan:/etc/security/keytabs/kafka-broker1.keytab "D:\workspace\k_c_m\kafka_with_kerberos\keytabs\kafka-broker1.keytab"
  ```
- Linux/macOS:
  ```bash
  scp youruser@kdc.kcm.lan:/etc/security/keytabs/kafka-broker1.keytab ./keytabs/kafka-broker1.keytab
  ```

2) Ensure configuration files are present and consistent

- `./krb5.conf` defines realm `KCM.LAN` and points to `kdc.kcm.lan` (bind-mounted to `/etc/krb5.conf`).
- `./keytabs/kafka-broker1.keytab` contains `kafka/broker1.kcm.lan@KCM.LAN` (bind-mounted to `/etc/security/keytabs/kafka-broker1.keytab`).
- `./kafka_server_jaas.conf` references that keytab and principal.
- In `docker-compose.yml`, `extra_hosts` uses your actual KDC/broker IPs for `kdc.kcm.lan` and `broker1.kcm.lan`.

Start the broker and check logs:

```cmd
docker compose up -d
docker compose logs -f kafka
```

If you see SASL/GSSAPI errors, re-check `./krb5.conf`, JAAS principal, and that the keytab contains the correct entry.

### If you see: `javax.security.auth.login.LoginException: Cannot locate KDC`

- We pass `-Djava.security.krb5.conf=/etc/krb5.conf`. Ensure `./krb5.conf` has:
  - `[realms] KCM.LAN = { kdc = kdc.kcm.lan }` and `[domain_realm]` for `kcm.lan`.
- Ensure `extra_hosts` points to the real KDC IP; open UDP/88 and TCP/88 on the KDC firewall.
- Time skew < 5 minutes (compare container vs KDC time).
- Optional verbose logs: set `-Dsun.security.krb5.debug=true` in `KAFKA_OPTS` then restart.

---

## 12) Troubleshooting — `kdb5_util: Permission denied while initializing Kerberos code`

1) Ensure packages and Kerberos config helper are installed

```bash
sudo apt update
sudo apt install -y krb5-kdc krb5-admin-server krb5-user krb5-config
```

2) Create `/etc/krb5.conf` if missing

```bash
cat | sudo tee /etc/krb5.conf >/dev/null <<'EOF'
[libdefaults]
  default_realm = KCM.LAN
  dns_canonicalize_hostname = false
  rdns = false
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true

[realms]
  KCM.LAN = {
    kdc = kdc.kcm.lan
    admin_server = kdc.kcm.lan
  }

[domain_realm]
  .kcm.lan = KCM.LAN
  kcm.lan = KCM.LAN
EOF
```

3) Fix KDC directories and permissions

```bash
sudo install -d -m 0755 /etc/krb5kdc
sudo install -d -m 0700 /var/lib/krb5kdc
# optional: move stale files aside
[ -f /etc/krb5kdc/stash ] && sudo mv /etc/krb5kdc/stash /etc/krb5kdc/stash.bak.$(date +%s)
if [ -f /var/lib/krb5kdc/principal ] || [ -f /var/lib/krb5kdc/principal.ok ]; then
  TS=$(date +%s); sudo mkdir -p /var/lib/krb5kdc.backup.$TS
  sudo mv /var/lib/krb5kdc/* /var/lib/krb5kdc.backup.$TS/ 2>/dev/null || true
fi
sudo chown -R root:root /etc/krb5kdc /var/lib/krb5kdc
sudo chmod 755 /etc/krb5kdc
sudo chmod 700 /var/lib/krb5kdc
```

4) Initialize the realm again

```bash
sudo krb5_newrealm
```

If it still fails, capture a short trace:

```bash
sudo strace -f -o /tmp/krb5_newrealm.strace krb5_newrealm || true
grep -nE "EACCES|Permission denied|ENOENT" /tmp/krb5_newrealm.strace | tail -n 40
```
