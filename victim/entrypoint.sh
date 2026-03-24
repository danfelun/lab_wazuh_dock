#!/usr/bin/env bash
set -e

# Crear archivos de log que ossec.conf referencia
touch /var/log/auth.log /var/log/fake_auth.log /var/log/lab_auth.log /var/log/syslog
chmod 644 /var/log/auth.log /var/log/fake_auth.log /var/log/lab_auth.log /var/log/syslog

mkdir -p /run/sshd /var/run/sshd

# Arrancar rsyslog y esperar que el socket /dev/log esté listo
/usr/sbin/rsyslogd
sleep 1

# Arrancar sshd
/usr/sbin/sshd

# Arrancar agente Wazuh
/var/ossec/bin/wazuh-control start

echo "[OK] victim01 listo. Usuario demo / Demo123!"
tail -F /var/log/auth.log /var/log/lab_auth.log /var/ossec/logs/ossec.log
