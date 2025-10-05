# Certified Kubernetes Security Specialist (CKS) Study Guide - Comprehensive Summary

## Table of Contents
1. [Exam Details and Resources](#chapter-1-exam-details-and-resources)
2. [Cluster Setup](#chapter-2-cluster-setup)
3. [Cluster Hardening](#chapter-3-cluster-hardening)
4. [System Hardening](#chapter-4-system-hardening)
5. [Minimizing Microservice Vulnerabilities](#chapter-5-minimizing-microservice-vulnerabilities)
6. [Supply Chain Security](#chapter-6-supply-chain-security)
7. [Monitoring, Logging, and Runtime Security](#chapter-7-monitoring-logging-and-runtime-security)

---

## Chapter 1: Exam Details and Resources

### Kubernetes Certification Learning Path
- **KCNA (Kubernetes and Cloud Native Associate)**: Entry-level certification for cloud-native application development
- **KCSA (Kubernetes and Cloud Native Security Associate)**: Basic knowledge of security concepts in Kubernetes
- **CKAD (Certified Kubernetes Application Developer)**: Focus on building, configuring, and deploying microservices
- **CKA (Certified Kubernetes Administrator)**: Tests administrator abilities (cluster, network, storage management)
- **CKS (Certified Kubernetes Security Specialist)**: Advanced security aspects (requires CKA as prerequisite)

### Exam Curriculum (Kubernetes 1.26)
- **10%**: Cluster Setup
- **15%**: Cluster Hardening
- **15%**: System Hardening
- **20%**: Minimize Microservice Vulnerabilities
- **20%**: Supply Chain Security
- **20%**: Monitoring, Logging, and Runtime Security

### Key Kubernetes Primitives
- Core resources: Pods, Services, Deployments, ConfigMaps, Secrets
- Security-related: NetworkPolicy, ServiceAccount, Role, RoleBinding, ClusterRole, ClusterRoleBinding
- Custom Resource Definitions (CRDs) from projects like OPA Gatekeeper

### External Tools Required
- **kube-bench**: CIS benchmark verification
- **AppArmor**: Linux application access control
- **seccomp**: System call restriction
- **gVisor/Kata Containers**: Container runtime sandboxes
- **Trivy**: Container vulnerability scanning
- **Falco**: Runtime behavior analytics

### Permitted Documentation During Exam
- Kubernetes documentation: https://kubernetes.io/docs
- GitHub: https://github.com/kubernetes
- Kubernetes blog: https://kubernetes.io/blog
- Tool-specific documentation for Trivy, Falco, and AppArmor

---

## Chapter 2: Cluster Setup

### Network Policies for Pod-to-Pod Communication

#### Default Behavior
- Pods can communicate freely across namespaces without restrictions
- Every Pod gets unique IP address from Pod CIDR range
- IP addresses are ephemeral (change on restart)

#### Network Policy Components
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: target-namespace
spec:
  podSelector: {}  # {} selects all pods
  policyTypes:
  - Ingress
  - Egress
```

#### Best Practices
1. Start with deny-all policy (principle of least privilege)
2. Add specific allow rules as needed
3. Use label selectors for pod and namespace selection
4. Network policies are additive (multiple policies combine)

### CIS Benchmark and kube-bench

#### Installation and Execution
```bash
# Run on control plane
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-master.yaml

# Run on worker nodes
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-node.yaml

# Check results
kubectl logs kube-bench-master-[pod-hash]
```

#### Fixing Security Issues
1. Locate configuration files in `/etc/kubernetes/manifests/`
2. Common fixes:
   - Enable admission plugins (e.g., AlwaysPullImages)
   - Set appropriate file permissions (644 or more restrictive)
   - Configure certificate authorities properly

### Ingress with TLS Termination

#### Setup Process
1. **Create TLS certificate and key**:
   ```bash
   openssl req -nodes -new -x509 -keyout accounting.key -out accounting.crt \
     -subj "/CN=accounting.tls"
   ```

2. **Create TLS Secret**:
   ```bash
   kubectl create secret tls accounting-secret \
     --cert=accounting.crt --key=accounting.key -n namespace
   ```

3. **Configure Ingress**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: accounting-ingress
   spec:
     tls:
     - hosts:
       - accounting.internal.acme.com
       secretName: accounting-secret
     rules:
     - host: accounting.internal.acme.com
       http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: accounting-service
               port:
                 number: 80
   ```

### Protecting Node Metadata and Endpoints

#### Default Kubernetes Ports
**Control Plane (Inbound)**:
- 6443: Kubernetes API server
- 2379-2380: etcd server client API
- 10250: Kubelet API
- 10259: kube-scheduler
- 10257: kube-controller-manager

**Worker Nodes (Inbound)**:
- 10250: Kubelet API
- 30000-32767: NodePort Services

#### Cloud Provider Metadata Protection
- AWS metadata server: 169.254.169.254
- Use network policies to block egress to metadata endpoints:
```yaml
egress:
- to:
  - ipBlock:
      cidr: 0.0.0.0/0
      except:
      - 169.254.169.254/32
```

### Kubernetes Dashboard Security

#### Installation
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.0/aio/deploy/recommended.yaml
```

#### Creating Users with Different Privileges
1. **Admin user**: Full cluster-wide permissions
2. **Restricted user**: Read-only or namespace-specific permissions

#### Security Configuration
- Avoid `--insecure-port` flag
- Never use `--enable-insecure-login`
- Don't set `--enable-skip-login`
- Always use HTTPS with proper certificates

### Verifying Platform Binaries

#### Hash Verification Process
1. Download binary and SHA256 hash:
   ```bash
   curl -LO "https://dl.k8s.io/v1.26.1/bin/linux/amd64/kubeadm"
   curl -LO "https://dl.k8s.io/v1.26.1/bin/linux/amd64/kubeadm.sha256"
   ```

2. Verify checksum:
   ```bash
   echo "$(cat kubeadm.sha256) kubeadm" | shasum -a 256 --check
   ```

---

## Chapter 3: Cluster Hardening

### Kubernetes API Request Processing

#### Processing Stages
1. **Authentication**: Validates caller identity (certificates, bearer tokens)
2. **Authorization**: Checks if identity can access requested resources (RBAC)
3. **Admission Control**: Validates/modifies request (webhooks, policies)
4. **Validation**: Ensures resource format is correct

### API Server Access Methods

#### Anonymous Access
- Accepted but mapped to `system:anonymous` user
- No permissions by default

#### Client Certificate Access
```bash
# Extract certificates from kubeconfig
kubectl config view --raw

# Make authenticated request
curl --cacert ca --cert client.crt --key client.key \
  https://api-server:6443/api/v1/namespaces
```

#### Service Account Access
- Uses bearer token at `/var/run/secrets/kubernetes.io/serviceaccount/token`
- Can be disabled with `automountServiceAccountToken: false`

### User Management and RBAC

#### Creating Users
1. Generate private key:
   ```bash
   openssl genrsa -out johndoe.key 2048
   ```

2. Create CSR:
   ```bash
   openssl req -new -key johndoe.key -out johndoe.csr
   ```

3. Create CertificateSigningRequest object
4. Approve and export certificate
5. Create Role and RoleBinding
6. Add user to kubeconfig

#### Service Account Best Practices
- Disable token automounting when not needed
- Use minimal permissions (principle of least privilege)
- Create tokens with expiration (`--duration`)
- Manually create Secret for service account if needed

### RBAC Configuration

#### Role Definition
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "create", "update", "delete"]
```

#### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
subjects:
- kind: User
  name: johndoe
- kind: ServiceAccount
  name: sa-api
roleRef:
  kind: Role
  name: developer
```

### Kubernetes Version Management

#### Versioning Scheme
- Follows semantic versioning: MAJOR.MINOR.PATCH
- New minor version every 3 months
- Security fixes backported to last 2 minor releases

#### Upgrade Process
1. Always upgrade incrementally (1.23 → 1.24, not 1.23 → 1.25)
2. Order: Control plane first, then worker nodes
3. Steps per node:
   - Upgrade kubeadm
   - Apply upgrade
   - Drain node
   - Upgrade kubelet and kubectl
   - Restart kubelet
   - Uncordon node

---

## Chapter 4: System Hardening

### Minimizing Host OS Footprint

#### Disabling Unnecessary Services
```bash
# List running services
systemctl | grep running

# Stop and disable service
sudo systemctl stop snapd
sudo systemctl disable snapd
```

#### Removing Packages
```bash
# Remove package and dependencies
sudo apt purge --auto-remove snapd
```

### User and Group Management

#### User Operations
```bash
# Add user
sudo adduser ben

# Switch user
su - ben

# Delete user with home directory
sudo userdel -r ben
```

#### Group Operations
```bash
# Create group
sudo groupadd kube-developers

# Add user to group
sudo usermod -g kube-developers ben

# Delete group
sudo groupdel kube-developers
```

### File Permissions

#### Viewing Permissions
```bash
ls -l
# Output: -rw-r--r-- (owner-group-others)
```

#### Modifying Permissions
```bash
# Change ownership
chown ben:developers file.txt

# Change permissions
chmod 644 file.txt
```

### Network Security

#### Port Management
```bash
# Check open ports
sudo ss -ltpn

# Identify process on port
sudo lsof -i :80
```

#### Firewall Configuration (UFW)
```bash
# Enable firewall
sudo ufw enable

# Set default policies
sudo ufw default deny incoming
sudo ufw default deny outgoing

# Allow specific ports
sudo ufw allow 6443  # API server
sudo ufw allow ssh
```

### Kernel Hardening Tools

#### AppArmor

**Profile Creation** (`/etc/apparmor.d/k8s-deny-write`):
```
#include <tunables/global>
profile k8s-deny-write flags=(attach_disconnected) {
  #include <abstractions/base>
  file,
  deny /** w,
}
```

**Loading Profile**:
```bash
sudo apparmor_parser /etc/apparmor.d/k8s-deny-write
```

**Pod Configuration**:
```yaml
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/container-name: localhost/k8s-deny-write
```

#### seccomp

**Profile Location**: `/var/lib/kubelet/seccomp/profiles/`

**Custom Profile Example**:
```json
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [
    {
      "names": ["mkdir"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```

**Pod Configuration**:
```yaml
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/custom.json
```

---

## Chapter 5: Minimizing Microservice Vulnerabilities

### Security Contexts

#### Container-Level Security
```yaml
spec:
  containers:
  - name: app
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 3000
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
```

#### Pod-Level Security
```yaml
spec:
  securityContext:
    runAsUser: 1000
    fsGroup: 2000
    supplementalGroups: [3000, 4000]
```

### Pod Security Admission (PSA)

#### Configuration Levels
- **privileged**: Unrestricted
- **baseline**: Minimal restrictions
- **restricted**: Maximum security

#### Namespace Labels
```yaml
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/warn: baseline
```

### Open Policy Agent (OPA) Gatekeeper

#### Installation
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

#### Constraint Template Example
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
      violation[{"msg": msg}] {
        required := {label | label := input.parameters.labels[_]}
        provided := {label | input.review.object.metadata.labels[label]}
        missing := required - provided
        count(missing) > 0
        msg := sprintf("Missing required labels: %v", [missing])
      }
```

### Secrets Management

#### etcd Encryption

**Create Encryption Configuration** (`/etc/kubernetes/enc/enc.yaml`):
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: <base64-encoded-32-byte-key>
  - identity: {}
```

**Configure API Server**:
```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
```

**Encrypt Existing Secrets**:
```bash
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
```

### Container Runtime Sandboxes

#### gVisor Setup

**Install runsc**:
```bash
sudo apt-get install -y runsc
```

**Configure containerd** (`/etc/containerd/config.toml`):
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
```

**RuntimeClass Definition**:
```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
```

**Pod Usage**:
```yaml
spec:
  runtimeClassName: gvisor
```

### mTLS for Pod-to-Pod Communication

#### Key Concepts
- Default Pod-to-Pod communication is unencrypted
- mTLS provides encryption and mutual authentication
- Certificate management is complex at scale

#### Implementation Options
- Service meshes (Linkerd, Istio)
- CNI plugins with WireGuard support (Calico, Cilium)
- Manual certificate management (not recommended for production)

---

## Chapter 6: Supply Chain Security

### Container Image Optimization

#### Base Image Selection
- **Standard images**: Can be 1GB+ in size
- **Alpine images**: ~7MB, includes shell
- **Distroless images**: ~2MB, no shell, minimal attack surface

#### Multi-Stage Dockerfiles
```dockerfile
# Build stage
FROM golang:1.19.4-alpine AS build
WORKDIR /tmp/app
COPY . .
RUN go test -v
RUN go build -o ./out/app .

# Runtime stage
FROM alpine:3.17.0
COPY --from=build /tmp/app/out/app /app/app
CMD ["/app/app"]
```

#### Layer Optimization
```dockerfile
# Bad: Multiple RUN commands create multiple layers
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y curl

# Good: Single RUN command creates one layer
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y curl
```

### Container Image Security

#### Image Signing and Verification
```yaml
# Pod with image digest
spec:
  containers:
  - name: app
    image: alpine@sha256:c0d488a800e4127c334ad20d61d7bc21b4097540327217dfab52262adc02380c
```

#### Registry Whitelisting with OPA Gatekeeper

**Constraint Template**: Validates image prefixes
**Constraint Example**:
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: repo-is-gcr
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
  parameters:
    repos:
    - "gcr.io/"
    - "my-registry.company.com/"
```

#### ImagePolicyWebhook Configuration

**Admission Configuration**:
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission-control/imagepolicywebhook.kubeconfig
      allowTTL: 50
      denyTTL: 50
      defaultAllow: false
```

**API Server Flags**:
```
--enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
--admission-control-config-file=/etc/kubernetes/admission-control/config.yaml
```

### Static Analysis Tools

#### Hadolint (Dockerfile Analysis)
```bash
hadolint Dockerfile
```

Common Issues:
- Missing version tags
- No WORKDIR set
- Using latest tag
- Multiple RUN commands

#### Kubesec (Kubernetes Manifest Analysis)
```bash
docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < pod.yaml
```

Recommendations:
- Set resource limits
- Run as non-root
- Drop capabilities
- Use read-only filesystem

### Vulnerability Scanning with Trivy

#### Installation and Usage
```bash
# Scan image
trivy image python:3.4-alpine

# Output includes:
# - Library/package name
# - Vulnerability ID
# - Severity (LOW, MEDIUM, HIGH, CRITICAL)
# - Fixed version
```

#### Best Practices
- Fix HIGH and CRITICAL vulnerabilities
- Scan images before deployment
- Integrate into CI/CD pipeline
- Regular rescanning of deployed images

---

## Chapter 7: Monitoring, Logging, and Runtime Security

### Falco - Runtime Security Monitoring

#### Installation
```bash
# Add repository
curl -s https://falco.org/repo/falcosecurity-packages.asc | apt-key add -
echo "deb https://download.falco.org/packages/deb stable main" | tee -a /etc/apt/sources.list.d/falcosecurity.list

# Install
apt-get update -y
apt-get install -y falco=0.33.1
```

#### Configuration Files
- `/etc/falco/falco.yaml`: Main configuration
- `/etc/falco/falco_rules.yaml`: Default rules
- `/etc/falco/falco_rules.local.yaml`: Custom rules
- `/etc/falco/k8s_audit_rules.yaml`: Kubernetes-specific rules

#### Rule Components

**Rule Structure**:
```yaml
- rule: Terminal shell in container
  desc: Shell opened in container
  condition: >
    spawned_process and container
    and shell_procs and proc.tty != 0
    and container_entrypoint
  output: >
    Shell opened: %evt.time,%user.name,%container.name
  priority: ALERT
  tags: [container, shell]
```

**Macros** (Reusable conditions):
```yaml
- macro: container
  condition: (container.id != host)
```

**Lists** (Reusable arrays):
```yaml
- list: shell_binaries
  items: [bash, sh, zsh]
```

#### Managing Falco
```bash
# Check status
sudo systemctl status falco

# View logs
sudo journalctl -fu falco

# Restart after config changes
sudo systemctl restart falco
```

### Container Immutability

#### Key Principles
1. Use distroless base images (no shell)
2. Configure read-only root filesystem
3. Use ConfigMaps/Secrets for configuration
4. Mount volumes for required write paths

#### Implementation
```yaml
spec:
  containers:
  - name: nginx
    image: nginx:1.21.6
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: nginx-run
      mountPath: /var/run
    - name: nginx-cache
      mountPath: /var/cache/nginx
  volumes:
  - name: nginx-run
    emptyDir: {}
  - name: nginx-cache
    emptyDir: {}
```

### Audit Logging

#### Audit Policy Configuration
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
- "RequestReceived"
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods", "services"]
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
```

#### Audit Levels
- **None**: Don't log
- **Metadata**: Log request metadata only
- **Request**: Log metadata and request body
- **RequestResponse**: Log metadata, request, and response

#### File Backend Configuration

**API Server Configuration**:
```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
```

#### Webhook Backend Configuration
```yaml
- --audit-webhook-config-file=/etc/kubernetes/webhook-config.yaml
- --audit-webhook-initial-backoff=10
```

### Behavior Analytics Best Practices

#### Detection Scenarios
- Shell access to containers
- Write operations to system directories
- Package manager execution in containers
- Unexpected network connections
- Privilege escalation attempts

#### Response Actions
1. Alert generation (email, Slack, PagerDuty)
2. Automatic remediation (kill process, isolate pod)
3. Evidence collection for forensics
4. Incident response workflow triggering

---

## Exam Preparation Tips

### Essential Skills by Domain

#### Cluster Setup (10%)
- Configure network policies effectively
- Run and interpret kube-bench results
- Set up Ingress with TLS
- Secure Dashboard access
- Verify binary checksums

#### Cluster Hardening (15%)
- Create and manage users with RBAC
- Configure service accounts properly
- Perform cluster upgrades
- Restrict API server access

#### System Hardening (15%)
- Manage Linux users and permissions
- Configure firewall rules
- Set up AppArmor profiles
- Configure seccomp profiles

#### Minimize Microservice Vulnerabilities (20%)
- Configure security contexts
- Implement PSA and OPA Gatekeeper policies
- Encrypt etcd
- Set up container runtime sandboxes

#### Supply Chain Security (20%)
- Optimize container images
- Configure image policies
- Use static analysis tools
- Scan for vulnerabilities with Trivy

#### Monitoring & Logging (20%)
- Configure Falco rules
- Set up audit logging
- Ensure container immutability

### Time Management
- Practice with time limits
- Know when to use imperative vs declarative approaches
- Bookmark important documentation pages
- Use aliases and shortcuts where appropriate

### Common Pitfalls to Avoid
1. Not reading questions carefully
2. Forgetting to specify namespaces
3. Missing YAML indentation errors
4. Not verifying changes after applying
5. Spending too much time on one question

---

## Quick Reference Commands

### Network Policies
```bash
# Test connectivity
kubectl exec pod1 -- wget --spider --timeout=1 pod2-ip:port

# List network policies
kubectl get networkpolicies -A
```

### Security Scanning
```bash
# Scan with Trivy
trivy image nginx:latest

# Run kube-bench
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-master.yaml
```

### RBAC
```bash
# Check permissions
kubectl auth can-i create pods --as=john

# Create role
kubectl create role dev --verb=get,list --resource=pods

# Create rolebinding
kubectl create rolebinding dev-binding --role=dev --user=john
```

### Secrets and Encryption
```bash
# Create TLS secret
kubectl create secret tls my-tls --cert=cert.crt --key=cert.key

# Check etcd encryption
sudo ETCDCTL_API=3 etcdctl get /registry/secrets/default/my-secret
```

### System Tools
```bash
# AppArmor
sudo apparmor_parser /etc/apparmor.d/profile
sudo aa-status

# Check open ports
sudo ss -ltpn
sudo lsof -i :port

# Firewall
sudo ufw allow 6443
sudo ufw status
```

### Monitoring
```bash
# Falco
sudo systemctl status falco
sudo journalctl -fu falco

# Audit logs
grep 'audit.k8s.io/v1' /var/log/kubernetes/audit/audit.log
```

---

## Additional Resources

### Official Documentation
- Kubernetes Security: https://kubernetes.io/docs/concepts/security/
- CKS Exam Guide: https://www.cncf.io/certification/cks/
- CKS FAQ: https://docs.linuxfoundation.org/tc-docs/certification/faq-cks

### Tools Documentation
- Falco: https://falco.org/docs/
- Trivy: https://aquasecurity.github.io/trivy/
- OPA Gatekeeper: https://open-policy-agent.github.io/gatekeeper/
- kube-bench: https://github.com/aquasecurity/kube-bench

### Practice Resources
- Killer Shell: CKS practice scenarios
- O'Reilly Learning Platform: Interactive labs
- GitHub: bmuschko/cks-study-guide (exercise solutions)

### Books and Courses
- Container Security by Liz Rice
- Practical Cloud Native Security with Falco
- Falco 101 (free video course)
- Managing Kubernetes by Burns and Tracey
