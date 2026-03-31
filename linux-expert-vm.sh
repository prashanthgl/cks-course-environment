gcloud compute instances create linux-learning-vm \
  --project=expert-linux \
  --zone=europe-west4-a \
  --machine-type=e2-standard-4 \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --boot-disk-type=pd-ssd \
  --tags=linux-learning \
  --metadata=startup-script='#!/bin/bash
apt-get update -y && apt-get upgrade -y
apt-get install -y \
  curl wget vim nano git htop tree \
  net-tools iputils-ping traceroute \
  dnsutils nmap tcpdump wireshark-common \
  lsof strace ltrace iotop iftop \
  sysstat procps psmisc \
  parted fdisk gdisk lvm2 \
  e2fsprogs xfsprogs btrfs-progs ncdu \
  linux-tools-generic linux-tools-common \
  valgrind gdb \
  iproute2 bridge-utils iptables \
  netcat-openbsd socat openssh-server nginx \
  docker.io docker-compose \
  python3 python3-pip \
  build-essential gcc g++ make automake autoconf \
  jq unzip zip \
  auditd cgroup-tools numactl schedtool \
  apparmor apparmor-utils fail2ban ufw \
  rsyslog logwatch
systemctl enable docker && systemctl start docker
systemctl enable nginx  && systemctl start nginx
systemctl enable auditd && systemctl start auditd
echo "Setup complete!" >> /var/log/startup-script.log'
