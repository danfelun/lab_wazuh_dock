FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV WAZUH_MANAGER=wazuh.manager
ENV WAZUH_AGENT_NAME=victim01

RUN apt-get update && apt-get install -y \
    curl gnupg apt-transport-https lsb-release ca-certificates \
    openssh-server rsyslog procps vim net-tools iproute2 sudo \
    && mkdir -p /run/sshd /var/run/sshd \
    && useradd -m -s /bin/bash demo \
    && echo 'demo:Demo123!' | chpasswd \
    && usermod -aG sudo demo \
    && mkdir -p /opt/lab \
    && echo 'archivo sensible' > /opt/lab/crownjewels.txt \
    && chmod 600 /opt/lab/crownjewels.txt \
    && rm -rf /var/lib/apt/lists/*

RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list && \
    apt-get update && \
    WAZUH_MANAGER=${WAZUH_MANAGER} WAZUH_AGENT_NAME=${WAZUH_AGENT_NAME} apt-get install -y wazuh-agent && \
    apt-mark hold wazuh-agent && \
    rm -rf /var/lib/apt/lists/*

COPY sshd_config /etc/ssh/sshd_config
COPY ossec.conf /var/ossec/etc/ossec.conf
COPY entrypoint.sh /entrypoint.sh

# Asegurar que rsyslog escribe auth en /var/log/auth.log
RUN echo 'auth,authpriv.*    /var/log/auth.log' > /etc/rsyslog.d/50-auth.conf

RUN chmod +x /entrypoint.sh

EXPOSE 22
CMD ["/entrypoint.sh"]
