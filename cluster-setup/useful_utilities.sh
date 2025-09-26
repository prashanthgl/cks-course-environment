#!/bin/bash

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

sudo apt install -y git python3 python3-pip
sudo apt-get install -y fzf
# Install kube-bench (CIS Kubernetes benchmark)
KUBE_BENCH_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/kube-bench/releases/latest | jq -r '.tag_name')
curl -sL "https://github.com/aquasecurity/kube-bench/releases/download/${KUBE_BENCH_VERSION}/kube-bench_${KUBE_BENCH_VERSION#v}_linux_amd64.tar.gz" | sudo tar -xzf - -C /usr/local/bin kube-bench
sudo chmod +x /usr/local/bin/kube-bench

# Install kube-hunter (security vulnerability hunter)
# Use pipx for isolated installation to avoid externally-managed-environment error
sudo apt-get install -y pipx
sudo pipx install kube-hunter
# Make pipx binaries available system-wide
sudo ln -sf /root/.local/bin/kube-hunter /usr/local/bin/kube-hunter

# Install kubesec (security risk analysis)
KUBESEC_VERSION=$(curl -s https://api.github.com/repos/controlplaneio/kubesec/releases/latest | jq -r '.tag_name')
curl -sL "https://github.com/controlplaneio/kubesec/releases/download/${KUBESEC_VERSION}/kubesec_linux_amd64.tar.gz" | sudo tar -xzf - -C /usr/local/bin kubesec
sudo chmod +x /usr/local/bin/kubesec

# Install kube-linter (static analysis tool)
KUBE_LINTER_VERSION=$(curl -s https://api.github.com/repos/stackrox/kube-linter/releases/latest | jq -r '.tag_name')
curl -sL "https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-linux.tar.gz" | sudo tar -xzf - -C /usr/local/bin
sudo chmod +x /usr/local/bin/kube-linter

# Install Polaris (best practices validation)
POLARIS_VERSION=$(curl -s https://api.github.com/repos/FairwindsOps/polaris/releases/latest | jq -r '.tag_name')
curl -sL "https://github.com/FairwindsOps/polaris/releases/download/${POLARIS_VERSION}/polaris_linux_amd64.tar.gz" | sudo tar -xzf - -C /usr/local/bin polaris
sudo chmod +x /usr/local/bin/polaris

git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz -o k9s.tar.gz
tar -xzvf k9s.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz

sudo apt install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install -y trivy

curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | sudo apt-key add -
echo "deb https://download.falco.org/packages/deb stable main" | sudo tee /etc/apt/sources.list.d/falcosecurity.list
sudo apt update
sudo apt install -y falco
