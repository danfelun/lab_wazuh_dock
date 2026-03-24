FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nmap hydra openssh-client curl wget iputils-ping netcat-traditional \
    vim procps inetutils-tools \
    && rm -rf /var/lib/apt/lists/*

CMD ["sleep", "infinity"]
