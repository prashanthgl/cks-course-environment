# Certified Kubernetes Security Specialist (CKS) - Complete Study Guide

## Table of Contents
1. [Cluster Setup (10%)](#1-cluster-setup)
2. [Cluster Hardening (15%)](#2-cluster-hardening)
3. [System Hardening (15%)](#3-system-hardening)
4. [Minimize Microservice Vulnerabilities (20%)](#4-minimize-microservice-vulnerabilities)
5. [Supply Chain Security (20%)](#5-supply-chain-security)
6. [Monitoring, Logging & Runtime Security (20%)](#6-monitoring-logging-runtime-security)

---

## 1. Cluster Setup (10%)

### 1.1 Network Policies

Network Policies control traffic flow between pods and network endpoints.

#### Key Commands
```bash
# Get network policies
kubectl get networkpolicies
kubectl get netpol

# Describe network policy
kubectl describe networkpolicy <policy-name>

# Delete network policy
kubectl delete networkpolicy <policy-name>

# Test network connectivity between pods
kubectl exec -it <pod-name> -- nc -zv <target-pod-ip> <port>
kubectl exec -it <pod-name> -- wget -O- <target-service>
```

#### Default Deny All Ingress Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

#### Default Deny All Egress Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
```

#### Allow Specific Ingress Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    - podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 5432
```

#### Allow Specific Egress Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  - to:
    - podSelector:
        matchLabels:
          app: external-api
    ports:
    - protocol: TCP
      port: 443
```

#### Combined Ingress and Egress Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: full-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: webapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: database
    ports:
    - protocol: TCP
      port: 3306
```

#### Allow Traffic from IP Block
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-ip
spec:
  podSelector:
    matchLabels:
      app: public-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 192.168.1.0/24
        except:
        - 192.168.1.5/32
    ports:
    - protocol: TCP
      port: 443
```

### 1.2 CIS Benchmark

CIS Kubernetes Benchmark provides security configuration guidelines.

#### Key Commands
```bash
# Run kube-bench (CIS benchmark tool)
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# Check kube-bench results
kubectl logs -l app=kube-bench

# Run kube-bench on master node
kube-bench run --targets master

# Run kube-bench on worker node
kube-bench run --targets node

# Run specific checks
kube-bench run --check 1.2.1
```

#### Install kube-bench
```bash
# Using Docker
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro \
  -t aquasec/kube-bench:latest run --targets master

# Binary installation
curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.6.15/kube-bench_0.6.15_linux_amd64.tar.gz -o kube-bench.tar.gz
tar -xvf kube-bench.tar.gz
./kube-bench
```

### 1.3 Ingress with TLS

#### Commands for TLS Secrets
```bash
# Create TLS secret from cert and key files
kubectl create secret tls my-tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key

# Create TLS secret with openssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=myapp.example.com"
kubectl create secret tls my-tls-secret --cert=tls.crt --key=tls.key

# View secret
kubectl get secret my-tls-secret -o yaml
```

#### Ingress with TLS
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: my-tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

### 1.4 Verify Platform Binaries

#### Commands to Verify Binaries
```bash
# Download Kubernetes binaries
wget https://dl.k8s.io/v1.28.0/bin/linux/amd64/kubectl

# Download SHA256 checksum
wget https://dl.k8s.io/v1.28.0/bin/linux/amd64/kubectl.sha256

# Verify checksum
echo "$(cat kubectl.sha256) kubectl" | sha256sum --check

# Alternative verification
sha256sum kubectl
cat kubectl.sha256

# Compare checksums manually
ACTUAL=$(sha256sum kubectl | awk '{print $1}')
EXPECTED=$(cat kubectl.sha256)
if [ "$ACTUAL" = "$EXPECTED" ]; then
  echo "Checksum verified successfully"
else
  echo "Checksum verification failed"
fi
```

---

## 2. Cluster Hardening (15%)

### 2.1 RBAC (Role-Based Access Control)

#### Key Commands
```bash
# Get roles and rolebindings
kubectl get roles -A
kubectl get rolebindings -A
kubectl get clusterroles
kubectl get clusterrolebindings

# Describe role
kubectl describe role <role-name> -n <namespace>
kubectl describe clusterrole <clusterrole-name>

# Check permissions
kubectl auth can-i create pods --as <user>
kubectl auth can-i create pods --as system:serviceaccount:<namespace>:<sa-name>
kubectl auth can-i list secrets --as <user> -n <namespace>

# Create role
kubectl create role pod-reader --verb=get,list,watch --resource=pods

# Create rolebinding
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader --user=john -n default

# Create clusterrole
kubectl create clusterrole secret-reader --verb=get,list --resource=secrets

# Create clusterrolebinding
kubectl create clusterrolebinding secret-reader-binding \
  --clusterrole=secret-reader --user=jane
```

#### Role Example
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

#### RoleBinding Example
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: john
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: myapp-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

#### ClusterRole Example
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
```

#### ClusterRoleBinding Example
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: security-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

#### Role with Multiple Resources
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: app-manager
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  resourceNames: ["app-secret"]
```

### 2.2 Service Accounts

#### Commands
```bash
# Create service account
kubectl create serviceaccount myapp-sa -n default

# Get service accounts
kubectl get serviceaccounts
kubectl get sa

# Describe service account
kubectl describe sa myapp-sa

# Get service account token
kubectl create token myapp-sa
kubectl create token myapp-sa --duration=8h

# Delete service account
kubectl delete sa myapp-sa
```

#### ServiceAccount with Secret
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: default
automountServiceAccountToken: false
```

#### Pod using ServiceAccount
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  serviceAccountName: myapp-sa
  automountServiceAccountToken: true
  containers:
  - name: myapp
    image: nginx
```

#### ServiceAccount with ImagePullSecret
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
imagePullSecrets:
- name: registry-secret
```

### 2.3 Restrict API Access

#### Update kube-apiserver Configuration
```bash
# Edit kube-apiserver manifest (static pod)
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

#### kube-apiserver Secure Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - name: kube-apiserver
    image: k8s.gcr.io/kube-apiserver:v1.28.0
    command:
    - kube-apiserver
    - --anonymous-auth=false
    - --authorization-mode=Node,RBAC
    - --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
    - --insecure-port=0
    - --profiling=false
    - --audit-log-path=/var/log/kubernetes/audit.log
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
    - --enable-bootstrap-token-auth=true
    - --service-account-lookup=true
```

#### Audit Policy
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  omitStages:
  - RequestReceived
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
- level: Request
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: ""
    resources: ["pods", "services"]
- level: RequestResponse
  resources:
  - group: "rbac.authorization.k8s.io"
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
```

### 2.4 Upgrade Kubernetes Components

#### Commands
```bash
# Check current version
kubectl version --short
kubectl get nodes

# Drain node before upgrade
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Upgrade kubeadm
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.28.0-00
apt-mark hold kubeadm

# Verify kubeadm version
kubeadm version

# Plan upgrade (control plane)
kubeadm upgrade plan

# Apply upgrade (control plane first node)
kubeadm upgrade apply v1.28.0

# Apply upgrade (control plane additional nodes)
kubeadm upgrade node

# Upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
apt-mark hold kubelet kubectl

# Restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# Uncordon node
kubectl uncordon <node-name>

# Verify upgrade
kubectl get nodes
```

---

## 3. System Hardening (15%)

### 3.1 Minimize Host OS Footprint

#### Key Commands
```bash
# Check running services
systemctl list-units --type=service --state=running

# Stop and disable unnecessary services
systemctl stop <service-name>
systemctl disable <service-name>

# Check open ports
netstat -tulpn
ss -tulpn

# Check installed packages
apt list --installed
dpkg -l

# Remove unnecessary packages
apt-get remove <package-name>
apt-get autoremove

# Update system
apt-get update
apt-get upgrade

# Check kernel version
uname -r
```

#### Restrict Kernel Modules
```bash
# List loaded modules
lsmod

# Blacklist modules
echo "install dccp /bin/true" >> /etc/modprobe.d/blacklist.conf
echo "install sctp /bin/true" >> /etc/modprobe.d/blacklist.conf
echo "install rds /bin/true" >> /etc/modprobe.d/blacklist.conf
echo "install tipc /bin/true" >> /etc/modprobe.d/blacklist.conf

# Unload module
modprobe -r <module-name>
```

### 3.2 AppArmor

#### Commands
```bash
# Check AppArmor status
systemctl status apparmor
aa-status

# List profiles
aa-status --profiled

# Load profile
apparmor_parser -r -W /etc/apparmor.d/<profile>

# Set profile to enforce mode
aa-enforce /etc/apparmor.d/<profile>

# Set profile to complain mode
aa-complain /etc/apparmor.d/<profile>

# Disable profile
aa-disable /etc/apparmor.d/<profile>

# Check which profile a process is using
cat /proc/<pid>/attr/current
```

#### AppArmor Profile Example
```
#include <tunables/global>

profile k8s-deny-write flags=(attach_disconnected) {
  #include <abstractions/base>
  
  file,
  deny /data/** w,
  deny /etc/** w,
  deny /bin/** w,
}
```

#### Pod with AppArmor Profile
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secured-pod
  annotations:
    container.apparmor.security.beta.kubernetes.io/secured-container: localhost/k8s-deny-write
spec:
  containers:
  - name: secured-container
    image: nginx
```

### 3.3 Seccomp

#### Commands
```bash
# Check seccomp support
grep SECCOMP /boot/config-$(uname -r)

# Default seccomp profiles location
ls /var/lib/kubelet/seccomp/
```

#### Seccomp Profile (JSON)
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32"
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "arch_prctl",
        "bind",
        "brk",
        "close",
        "connect",
        "dup",
        "dup2",
        "epoll_create",
        "epoll_ctl",
        "epoll_wait",
        "exit",
        "exit_group",
        "fcntl",
        "fstat",
        "futex",
        "getcwd",
        "getdents",
        "getpeername",
        "getpid",
        "getsockname",
        "getsockopt",
        "listen",
        "mmap",
        "munmap",
        "open",
        "openat",
        "read",
        "readlink",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "setsockopt",
        "socket",
        "stat",
        "write"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

#### Pod with Seccomp Profile (RuntimeDefault)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
```

#### Pod with Custom Seccomp Profile
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-seccomp-pod
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/custom-profile.json
  containers:
  - name: app
    image: nginx
```

### 3.4 Restrict Syscalls with Seccomp

#### Deny All Seccomp Profile
```json
{
  "defaultAction": "SCMP_ACT_ERRNO"
}
```

#### Fine-grained Seccomp Profile
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64"
  ],
  "syscalls": [
    {
      "names": [
        "read",
        "write",
        "open",
        "close",
        "stat",
        "fstat",
        "lstat",
        "poll",
        "lseek",
        "mmap",
        "mprotect",
        "munmap",
        "brk",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "ioctl",
        "pread64",
        "pwrite64",
        "readv",
        "writev",
        "access",
        "pipe",
        "select",
        "sched_yield",
        "mremap",
        "msync",
        "mincore",
        "madvise",
        "shmget",
        "shmat",
        "shmctl",
        "dup",
        "dup2",
        "pause",
        "nanosleep",
        "getitimer",
        "alarm",
        "setitimer",
        "getpid",
        "socket",
        "connect",
        "accept",
        "sendto",
        "recvfrom",
        "sendmsg",
        "recvmsg",
        "shutdown",
        "bind",
        "listen",
        "getsockname",
        "getpeername",
        "socketpair",
        "setsockopt",
        "getsockopt",
        "clone",
        "fork",
        "vfork",
        "execve",
        "exit",
        "wait4",
        "kill",
        "uname",
        "fcntl",
        "flock",
        "fsync",
        "fdatasync",
        "truncate",
        "ftruncate",
        "getdents",
        "getcwd",
        "chdir",
        "fchdir",
        "rename",
        "mkdir",
        "rmdir",
        "creat",
        "link",
        "unlink",
        "symlink",
        "readlink",
        "chmod",
        "fchmod",
        "chown",
        "fchown",
        "lchown",
        "umask",
        "gettimeofday",
        "getrlimit",
        "getrusage",
        "sysinfo",
        "times",
        "ptrace",
        "getuid",
        "getgid",
        "setuid",
        "setgid",
        "geteuid",
        "getegid",
        "setpgid",
        "getppid",
        "getpgrp",
        "setsid",
        "setreuid",
        "setregid",
        "getgroups",
        "setgroups",
        "setresuid",
        "getresuid",
        "setresgid",
        "getresgid",
        "getpgid",
        "setfsuid",
        "setfsgid",
        "getsid",
        "capget",
        "capset",
        "rt_sigpending",
        "rt_sigtimedwait",
        "rt_sigqueueinfo",
        "rt_sigsuspend",
        "sigaltstack",
        "utime",
        "mknod",
        "personality",
        "statfs",
        "fstatfs",
        "arch_prctl",
        "setrlimit",
        "sync",
        "gettid",
        "futex",
        "sched_setaffinity",
        "sched_getaffinity",
        "exit_group",
        "epoll_create",
        "epoll_ctl",
        "epoll_wait",
        "set_tid_address",
        "fadvise64",
        "timer_create",
        "timer_settime",
        "timer_gettime",
        "timer_getoverrun",
        "timer_delete",
        "clock_gettime",
        "clock_getres",
        "clock_nanosleep",
        "tgkill",
        "openat",
        "newfstatat",
        "unlinkat",
        "futimesat",
        "accept4",
        "epoll_create1",
        "dup3",
        "pipe2",
        "preadv",
        "pwritev",
        "sendmmsg",
        "recvmmsg",
        "prlimit64"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

---

## 4. Minimize Microservice Vulnerabilities (20%)

### 4.1 Security Contexts

#### Commands
```bash
# Check pod security context
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}'

# Check container security context
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].securityContext}'
```

#### Pod Security Context
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    fsGroupChangePolicy: "OnRootMismatch"
    supplementalGroups: [4000]
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  volumes:
  - name: cache-volume
    emptyDir: {}
```

#### Privileged Container (Avoid)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: privileged-container
    image: nginx
    securityContext:
      privileged: true  # AVOID THIS
```

#### Secure Container Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: secure-container
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
    - name: cache-volume
      mountPath: /var/cache/nginx
  volumes:
  - name: tmp-volume
    emptyDir: {}
  - name: cache-volume
    emptyDir: {}
```

### 4.2 Pod Security Standards (PSS) / Pod Security Admission (PSA)

#### Namespace Labels for PSA
```bash
# Label namespace for baseline enforcement
kubectl label namespace default pod-security.kubernetes.io/enforce=baseline

# Label namespace for restricted enforcement
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted

# Label namespace with multiple levels
kubectl label namespace staging \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# View namespace labels
kubectl get namespace default -o yaml
```

#### Namespace with PSA Labels
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

#### Pod Meeting Baseline Standard
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: baseline-pod
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

#### Pod Meeting Restricted Standard
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
      seccompProfile:
        type: RuntimeDefault
    resources:
      limits:
        cpu: "1"
        memory: "512Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

### 4.3 OPA (Open Policy Agent) / Gatekeeper

#### Install Gatekeeper
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# Check gatekeeper pods
kubectl get pods -n gatekeeper-system
```

#### ConstraintTemplate Example
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8srequiredlabels
      
      violation[{"msg": msg, "details": {"missing_labels": missing}}] {
        provided := {label | input.review.object.metadata.labels[label]}
        required := {label | label := input.parameters.labels[_]}
        missing := required - provided
        count(missing) > 0
        msg := sprintf("You must provide labels: %v", [missing])
      }
```

#### Constraint Example
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-label
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Namespace"]
  parameters:
    labels:
    - "team"
    - "environment"
```

#### Container Image Restriction Template
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedrepos
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sallowedrepos
      
      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
      }
      
      violation[{"msg": msg}] {
        container := input.review.object.spec.initContainers[_]
        satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("initContainer <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
      }
```

#### Constraint for Allowed Repos
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: repo-is-company-registry
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces:
    - "production"
  parameters:
    repos:
    - "mycompany.registry.io/"
    - "docker.io/library/"
```

#### Deny Privileged Containers Template
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spspprivilegedcontainer
spec:
  crd:
    spec:
      names:
        kind: K8sPSPPrivilegedContainer
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8spspprivileged
      
      violation[{"msg": msg, "details": {}}] {
        c := input_containers[_]
        c.securityContext.privileged
        msg := sprintf("Privileged container is not allowed: %v, securityContext: %v", [c.name, c.securityContext])
      }
      
      input_containers[c] {
        c := input.review.object.spec.containers[_]
      }
      
      input_containers[c] {
        c := input.review.object.spec.initContainers[_]
      }
```

### 4.4 Secrets Management

#### Commands
```bash
# Create generic secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password='S3cur3P@ss!'

# Create secret from file
kubectl create secret generic ssh-key-secret \
  --from-file=ssh-privatekey=/path/to/.ssh/id_rsa

# Create TLS secret
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key

# Create Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=myregistry.azurecr.io \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com

# Get secrets
kubectl get secrets
kubectl get secret db-secret -o yaml
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 --decode

# Encode/decode base64
echo -n 'mypassword' | base64
echo 'bXlwYXNzd29yZA==' | base64 --decode

# Delete secret
kubectl delete secret db-secret
```

#### Secret YAML
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded 'admin'
  password: UzNjdXIzUEBzcyE=  # base64 encoded 'S3cur3P@ss!'
stringData:
  connection-string: "postgresql://admin:S3cur3P@ss!@db.example.com:5432/mydb"
```

#### Pod Using Secret as Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    envFrom:
    - secretRef:
        name: db-credentials
```

#### Pod Using Secret as Volume
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-credentials
      defaultMode: 0400
      items:
      - key: username
        path: db-username
      - key: password
        path: db-password
```

#### Immutable Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: immutable-secret
type: Opaque
immutable: true
data:
  api-key: bXktYXBpLWtleQ==
```

### 4.5 Encrypt Secret Data at Rest

#### Check if Encryption is Enabled
```bash
# Create a test secret
kubectl create secret generic test-secret --from-literal=key=value

# Get the secret from etcd
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/test-secret | hexdump -C

# If encrypted, you should see "k8s:enc:aescbc:v1:" or similar prefix
```

#### Encryption Configuration
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  - configmaps
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: <BASE64_ENCODED_32_BYTE_KEY>
  - identity: {}
```

#### Generate Encryption Key
```bash
# Generate 32-byte random key and base64 encode it
head -c 32 /dev/urandom | base64
```

#### Apply Encryption Configuration
```bash
# 1. Create encryption config file
cat > /etc/kubernetes/encryption-config.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $(head -c 32 /dev/urandom | base64)
  - identity: {}
EOF

# 2. Edit kube-apiserver manifest
vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Add these flags:
#   - --encryption-provider-config=/etc/kubernetes/encryption-config.yaml
# Add volume mount:
#   - mountPath: /etc/kubernetes/encryption-config.yaml
#     name: encryption-config
#     readOnly: true
# Add volume:
#   - hostPath:
#       path: /etc/kubernetes/encryption-config.yaml
#       type: File
#     name: encryption-config

# 3. Wait for apiserver to restart
kubectl get pods -n kube-system | grep kube-apiserver

# 4. Encrypt all existing secrets
kubectl get secrets -A -o json | kubectl replace -f -
```

#### Rotate Encryption Key
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key2
        secret: <NEW_BASE64_ENCODED_KEY>
      - name: key1
        secret: <OLD_BASE64_ENCODED_KEY>
  - identity: {}
```

### 4.6 Container Runtime Sandboxing (gVisor, Kata Containers)

#### RuntimeClass for gVisor
```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
```

#### RuntimeClass for Kata Containers
```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata
```

#### Pod Using RuntimeClass
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sandboxed-pod
spec:
  runtimeClassName: gvisor
  containers:
  - name: app
    image: nginx
```

#### Commands
```bash
# List runtime classes
kubectl get runtimeclass

# Describe runtime class
kubectl describe runtimeclass gvisor

# Check container runtime
crictl info | grep -i runtime
```

### 4.7 mTLS (Mutual TLS)

#### Service Mesh (Istio) - Peer Authentication
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
```

#### Authorization Policy
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
  namespace: backend
spec:
  selector:
    matchLabels:
      app: database
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/frontend/sa/frontend-sa"]
    to:
    - operation:
        methods: ["GET", "POST"]
        ports: ["3306"]
```

---

## 5. Supply Chain Security (20%)

### 5.1 Minimize Base Image Footprint

#### Multi-stage Dockerfile
```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM scratch
COPY --from=builder /app/main /main
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
USER 65534
EXPOSE 8080
ENTRYPOINT ["/main"]
```

#### Distroless Image
```dockerfile
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o app .

FROM gcr.io/distroless/static-debian11
COPY --from=builder /app/app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

#### Alpine-based Image
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache ca-certificates && \
    addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser
COPY app /app
USER appuser
ENTRYPOINT ["/app"]
```

### 5.2 Image Scanning

#### Trivy Commands
```bash
# Install Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Scan image
trivy image nginx:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL nginx:latest

# Scan and output JSON
trivy image -f json -o results.json nginx:latest

# Scan local image
trivy image myapp:1.0

# Scan filesystem
trivy fs /path/to/project

# Scan Kubernetes cluster
trivy k8s --report summary cluster
```

#### Admission Controller for Image Scanning
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: trivy-scan-pod
spec:
  containers:
  - name: trivy-scanner
    image: aquasec/trivy:latest
    command:
    - trivy
    - image
    - --exit-code
    - "1"
    - --severity
    - "CRITICAL,HIGH"
    - nginx:latest
```

### 5.3 Image Policy Webhook / ImagePolicyWebhook

#### Enable ImagePolicyWebhook Admission Plugin
```yaml
# kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - name: kube-apiserver
    command:
    - kube-apiserver
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/admission-control-config.yaml
    volumeMounts:
    - name: admission-control-config
      mountPath: /etc/kubernetes/admission-control-config.yaml
      readOnly: true
  volumes:
  - name: admission-control-config
    hostPath:
      path: /etc/kubernetes/admission-control-config.yaml
      type: File
```

#### Admission Control Configuration
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/imagepolicy-webhook-config.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
```

#### Image Policy Webhook Config
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://image-policy-webhook:8080/check-image
  name: image-policy-webhook
contexts:
- context:
    cluster: image-policy-webhook
    user: api-server
  name: image-policy-webhook
current-context: image-policy-webhook
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/pki/apiserver.crt
    client-key: /etc/kubernetes/pki/apiserver.key
```

### 5.4 Sign Images and Verify Signatures

#### Install Cosign
```bash
# Install cosign
wget https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Generate key pair
cosign generate-key-pair

# Sign an image
cosign sign --key cosign.key myregistry.io/myapp:v1.0

# Verify image signature
cosign verify --key cosign.pub myregistry.io/myapp:v1.0

# Sign with keyless (OIDC)
cosign sign myregistry.io/myapp:v1.0

# Verify with keyless
cosign verify myregistry.io/myapp:v1.0
```

#### Connaisseur Admission Controller
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: connaisseur-config
  namespace: connaisseur
data:
  config.yaml: |
    application:
      features:
        namespacedValidation:
          enabled: true
    validators:
    - name: default
      type: cosign
      trust_roots:
      - name: default
        key: |
          -----BEGIN PUBLIC KEY-----
          <YOUR_PUBLIC_KEY>
          -----END PUBLIC KEY-----
    policy:
    - pattern: "myregistry.io/*:*"
      validator: default
    - pattern: "*:*"
      validator: allow
```

### 5.5 Static Analysis (KubeSec, Kubescape)

#### KubeSec Commands
```bash
# Install kubesec
wget https://github.com/controlplaneio/kubesec/releases/download/v2.13.0/kubesec_linux_amd64.tar.gz
tar -xvf kubesec_linux_amd64.tar.gz
sudo mv kubesec /usr/local/bin/

# Scan a manifest
kubesec scan pod.yaml

# Scan with HTTP API
curl -sSX POST --data-binary @pod.yaml https://v2.kubesec.io/scan
```

#### Kubescape Commands
```bash
# Install kubescape
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash

# Scan cluster
kubescape scan

# Scan specific framework
kubescape scan framework nsa

# Scan YAML files
kubescape scan *.yaml

# Scan with control
kubescape scan control "Dangerous capabilities"

# Generate report
kubescape scan --format json --output results.json
```

### 5.6 Allow/Deny Registries

#### Using OPA/Gatekeeper
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-docker-registries
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
  parameters:
    repos:
    - "mycompany.registry.io/"
    - "gcr.io/myproject/"
```

#### Using Admission Webhook
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: registry-validation
webhooks:
- name: validate-registry.example.com
  clientConfig:
    service:
      name: registry-webhook
      namespace: default
      path: "/validate"
    caBundle: <CA_BUNDLE>
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
```

---

## 6. Monitoring, Logging & Runtime Security (20%)

### 6.1 Behavioral Analytics (Falco)

#### Install Falco
```bash
# Using Helm
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco --namespace falco --create-namespace

# Direct installation
curl -s https://falco.org/repo/falcosecurity-packages.asc | apt-key add -
echo "deb https://download.falco.org/packages/deb stable main" | tee /etc/apt/sources.list.d/falcosecurity.list
apt-get update
apt-get install -y falco

# Start Falco
systemctl start falco
systemctl enable falco

# View Falco logs
journalctl -fu falco
tail -f /var/log/falco/falco.log
```

#### Falco Custom Rules
```yaml
# /etc/falco/falco_rules.local.yaml
- rule: Terminal Shell in Container
  desc: Detect shell spawned in container
  condition: >
    spawned_process and
    container and
    proc.name in (bash, sh, zsh, fish)
  output: >
    Shell spawned in container
    (user=%user.name container=%container.name
    image=%container.image.repository:%container.image.tag
    shell=%proc.name parent=%proc.pname cmdline=%proc.cmdline)
  priority: WARNING
  tags: [container, shell, mitre_execution]

- rule: Write below /etc
  desc: Detect write operations under /etc
  condition: >
    open_write and
    container and
    fd.name startswith /etc
  output: >
    File opened for writing under /etc
    (user=%user.name command=%proc.cmdline
    file=%fd.name container=%container.name
    image=%container.image.repository)
  priority: ERROR
  tags: [filesystem, mitre_persistence]

- rule: Unauthorized Process in Container
  desc: Detect unexpected processes
  condition: >
    spawned_process and
    container and
    not proc.name in (nginx, java, python, node)
  output: >
    Unexpected process started in container
    (user=%user.name process=%proc.name
    container=%container.name
    image=%container.image.repository)
  priority: WARNING

- rule: Read Sensitive File
  desc: Detect reading of sensitive files
  condition: >
    open_read and
    container and
    fd.name in (/etc/shadow, /etc/sudoers, /root/.ssh/id_rsa)
  output: >
    Sensitive file read
    (user=%user.name file=%fd.name
    container=%container.name command=%proc.cmdline)
  priority: CRITICAL
```

#### Falco DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: falco
  namespace: falco
spec:
  selector:
    matchLabels:
      app: falco
  template:
    metadata:
      labels:
        app: falco
    spec:
      serviceAccountName: falco
      hostNetwork: true
      hostPID: true
      containers:
      - name: falco
        image: falcosecurity/falco:latest
        securityContext:
          privileged: true
        volumeMounts:
        - name: dev
          mountPath: /host/dev
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: boot
          mountPath: /host/boot
          readOnly: true
        - name: lib-modules
          mountPath: /host/lib/modules
          readOnly: true
        - name: usr
          mountPath: /host/usr
          readOnly: true
        - name: etc-falco
          mountPath: /etc/falco
      volumes:
      - name: dev
        hostPath:
          path: /dev
      - name: proc
        hostPath:
          path: /proc
      - name: boot
        hostPath:
          path: /boot
      - name: lib-modules
        hostPath:
          path: /lib/modules
      - name: usr
        hostPath:
          path: /usr
      - name: etc-falco
        configMap:
          name: falco-config
```

### 6.2 Audit Logs

#### Audit Policy File
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
- "RequestReceived"
rules:
# Log pod changes at RequestResponse level
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods"]
  verbs: ["create", "delete", "update", "patch"]

# Log secret, configmap access at Metadata level
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]

# Log all authentication and authorization at Metadata level
- level: Metadata
  omitStages:
  - "RequestReceived"
  resources:
  - group: "authentication.k8s.io"
  - group: "authorization.k8s.io"

# Log RBAC changes at RequestResponse level
- level: RequestResponse
  resources:
  - group: "rbac.authorization.k8s.io"
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]

# Log persistent volume claims
- level: Request
  resources:
  - group: ""
    resources: ["persistentvolumeclaims"]

# Log service accounts
- level: Metadata
  resources:
  - group: ""
    resources: ["serviceaccounts"]

# Don't log read-only URLs
- level: None
  nonResourceURLs:
  - "/healthz*"
  - "/version"
  - "/swagger*"

# Don't log watch
- level: None
  verbs: ["watch"]

# Don't log low-level API requests
- level: None
  users: ["system:kube-proxy"]
  verbs: ["watch"]
  resources:
  - group: ""
    resources: ["endpoints", "services"]

# Default catch-all
- level: Metadata
  omitStages:
  - "RequestReceived"
```

#### Enable Audit Logging in kube-apiserver
```yaml
# /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - name: kube-apiserver
    command:
    - kube-apiserver
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
    volumeMounts:
    - name: audit-policy
      mountPath: /etc/kubernetes/audit-policy.yaml
      readOnly: true
    - name: audit-log
      mountPath: /var/log/kubernetes/audit/
  volumes:
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/audit-policy.yaml
      type: File
  - name: audit-log
    hostPath:
      path: /var/log/kubernetes/audit/
      type: DirectoryOrCreate
```

#### Audit Log Analysis Commands
```bash
# View audit logs
tail -f /var/log/kubernetes/audit/audit.log

# Search for specific user activity
jq 'select(.user.username=="john")' /var/log/kubernetes/audit/audit.log

# Find all secret access
jq 'select(.objectRef.resource=="secrets")' /var/log/kubernetes/audit/audit.log

# Find failed requests
jq 'select(.responseStatus.code>=400)' /var/log/kubernetes/audit/audit.log

# Count requests by user
jq -r '.user.username' /var/log/kubernetes/audit/audit.log | sort | uniq -c | sort -nr

# Find pod deletions
jq 'select(.objectRef.resource=="pods" and .verb=="delete")' /var/log/kubernetes/audit/audit.log
```

### 6.3 Immutability of Containers at Runtime

#### Read-Only Root Filesystem
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: immutable-pod
spec:
  containers:
  - name: app
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
  - name: tmp
    emptyDir: {}
```

#### Deployment with Immutability
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: immutable-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: myapp:1.0
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: app-data
          mountPath: /app/data
      volumes:
      - name: tmp
        emptyDir: {}
      - name: app-data
        emptyDir: {}
```

### 6.4 Use Audit Logs to Monitor Access

#### Query Audit Logs for Suspicious Activity
```bash
# Find unauthorized access attempts
jq 'select(.responseStatus.code==403)' audit.log

# Monitor secret access
jq 'select(.objectRef.resource=="secrets" and .verb=="get")' audit.log

# Find privilege escalation attempts
jq 'select(.objectRef.resource=="pods" and 
    .requestObject.spec.containers[].securityContext.privileged==true)' audit.log

# Track service account usage
jq 'select(.user.username | startswith("system:serviceaccount"))' audit.log

# Monitor exec into pods
jq 'select(.objectRef.subresource=="exec")' audit.log

# Find anonymous access
jq 'select(.user.username=="system:anonymous")' audit.log
```

### 6.5 Container Runtime Security

#### Check for Suspicious Processes
```bash
# List all running containers
crictl ps

# Inspect container
crictl inspect <container-id>

# Execute command in container
crictl exec -it <container-id> sh

# View container logs
crictl logs <container-id>

# Check container stats
crictl stats

# List images
crictl images

# Pull image
crictl pull nginx:latest
```

#### RuntimeClass for Enhanced Security
```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: secure-runtime
handler: runc
scheduling:
  nodeSelector:
    security: high
overhead:
  podFixed:
    cpu: "100m"
    memory: "50Mi"
```

### 6.6 Investigate Security Incidents

#### Forensics Commands
```bash
# Get pod events
kubectl get events --field-selector involvedObject.name=<pod-name>

# Get pod logs (current)
kubectl logs <pod-name>

# Get pod logs (previous crashed container)
kubectl logs <pod-name> --previous

# Get all container logs in pod
kubectl logs <pod-name> --all-containers

# Describe pod for security context
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].securityContext}'

# Check which node pod is running on
kubectl get pod <pod-name> -o wide

# SSH to node and check processes
ps aux | grep <container-id>

# Check network connections
netstat -tulpn | grep <pid>

# Examine container filesystem
crictl inspect <container-id> | jq '.info.runtimeSpec.root.path'

# Copy files from container
kubectl cp <pod-name>:/path/to/file ./local-file

# Execute forensic commands
kubectl exec -it <pod-name> -- ps aux
kubectl exec -it <pod-name> -- netstat -tulpn
kubectl exec -it <pod-name> -- ls -la /

# Check resource usage
kubectl top pod <pod-name>
kubectl top node <node-name>
```

#### Incident Response Checklist
```bash
# 1. Identify affected resources
kubectl get pods -A | grep <pattern>

# 2. Collect pod information
kubectl get pod <pod-name> -o yaml > pod-manifest.yaml
kubectl describe pod <pod-name> > pod-description.txt

# 3. Collect logs
kubectl logs <pod-name> --all-containers > pod-logs.txt
kubectl logs <pod-name> --previous > previous-logs.txt

# 4. Check audit logs
grep <pod-name> /var/log/kubernetes/audit/audit.log > pod-audit.log

# 5. Check Falco alerts
journalctl -u falco | grep <pod-name> > falco-alerts.txt

# 6. Isolate affected pod (using network policy)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-pod
spec:
  podSelector:
    matchLabels:
      run: <pod-label>
  policyTypes:
  - Ingress
  - Egress
EOF

# 7. Preserve evidence
kubectl exec <pod-name> -- tar czf /tmp/evidence.tar.gz /var/log /etc
kubectl cp <pod-name>:/tmp/evidence.tar.gz ./evidence.tar.gz

# 8. Terminate compromised pod
kubectl delete pod <pod-name>
```

---

## 7. Advanced Security Topics

### 7.1 Certificate Management

#### View Certificate Details
```bash
# View kube-apiserver certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Check certificate expiration
kubeadm certs check-expiration

# View all certificates
ls -la /etc/kubernetes/pki/

# Decode certificate from secret
kubectl get secret <tls-secret> -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

#### Renew Certificates
```bash
# Renew all certificates
kubeadm certs renew all

# Renew specific certificate
kubeadm certs renew apiserver

# Manually renew certificate
kubeadm certs renew apiserver-kubelet-client

# Restart control plane pods
kubectl delete pod -n kube-system kube-apiserver-<node-name>
kubectl delete pod -n kube-system kube-controller-manager-<node-name>
kubectl delete pod -n kube-system kube-scheduler-<node-name>
```

#### Certificate Signing Request (CSR)
```bash
# Create private key
openssl genrsa -out myuser.key 2048

# Create certificate signing request
openssl req -new -key myuser.key -out myuser.csr -subj "/CN=myuser/O=devteam"

# Create CSR object
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
  request: $(cat myuser.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# Approve CSR
kubectl certificate approve myuser

# Get certificate
kubectl get csr myuser -o jsonpath='{.status.certificate}' | base64 -d > myuser.crt

# Create kubeconfig
kubectl config set-credentials myuser --client-certificate=myuser.crt --client-key=myuser.key
kubectl config set-context myuser-context --cluster=kubernetes --user=myuser
```

#### CSR YAML Example
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john-developer
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0K...
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # 1 day
  usages:
  - client auth
```

### 7.2 Kubeconfig Security

#### Secure Kubeconfig
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTi...
    server: https://kubernetes.example.com:6443
  name: production-cluster
contexts:
- context:
    cluster: production-cluster
    user: admin-user
    namespace: default
  name: production-context
current-context: production-context
users:
- name: admin-user
  user:
    client-certificate-data: LS0tLS1CRUdJTi...
    client-key-data: LS0tLS1CRUdJTi...
```

#### Kubeconfig Commands
```bash
# View current context
kubectl config current-context

# View all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Set namespace in context
kubectl config set-context --current --namespace=<namespace>

# View kubeconfig
kubectl config view

# Set credentials
kubectl config set-credentials <user> --token=<bearer-token>

# Merge kubeconfig files
KUBECONFIG=~/.kube/config:~/new-config kubectl config view --flatten > ~/.kube/merged-config
```

### 7.3 Admission Controllers

#### List Enabled Admission Controllers
```bash
# Check enabled admission controllers
kubectl exec -n kube-system kube-apiserver-<node> -- kube-apiserver -h | grep enable-admission-plugins
```

#### Common Admission Controllers Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - name: kube-apiserver
    command:
    - kube-apiserver
    - --enable-admission-plugins=NodeRestriction,PodSecurityPolicy,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,PodSecurityAdmission
    - --disable-admission-plugins=AlwaysAdmit
```

#### ValidatingWebhookConfiguration
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: security-validation
webhooks:
- name: validate-security.example.com
  clientConfig:
    service:
      name: security-webhook
      namespace: security-system
      path: "/validate"
    caBundle: LS0tLS1CRUdJTi...
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
  timeoutSeconds: 10
  failurePolicy: Fail
  namespaceSelector:
    matchLabels:
      security: enforced
```

#### MutatingWebhookConfiguration
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: security-mutation
webhooks:
- name: mutate-security.example.com
  clientConfig:
    service:
      name: security-webhook
      namespace: security-system
      path: "/mutate"
    caBundle: LS0tLS1CRUdJTi...
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
  timeoutSeconds: 10
  failurePolicy: Ignore
  reinvocationPolicy: Never
```

### 7.4 Etcd Security

#### Backup Etcd
```bash
# Backup etcd
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db

# Restore etcd
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restore \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380
```

#### Secure Etcd Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd
  namespace: kube-system
spec:
  containers:
  - name: etcd
    command:
    - etcd
    - --advertise-client-urls=https://127.0.0.1:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --client-cert-auth=true
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-client-cert-auth=true
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --data-dir=/var/lib/etcd
```

### 7.5 Kubelet Security

#### Kubelet Configuration
```yaml
# /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
serverTLSBootstrap: true
tlsCertFile: /var/lib/kubelet/pki/kubelet.crt
tlsPrivateKeyFile: /var/lib/kubelet/pki/kubelet.key
rotateCertificates: true
protectKernelDefaults: true
readOnlyPort: 0
eventRecordQPS: 5
```

#### Kubelet Commands
```bash
# Check kubelet configuration
systemctl status kubelet
cat /var/lib/kubelet/config.yaml

# View kubelet logs
journalctl -u kubelet -f

# Restart kubelet
systemctl restart kubelet

# Check kubelet metrics
curl -k https://localhost:10250/metrics

# Disable anonymous auth
# Edit /var/lib/kubelet/config.yaml
# Set authentication.anonymous.enabled: false
```

### 7.6 kube-bench Remediations

#### Common CIS Benchmark Failures and Fixes

**1.1.1 Ensure API server certificate authority file permissions**
```bash
chmod 644 /etc/kubernetes/pki/ca.crt
```

**1.1.2 Ensure API server certificate authority file ownership**
```bash
chown root:root /etc/kubernetes/pki/ca.crt
```

**1.2.1 Ensure that anonymous-auth is not enabled**
```yaml
# kube-apiserver.yaml
spec:
  containers:
  - command:
    - --anonymous-auth=false
```

**1.2.2 Ensure that basic-auth-file is not set**
```yaml
# Remove from kube-apiserver.yaml
# - --basic-auth-file=<filename>
```

**1.2.9 Ensure that AlwaysAdmit is not set**
```yaml
# kube-apiserver.yaml
spec:
  containers:
  - command:
    - --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
    # Do not include AlwaysAdmit
```

**4.2.1 Ensure anonymous-auth is not enabled on kubelet**
```yaml
# /var/lib/kubelet/config.yaml
authentication:
  anonymous:
    enabled: false
```

**4.2.2 Ensure authorization mode is not AlwaysAllow**
```yaml
# /var/lib/kubelet/config.yaml
authorization:
  mode: Webhook
```

### 7.7 Network Security

#### Pod with Host Network (Avoid)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: host-network-pod
spec:
  hostNetwork: true  # AVOID unless absolutely necessary
  hostPID: true      # AVOID
  hostIPC: true      # AVOID
  containers:
  - name: app
    image: nginx
```

#### Secure Pod Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-network-pod
spec:
  hostNetwork: false
  hostPID: false
  hostIPC: false
  containers:
  - name: app
    image: nginx
    ports:
    - containerPort: 8080
      protocol: TCP
```

#### Egress Network Policy for DNS and External API
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-and-external
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow external API
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32  # Block AWS metadata
        - 10.0.0.0/8          # Block internal network
    ports:
    - protocol: TCP
      port: 443
```

---

## 8. Quick Reference & Cheat Sheet

### Essential kubectl Commands
```bash
# Quick pod security check
kubectl get pod <pod> -o jsonpath='{.spec.securityContext}'
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].securityContext}'

# Check service accounts
kubectl get sa
kubectl describe sa <sa-name>

# Check RBAC
kubectl auth can-i <verb> <resource> --as <user>
kubectl get roles,rolebindings -A
kubectl get clusterroles,clusterrolebindings

# Network policies
kubectl get netpol -A
kubectl describe netpol <policy>

# Secrets
kubectl get secrets
kubectl create secret generic <name> --from-literal=key=value

# Check pod's service account token
kubectl exec <pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Get pod on specific node
kubectl get pods --field-selector spec.nodeName=<node>

# Drain node
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Cordon/uncordon node
kubectl cordon <node>
kubectl uncordon <node>
```

### Security Context Quick Reference
```yaml
# Pod Level
securityContext:
  runAsUser: 1000          # Run as user ID
  runAsGroup: 3000         # Run as group ID
  fsGroup: 2000            # Filesystem group
  runAsNonRoot: true       # Require non-root
  supplementalGroups: [4000]
  seccompProfile:
    type: RuntimeDefault   # or Localhost

# Container Level
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE
  seccompProfile:
    type: RuntimeDefault
```

### Network Policy Quick Reference
```yaml
# Deny all ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress

# Deny all egress
spec:
  podSelector: {}
  policyTypes:
  - Egress

# Allow specific ingress
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### Common File Locations
```bash
# Kubernetes configuration
/etc/kubernetes/manifests/           # Static pod manifests
/etc/kubernetes/pki/                 # Certificates
/var/lib/kubelet/                    # Kubelet data
/var/lib/kubelet/config.yaml         # Kubelet configuration
/etc/kubernetes/admission-control/   # Admission control configs

# Etcd
/var/lib/etcd/                       # Etcd data directory

# Logs
/var/log/kubernetes/audit/           # Audit logs
/var/log/pods/                       # Pod logs
journalctl -u kubelet                # Kubelet logs
journalctl -u etcd                   # Etcd logs

# AppArmor
/etc/apparmor.d/                     # AppArmor profiles

# Seccomp
/var/lib/kubelet/seccomp/            # Seccomp profiles

# Falco
/etc/falco/                          # Falco configuration
/var/log/falco/                      # Falco logs
```

### Exam Tips

1. **Time Management**
   - Exam is 2 hours
   - 15-20 performance-based questions
   - Passing score: 67%
   - Practice speed and accuracy

2. **Allowed Resources**
   - kubernetes.io/docs
   - kubernetes.io/blog
   - github.com/kubernetes
   - Use browser bookmarks

3. **Key Focus Areas**
   - Network Policies (practice extensively)
   - RBAC (roles, rolebindings)
   - Security Contexts
   - Secrets management
   - Audit logs
   - AppArmor/Seccomp
   - Image security (scanning, signing)
   - Falco rules

4. **Common Tasks**
   - Create network policies
   - Configure RBAC
   - Secure pods with security contexts
   - Enable audit logging
   - Use AppArmor profiles
   - Scan images with Trivy
   - Analyze Falco outputs
   - Fix CIS benchmark failures

5. **Command Line Efficiency**
   - Use aliases: `alias k=kubectl`
   - Use auto-completion
   - Practice YAML generation with `--dry-run=client -o yaml`
   - Master `kubectl explain` for field documentation

6. **Common Mistakes to Avoid**
   - Forgetting to specify namespace
   - Not verifying changes
   - Incorrect YAML indentation
   - Not reading questions carefully
   - Spending too much time on one question

### Practice Scenarios

#### Scenario 1: Secure a Pod
```bash
# Task: Create a pod that runs as non-root with read-only filesystem
kubectl run secure-pod --image=nginx --dry-run=client -o yaml > pod.yaml
# Edit pod.yaml to add security context
kubectl apply -f pod.yaml
kubectl get pod secure-pod -o jsonpath='{.spec.securityContext}'
```

#### Scenario 2: Implement Network Policy
```bash
# Task: Create network policy allowing only frontend pods to access backend
cat > netpol.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
EOF
kubectl apply -f netpol.yaml
```

#### Scenario 3: Create RBAC
```bash
# Task: Create role for pod reader and bind to user
kubectl create role pod-reader --verb=get,list,watch --resource=pods
kubectl create rolebinding pod-reader-binding --role=pod-reader --user=john
kubectl auth can-i list pods --as john
```

#### Scenario 4: Enable Audit Logging
```bash
# Task: Configure audit logging for secrets access
# 1. Create audit policy at /etc/kubernetes/audit-policy.yaml
# 2. Edit /etc/kubernetes/manifests/kube-apiserver.yaml
# 3. Add audit flags and volume mounts
# 4. Wait for apiserver to restart
# 5. Verify logs at /var/log/kubernetes/audit/audit.log
```

---

## 9. Troubleshooting Guide

### Pod Not Starting

```bash
# Check pod status
kubectl get pod <pod-name>
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Common issues:
# - Image pull errors: Check imagePullSecrets
# - Security context violations: Check PSA/PSP
# - Resource constraints: Check resource requests/limits
# - Network policy blocking: Check network policies
```

### Network Policy Not Working

```bash
# Verify CNI plugin supports network policies
kubectl get pods -n kube-system | grep -E 'calico|cilium|weave'

# Check network policy
kubectl get netpol -A
kubectl describe netpol <policy-name>

# Test connectivity
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod: nc -zv <target-service> <port>

# Common issues:
# - CNI plugin doesn't support network policies
# - Label selectors don't match
# - Missing egress rules for DNS
```

### RBAC Permission Denied

```bash
# Check current permissions
kubectl auth can-i <verb> <resource>

# Check roles and bindings
kubectl get roles,rolebindings -A | grep <user-or-sa>
kubectl describe role <role-name>
kubectl describe rolebinding <binding-name>

# Check service account
kubectl get sa
kubectl describe sa <sa-name>

# Common issues:
# - Wrong namespace
# - Service account not bound to role
# - Missing verb in role
```

### Secrets Not Mounting

```bash
# Check secret exists
kubectl get secret <secret-name>
kubectl describe secret <secret-name>

# Check pod manifest
kubectl get pod <pod> -o yaml | grep -A 10 volumes

# Check mounted secrets in pod
kubectl exec <pod> -- ls -la /path/to/secret

# Common issues:
# - Secret doesn't exist in namespace
# - Wrong secret name in manifest
# - Wrong mount path
# - Permissions on secret
```

---

## 10. Additional Resources

### Important Documentation Links
- Kubernetes Security: https://kubernetes.io/docs/concepts/security/
- Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
- Network Policies: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- Audit Logging: https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/

### Security Tools
- **Trivy**: Container image scanning
- **Falco**: Runtime security monitoring
- **kube-bench**: CIS benchmark checker
- **kubescape**: Security posture assessment
- **OPA Gatekeeper**: Policy enforcement
- **Cosign**: Container signing

### Best Practices Summary

1. **Always use least privilege** - RBAC, network policies, security contexts
2. **Never run as root** - Use runAsNonRoot: true
3. **Use read-only filesystems** - readOnlyRootFilesystem: true
4. **Drop all capabilities** - capabilities.drop: [ALL]
5. **Scan images regularly** - Use Trivy or similar
6. **Enable audit logging** - Monitor all API access
7. **Use network policies** - Default deny all, then allow specific
8. **Encrypt secrets at rest** - Use encryption configuration
9. **Rotate credentials** - Regularly update certificates and secrets
10. **Monitor runtime behavior** - Use Falco for detection

---

## Study Plan Recommendation

### Week 1-2: Foundation
- Kubernetes security architecture
- RBAC concepts and practice
- Security contexts
- Network policies basics

### Week 3-4: Advanced Security
- Pod Security Standards/Admission
- Secrets management and encryption
- Image security and scanning
- Supply chain security

### Week 5-6: Monitoring & Response
- Audit logging
- Falco rules and alerts
- Incident response
- Runtime security

### Week 7-8: Practice & Review
- Complete practice exams
- Time-based exercises
- Review weak areas
- Optimize speed

**Good luck with your CKS exam preparation!**