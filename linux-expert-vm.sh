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

# Helper — logs with timestamp to syslog AND custom log
log() {
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a /var/log/startup-script.log
  logger -t startup-script "$1"
}

log "🚀 Startup script BEGIN"

# ── Step 1: Update ────────────────────────────
log "📦 Step 1/7: Running apt-get update..."
apt-get update -y >> /var/log/startup-script.log 2>&1
log "✅ Step 1/7: apt-get update done"

# ── Step 2: Upgrade ───────────────────────────
log "⬆️  Step 2/7: Running apt-get upgrade..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> /var/log/startup-script.log 2>&1
log "✅ Step 2/7: apt-get upgrade done"

# ── Step 3: Install all packages ─────────────
log "🔧 Step 3/7: Installing all packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
  rsyslog logwatch >> /var/log/startup-script.log 2>&1
log "✅ Step 3/7: All packages installed"

# ── Step 4: Install linux-headers ─────────────
# ✅ CORRECT — KERNEL_VER is evaluated INSIDE the VM at runtime!
log "🐧 Step 4/7: Installing linux-headers for running kernel..."
KERNEL_VER=$(uname -r)
log "   Detected kernel version: ${KERNEL_VER}"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  linux-headers-${KERNEL_VER} >> /var/log/startup-script.log 2>&1
log "✅ Step 4/7: linux-headers-${KERNEL_VER} installed"

# ── Step 5: Enable services ───────────────────
log "⚙️  Step 5/7: Enabling services..."
systemctl enable docker && systemctl start docker
systemctl enable nginx  && systemctl start nginx
systemctl enable auditd && systemctl start auditd
log "✅ Step 5/7: All services enabled and started"

# ── Step 6: Verify installs ───────────────────
log "🔍 Step 6/7: Verifying key installs..."
for cmd in docker nginx python3 gcc gdb strace tcpdump; do
  if command -v $cmd > /dev/null 2>&1; then
    log "  ✅ $cmd: $(command -v $cmd)"
  else
    log "  ❌ $cmd: NOT FOUND — install may have failed!"
  fi
done

# ── Step 7: Write completion marker ──────────
log "🏁 Step 7/7: Writing completion marker..."
echo "STARTUP_COMPLETE" > /var/run/startup-done
log "🎉 Startup script COMPLETE — VM is ready!"
'
