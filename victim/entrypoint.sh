#!/usr/bin/env bash
set -e

touch /var/log/auth.log
mkdir -p /run/sshd /var/run/sshd

/usr/sbin/rsyslogd
/usr/sbin/sshd
/var/ossec/bin/wazuh-control start

echo "[OK] victim01 listo. Usuario demo / Demo123!"
tail -F /var/log/auth.log /var/ossec/logs/ossec.log
