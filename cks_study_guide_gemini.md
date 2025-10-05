# CKS Study Guide - Detailed Chapter Summaries

This document provides a detailed summary of each chapter from the "Certified Kubernetes Security Specialist (CKS) Study Guide" by Benjamin Muschko. It is intended as a comprehensive reference and review tool.

## Chapter 1: Exam Details and Resources

This chapter provides an overview of the CKS certification, its place within the CNCF certification path, and the structure of the exam.

### Kubernetes Certification Learning Path
The CNCF offers a tiered certification path:
* **Associate Level**:
    * [cite_start]**KCNA (Kubernetes and Cloud Native Associate)**: Entry-level, conceptual knowledge of the cloud-native ecosystem. [cite: 148]
    * [cite_start]**KCSA (Kubernetes and Cloud Native Security Associate)**: Entry-level, focuses on basic security concepts. [cite: 151]
* **Developer Level**:
    * [cite_start]**CKAD (Certified Kubernetes Application Developer)**: For developers, focuses on building, configuring, and deploying applications on Kubernetes. [cite: 153]
* **Administrator Level**:
    * [cite_start]**CKA (Certified Kubernetes Administrator)**: For administrators, covers cluster management, networking, storage, and basic security. [cite: 155] [cite_start]A prerequisite for the CKS exam. [cite: 158]
    * [cite_start]**CKS (Certified Kubernetes Security Specialist)**: The most advanced certification, requiring deep knowledge of Kubernetes security features and third-party tools. [cite: 144, 157, 159]

### CKS Exam Objectives & Curriculum
[cite_start]The CKS exam is a performance-based test focused on securing Kubernetes clusters and cloud-native applications. [cite: 12, 14, 163]

[cite_start]**Exam Domains and Weights**[cite: 173]:
* [cite_start]**Cluster Setup (10%)**: Covers Network Policies, Ingress with TLS, using tools like `kube-bench` to find vulnerabilities, protecting node endpoints and GUIs, and verifying Kubernetes binaries. [cite: 178, 180, 182, 184, 187, 189]
* [cite_start]**Cluster Hardening (15%)**: Focuses on restricting API server access, using Role-Based Access Control (RBAC) effectively, securing service accounts, and the importance of frequent Kubernetes upgrades. [cite: 191, 195, 196]
* [cite_start]**System Hardening (15%)**: Deals with securing the underlying host OS by minimizing its footprint, managing IAM roles, restricting network access, and using kernel hardening tools like `AppArmor` and `seccomp`. [cite: 198, 199]
* [cite_start]**Minimize Microservice Vulnerabilities (20%)**: Involves using Security Contexts, Pod Security Admission (PSA), OPA Gatekeeper, managing Secrets (including etcd encryption), using container runtime sandboxes (`gVisor`), and mTLS for pod-to-pod encryption. [cite: 202, 204, 205, 207, 209]
* [cite_start]**Supply Chain Security (20%)**: Focuses on building secure container images (minimizing base images), signing images, whitelisting trusted container registries, static analysis of manifests, and scanning images for vulnerabilities with tools like `Trivy`. [cite: 210, 211, 213, 214]
* [cite_start]**Monitoring, Logging, and Runtime Security (20%)**: Covers behavior analytics with tools like `Falco`, ensuring container immutability at runtime, and configuring and using Kubernetes audit logs to monitor access. [cite: 216, 217, 218, 220, 221]

### Involved Tools and Resources
* [cite_start]**External Tools**: The exam requires proficiency with several external tools [cite: 228][cite_start]: `kube-bench`, `AppArmor`, `seccomp`, `gVisor`, `Kata Containers`, `Trivy`, and `Falco`. [cite: 230]
* [cite_start]**Allowed Documentation**: During the exam, you can access the official Kubernetes documentation, blog, and GitHub, as well as the documentation for `Trivy`, `Falco`, and `AppArmor`. [cite: 231, 233]

---

## Chapter 2: Cluster Setup

This chapter details the foundational steps for securing a Kubernetes cluster's configuration and network communication.

### Using Network Policies to Restrict Pod-to-Pod Communication
* **Default Behavior**: By default, all pods in a cluster can communicate with all other pods, regardless of namespace. [cite_start]This creates a large attack surface. [cite: 275, 284]
* **Principle of Least Privilege**: The best practice is to start with a "deny-all" `NetworkPolicy` and then explicitly allow required traffic.
    * [cite_start]A **deny-all ingress** policy can be created by targeting all pods (`podSelector: {}`) and specifying `policyTypes: [Ingress]`. [cite: 308, 309]
* **Fine-Grained Rules**: Create additional `NetworkPolicy` objects to allow specific traffic. [cite_start]These rules are additive. [cite: 319]
    * [cite_start]Policies use label selectors (`podSelector` and `namespaceSelector`) to define which pods are the source (`from`) and destination (`podSelector`) of traffic. [cite: 322]
    * [cite_start]You can also specify rules based on ports and protocols. [cite: 328]

### Applying Kubernetes Component Security Best Practices with `kube-bench`
* [cite_start]**CIS Benchmark**: The Center for Internet Security (CIS) provides a benchmark with security best practices for Kubernetes. [cite: 337, 338]
* [cite_start]**`kube-bench`**: This tool automates checking a cluster against the CIS Benchmark. [cite: 344]
    * [cite_start]**Execution**: It can be run as a Job in the cluster using a manifest file. [cite: 347]
    * [cite_start]**Interpreting Results**: The output log shows `[PASS]`, `[FAIL]`, and `[WARN]` for each check and provides remediation steps for failures and warnings. [cite: 355-365]
    * **Fixing Issues**: To fix a reported issue, you typically need to edit the static pod manifest for the relevant component (e.g., `/etc/kubernetes/manifests/kube-apiserver.yaml`), add or modify command-line arguments, and save the file. [cite_start]The `kubelet` will automatically restart the component's pod. [cite: 370, 375, 376]

### Creating an Ingress with TLS Termination
* **Purpose**: To securely expose services to the outside world using HTTPS. [cite_start]The Ingress controller handles the TLS handshake, terminating the encrypted connection and forwarding unencrypted traffic to the backend service. [cite: 380, 393]
* **Steps**:
    1.  [cite_start]**Set up the backend**: Create the `Deployment` and `Service` that the Ingress will route traffic to. [cite: 396]
    2.  [cite_start]**Generate TLS Certificate and Key**: Use a tool like `openssl` to create a certificate (`.crt`) and a private key (`.key`). [cite: 407]
    3.  **Create a TLS Secret**: Create a Kubernetes `Secret` of `type: kubernetes.io/tls` from the certificate and key files. [cite_start]This can be done imperatively: `kubectl create secret tls <secret-name> --cert=<cert-file> --key=<key-file>`. [cite: 409, 411]
    4.  **Create the Ingress**: Define an `Ingress` resource. The `spec.tls` section references the created Secret and the hosts it applies to. [cite_start]The `spec.rules` section maps hosts and paths to the backend service. [cite: 419, 420]

### Protecting Node Metadata and Endpoints
* **Default Ports**: Kubernetes components on control-plane and worker nodes listen on specific default ports (e.g., API server on 6443, kubelet on 10250). [cite_start]These should be protected by firewall rules. [cite: 431, 434, 438, 440]
* [cite_start]**Cloud Provider Metadata Services**: Cloud environments (AWS, GCP, Azure) expose a metadata service at a well-known IP address (e.g., `169.254.169.254` on AWS) that can leak sensitive data like credentials to compromised pods. [cite: 442, 451]
* [cite_start]**Mitigation**: Use a `NetworkPolicy` to create an egress rule that denies traffic from pods to the metadata service IP address. [cite: 455]

### Protecting GUI Elements (Kubernetes Dashboard)
* [cite_start]**Risk**: An improperly secured Kubernetes Dashboard can grant attackers full administrative access to the cluster. [cite: 472]
* **Secure Access**: Access should be managed via RBAC.
* **Creating Users with Restricted Privileges**:
    1.  [cite_start]Create a `ServiceAccount` for the user. [cite: 486]
    2.  [cite_start]Create a `ClusterRole` (or `Role`) that defines the specific permissions (e.g., `get`, `list` on `pods`). [cite: 504]
    3.  [cite_start]Create a `ClusterRoleBinding` (or `RoleBinding`) to link the `ServiceAccount` to the `Role`. [cite: 504]
    4.  [cite_start]Generate a long-lived bearer token for the `ServiceAccount`: `kubectl create token <sa-name>`. [cite: 489]
    5.  [cite_start]Use this token to log in to the Dashboard. [cite: 496]
* [cite_start]**Insecure Arguments to Avoid**: Do not use flags like `--enable-insecure-login` or `--enable-skip-login` when deploying the dashboard. [cite: 520, 521]

### Verifying Kubernetes Platform Binaries
* [cite_start]**Threat**: An attacker could replace a standard binary like `kubectl` or `kubeadm` with a malicious version. [cite: 532]
* **Verification Process**:
    1.  [cite_start]Download the official binary for your platform. [cite: 541]
    2.  [cite_start]Download the corresponding SHA256 checksum file (`.sha256`). [cite: 541]
    3.  [cite_start]Use an OS-specific command (`sha256sum --check` on Linux, `shasum -a 256 --check` on macOS) to verify that the binary's hash matches the official hash. [cite: 546] [cite_start]A mismatch indicates the file may have been tampered with. [cite: 538]

---

## Chapter 3: Cluster Hardening

This chapter focuses on securing an already running cluster by restricting access, managing permissions, and keeping it up to date.

### Interacting with the Kubernetes API
* [cite_start]**API Server as Gateway**: The API server is the central entry point for all cluster operations. [cite: 603]
* [cite_start]**Request Processing Stages**: Every API request goes through four stages[cite: 608]:
    1.  [cite_start]**Authentication**: Verifies the identity of the user or service account (via client certs, bearer tokens, etc.). [cite: 611]
    2.  [cite_start]**Authorization**: Checks if the authenticated identity has permission to perform the requested action (e.g., using RBAC). [cite: 614]
    3.  [cite_start]**Admission Control**: Intercepts requests to validate or mutate them before they are persisted. [cite: 617]
    4.  [cite_start]**Validation**: Ensures the resulting object is valid. [cite: 620]
* **Anonymous Access**: By default, anonymous requests are enabled but mapped to the `system:anonymous` user, which has no permissions. [cite_start]This should be disabled in production. [cite: 642]

### Restricting User Permissions with RBAC
* [cite_start]**Least Privilege**: Do not share the default `kubernetes-admin` user credentials. [cite: 667] [cite_start]Create dedicated users with the minimum permissions required for their role. [cite: 670]
* **Creating a New User**:
    1.  [cite_start]Use `openssl` to create a private key and a Certificate Signing Request (CSR) for the new user, specifying their username in the Common Name (CN) and groups in the Organization (O). [cite: 677, 678]
    2.  [cite_start]Create a Kubernetes `CertificateSigningRequest` object from the CSR file. [cite: 688]
    3.  [cite_start]An administrator must approve the CSR: `kubectl certificate approve <csr-name>`. [cite: 697]
    4.  [cite_start]Extract the signed certificate from the CSR object. [cite: 698]
    5.  [cite_start]Define permissions using a `Role` (namespace-scoped) or `ClusterRole` (cluster-scoped). [cite: 702]
    6.  [cite_start]Bind the user to the role using a `RoleBinding` or `ClusterRoleBinding`. [cite: 703]
    7.  [cite_start]Add the new user's credentials and a new context to the `kubeconfig` file. [cite: 704, 705]

### Minimizing Permissions for Service Accounts
* [cite_start]**Purpose**: Service accounts provide an identity for processes running inside pods that need to interact with the API server. [cite: 717]
* **Security Risk**: A compromised pod can leverage the permissions of its service account. [cite_start]By default, service accounts have a token automatically mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`. [cite: 719, 729]
* **Best Practices**:
    * [cite_start]**Disable Automounting**: If a pod doesn't need API access, disable token mounting by setting `automountServiceAccountToken: false` in either the `ServiceAccount` definition or the `Pod` spec. [cite: 759, 761]
    * **Scoped Permissions**: Create dedicated service accounts for applications and grant them minimal permissions using a `RoleBinding`. [cite_start]Avoid using the `default` service account. [cite: 721]
    * [cite_start]**Manual Token Generation**: For external tools that need to authenticate as a service account, generate a time-bound token manually: `kubectl create token <sa-name> --duration <time>`. [cite: 768, 774]

### Updating Kubernetes Frequently
* **Importance**: New Kubernetes releases include patches for security vulnerabilities (CVEs). [cite_start]Running an outdated version leaves the cluster exposed to known exploits. [cite: 782, 784]
* [cite_start]**Release Cadence**: A new minor version is released approximately every three months, with patch support for the three most recent minor versions. [cite: 795]
* **Upgrade Process**: Upgrades should be done incrementally (e.g., 1.25 to 1.26, not 1.25 to 1.27). [cite_start]The general process (a CKA topic) involves[cite: 800, 803]:
    1.  Upgrading `kubeadm` on the control plane node.
    2.  Running `kubeadm upgrade apply <version>`.
    3.  Draining the node, upgrading the `kubelet` and `kubectl` packages, and restarting the kubelet service.
    4.  Uncordoning the node.
    5.  Repeating the drain and package upgrade process on each worker node.

---

## Chapter 4: System Hardening

This chapter covers securing the host operating system that Kubernetes nodes run on, which is a critical layer of defense.

### Minimizing the Host OS Footprint
* [cite_start]**Goal**: Reduce the attack surface by removing anything that is not strictly necessary for running Kubernetes. [cite: 860, 861]
* **Actions**:
    * [cite_start]**Disable Services**: Identify unnecessary background services using `systemctl` and disable them (`systemctl stop <service>`, `systemctl disable <service>`). [cite: 868, 873]
    * [cite_start]**Remove Packages**: Uninstall unneeded software packages using the system's package manager (e.g., `apt purge --auto-remove <package>`). [cite: 878]

### Minimizing IAM Roles (Linux User Management)
* [cite_start]**Goal**: Apply the principle of least privilege to users and processes on the host machine. [cite: 899]
* **Core Concepts**:
    * **User Management**: Use `adduser` to create users and `userdel` to remove them. [cite_start]The `/etc/passwd` file lists all system users. [cite: 904, 912, 924]
    * **Group Management**: Use `groupadd` and `groupdel` to manage groups. Assign users to groups with `usermod`. [cite_start]Groups are listed in `/etc/group`. [cite: 928, 931, 934]
    * [cite_start]**File Permissions & Ownership**: Use `chown` to change file owners/groups and `chmod` to change read (`r`), write (`w`), and execute (`x`) permissions for the owner, group, and others. [cite: 953, 958]

### Minimizing External Access to the Network
* [cite_start]**Identify Open Ports**: Use tools like `ss -ltpn` to find which processes are listening on which network ports. [cite: 966]
* [cite_start]**Close Unnecessary Ports**: If a port is open for a non-essential service, stop and remove the service. [cite: 962]
* [cite_start]**Use a Firewall**: Configure a host-level firewall like **UFW** (Uncomplicated Firewall) on Linux. [cite: 975]
    * [cite_start]The best practice is to deny all incoming and outgoing traffic by default, then explicitly allow traffic on required ports (e.g., SSH, Kubernetes component ports). [cite: 977, 978]

### Using Kernel Hardening Tools
These tools restrict the actions that processes (including those in containers) can perform by intercepting calls to the Linux kernel.

* **AppArmor**:
    * [cite_start]**Purpose**: A Mandatory Access Control (MAC) system that confines programs to a limited set of resources. [cite: 987]
    * **Profiles**: Rules are defined in profiles located in `/etc/apparmor.d/`. [cite_start]A profile can be in `enforce` mode (blocks violations) or `complain` mode (logs violations). [cite: 994, 1003]
    * **Integration with Kubernetes**:
        1.  [cite_start]Create and load an AppArmor profile on the worker node using `apparmor_parser`. [cite: 1014]
        2.  [cite_start]Apply the profile to a container by adding an annotation to the pod: `container.apparmor.security.beta.kubernetes.io/<container-name>: localhost/<profile-name>`. [cite: 1027]

* **seccomp (Secure Computing Mode)**:
    * [cite_start]**Purpose**: A Linux kernel feature that filters the system calls (syscalls) a process is allowed to make. [cite: 1039]
    * [cite_start]**Profiles**: A JSON file that defines a default action (`SCMP_ACT_ALLOW`, `SCMP_ACT_LOG`, `SCMP_ACT_ERRNO`) and a list of specific rules for certain syscalls. [cite: 1040, 1058] [cite_start]Profiles should be placed on nodes in `/var/lib/kubelet/seccomp/`. [cite: 1055]
    * **Integration with Kubernetes**:
        1.  Apply a seccomp profile via the `securityContext.seccompProfile` field in a Pod or container spec.
        2.  [cite_start]To use the container runtime's default profile (recommended), set `type: RuntimeDefault`. [cite: 1046]
        3.  [cite_start]To use a custom profile, set `type: Localhost` and provide the path to the profile file in `localhostProfile`. [cite: 1066]

---

## Chapter 5: Minimizing Microservice Vulnerabilities

This chapter shifts the focus to securing the workloads themselves, using both built-in Kubernetes features and external tools.

### Setting Appropriate OS-Level Security Domains

* [cite_start]**Security Contexts**: A set of fields in the Pod and container spec that define privilege and access control settings. [cite: 1137]
    * [cite_start]`runAsNonRoot: true`: Prevents a container from starting if the image would run as the root user. [cite: 1146]
    * [cite_start]`runAsUser` / `runAsGroup`: Specifies the UID/GID to run the container process. [cite: 1160]
    * [cite_start]`privileged: false` (Default): Privileged containers should be avoided as they have nearly full access to the host. [cite: 1168]
    * [cite_start]`allowPrivilegeEscalation: false`: Prevents a process from gaining more privileges than its parent. [cite: 1186]

* [cite_start]**Pod Security Admission (PSA)**: A built-in admission controller that replaced the deprecated Pod Security Policies (PSP). [cite: 1197]
    * [cite_start]**Mechanism**: Enforces Pod Security Standards (PSS) at the namespace level via labels. [cite: 1203]
    * **Levels**:
        * `privileged`: Unrestricted.
        * `baseline`: Minimally restrictive, prevents known privilege escalations.
        * [cite_start]`restricted`: Heavily restricted, follows current pod hardening best practices. [cite: 1214, 1215]
    * **Modes**:
        * `enforce`: Violations will cause the pod to be rejected.
        * `audit`: Violations are allowed but added to the audit log.
        * [cite_start]`warn`: Violations are allowed, and a warning is returned to the user. [cite: 1211-1213]
    * **Example Label**: `pod-security.kubernetes.io/enforce: restricted`

* **Open Policy Agent (OPA) and Gatekeeper**:
    * **Purpose**: Gatekeeper is a validating admission webhook for Kubernetes that uses the OPA policy engine to enforce custom policies written in the **Rego** language. [cite_start]It is far more flexible than PSA. [cite: 1240, 1241]
    * **Components**:
        1.  [cite_start]**ConstraintTemplate**: Defines the policy logic in Rego and the schema for the parameters the policy accepts. [cite: 1255]
        2.  [cite_start]**Constraint**: An instance of a `ConstraintTemplate`, which specifies which resources the policy applies to and the specific parameters to use. [cite: 1264]

### Managing Secrets and etcd Encryption
* **Problem**: Kubernetes `Secrets` are stored in etcd only base64 encoded, which is not true encryption. [cite_start]An attacker with access to the etcd backup or host could read them. [cite: 1290, 1293]
* [cite_start]**Solution**: Enable Encryption at Rest for etcd. [cite: 1296]
* **Process**:
    1.  Create an `EncryptionConfiguration` YAML file. [cite_start]This file specifies one or more providers (e.g., `aescbc`) and a secret key. [cite: 1323]
    2.  Modify the `kube-apiserver` static pod manifest to add the `--encryption-provider-config` flag, pointing it to the configuration file.
    3.  [cite_start]Mount the configuration file into the `kube-apiserver` pod as a volume. [cite: 1326]
    4.  [cite_start]After the API server restarts, force all existing `Secret` objects to be rewritten and encrypted: `kubectl get secrets --all-namespaces -o json | kubectl replace -f -`. [cite: 1329, 1330]

### Using Container Runtime Sandboxes
* **Purpose**: To provide a stronger layer of isolation than standard container runtimes, creating a separate kernel for the container. [cite_start]This is useful for running untrusted code or in multi-tenant environments. [cite: 1346, 1349, 1350]
* **Implementations**:
    * [cite_start]**gVisor**: Implements an application kernel in user space. [cite: 1360]
    * [cite_start]**Kata Containers**: Runs containers inside a lightweight virtual machine. [cite: 1359]
* **Integration with Kubernetes**:
    1.  [cite_start]The sandbox runtime (e.g., `runsc` for gVisor) must be installed on the worker nodes. [cite: 1366, 1374]
    2.  [cite_start]A `RuntimeClass` object must be created in Kubernetes, which maps a name to the sandbox handler. [cite: 1381]
    3.  [cite_start]A Pod can then request to be run in the sandbox by specifying the `runtimeClassName` field in its spec. [cite: 1384]

### Pod-to-Pod Encryption with mTLS
* [cite_start]**Problem**: By default, traffic between pods is unencrypted, making it vulnerable to man-in-the-middle attacks. [cite: 1392, 1402]
* **mTLS (Mutual TLS)**: An extension of TLS where both the client and the server authenticate each other's identity using certificates. [cite_start]This provides both encryption and strong identity verification. [cite: 1397]
* **Implementation in Kubernetes**: Manually managing certificates for every pod is not feasible. This is typically implemented using:
    * [cite_start]**Service Mesh**: Tools like **Linkerd** or **Istio** can automatically inject sidecar proxies that handle mTLS for all pod traffic. [cite: 1413, 1414]
    * [cite_start]**CNI Plugins**: Some CNI plugins like **Calico** and **Cilium** offer transparent encryption using technologies like **WireGuard** or IPsec. [cite: 1416]

---

## Chapter 6: Supply Chain Security

This chapter covers securing the entire lifecycle of a container image, from creation to deployment.

### Minimizing the Base Image Footprint
* [cite_start]**Goal**: To reduce the image size and attack surface by including only what is absolutely necessary. [cite: 1496]
* **Techniques**:
    1.  [cite_start]**Pick a Small Base Image**: Start with a minimal base image like `alpine` or, for even better security and smaller size, a `distroless` image which contains no shell or package manager. [cite: 1502, 1506]
    2.  **Use Multi-Stage Builds**: Use a `Dockerfile` with multiple `FROM` instructions. One stage (the "builder") has all the build tools (e.g., JDK, Go compiler) to compile the application. [cite_start]A final, clean stage then copies *only* the compiled artifact from the builder, resulting in a lean production image. [cite: 1516]
    3.  [cite_start]**Reduce Layers**: Combine multiple `RUN` commands into a single layer using `&&` to reduce image size and build time. [cite: 1556]
* [cite_start]**Tools**: `DockerSlim` and `Dive` can help analyze and shrink container images. [cite: 1562, 1564]

### Securing the Supply Chain
* **Signing Container Images**:
    * [cite_start]**Threat**: An attacker could modify an image in a registry after it's been pushed. [cite: 1580]
    * [cite_start]**Solution**: Use an image digest (a SHA256 hash of the image content) instead of a mutable tag (like `:latest`). [cite: 1575]
    * **Implementation**: When defining a container in a Pod manifest, specify the image as `<image-name>@sha256:<hash>`. [cite_start]The `kubelet` will verify this hash when pulling the image, failing if the content does not match. [cite: 1584, 1585]

* **Using Trusted Image Registries**:
    * [cite_start]**Threat**: Public registries like Docker Hub can host malicious or unvetted images. [cite: 1604]
    * [cite_start]**Solution**: Only allow images to be pulled from a list of trusted, whitelisted registries (ideally a private, company-controlled registry like JFrog Artifactory). [cite: 1609, 1613]
    * **Enforcement**: Use an admission controller to enforce this policy.
        * [cite_start]**OPA Gatekeeper**: Create a `ConstraintTemplate` and `Constraint` to ensure all `pod.spec.containers.image` fields start with an approved registry prefix (e.g., `gcr.io/`). [cite: 1615]
        * **ImagePolicyWebhook**: A built-in admission controller that calls an external webhook to validate the image. [cite_start]This requires enabling the plugin on the API server and providing a configuration that points to your backend validation service. [cite: 1638, 1647]

### Static Analysis of Workload
* [cite_start]**Purpose**: To automatically scan configuration files for security misconfigurations and violations of best practices before they are deployed. [cite: 1689]
* **Tools**:
    * [cite_start]**`hadolint`**: A linter for `Dockerfile`s that checks for common mistakes and best practice violations. [cite: 1696]
    * [cite_start]**`Kubesec`**: A tool that scans Kubernetes resource manifests (YAML files) and provides a risk score and remediation advice. [cite: 1710]

### Scanning Images for Known Vulnerabilities
* [cite_start]**Purpose**: To identify and report known vulnerabilities (CVEs) present in the OS packages and application dependencies within a container image. [cite: 1730]
* **Tool: `Trivy`**:
    * [cite_start]An open-source scanner explicitly mentioned in the CKS curriculum. [cite: 1732]
    * [cite_start]**Usage**: It can be run from the command line: `trivy image <image-name>:<tag>`. [cite: 1738]
    * [cite_start]**Output**: It produces a report listing the vulnerable library, the CVE identifier, the severity (e.g., `CRITICAL`, `HIGH`), the installed version, and the version that contains a fix. [cite: 1740] [cite_start]High and critical vulnerabilities should be addressed immediately. [cite: 1741]

---

## Chapter 7: Monitoring, Logging, and Runtime Security

This final chapter addresses the detection of and response to security events in a running cluster.

### Performing Behavior Analytics with Falco
* [cite_start]**Purpose**: **Falco** is a runtime security tool that detects anomalous activity by tapping into Linux system calls and Kubernetes audit events. [cite: 1833]
* **Architecture**: Falco uses a set of rules to monitor events. [cite_start]When a rule's condition is met, an alert is triggered and sent to a configured output (e.g., standard output, a file, a webhook). [cite: 1837, 1838]
* **Configuration**:
    * [cite_start]Falco's main configuration is in `/etc/falco/falco.yaml`. [cite: 1862]
    * [cite_start]Default rules are in `/etc/falco/falco_rules.yaml`. [cite: 1866]
    * **Customization**: To override a default rule or add a new one, add it to `/etc/falco/falco_rules.local.yaml`. [cite_start]This is the recommended practice. [cite: 1869, 1922]
* **Rule Components**:
    * [cite_start]`rule`: The core element, defining a `condition`, an `output` message, and a `priority`. [cite: 1892]
    * [cite_start]`macro`: A reusable condition snippet. [cite: 1896]
    * [cite_start]`list`: A named list of items that can be used in macros or rules. [cite: 1904]
* **Usage**: After modifying rules, restart the Falco service (`systemctl restart falco`). [cite_start]Monitor alerts using `journalctl -fu falco` or by checking the configured output file. [cite: 1875, 1883]

### Ensuring Container Immutability
* **Concept**: An immutable container is one whose running state cannot be changed after it is created. If an update is needed, a new container is deployed to replace the old one. [cite_start]This prevents attackers from installing malicious software or altering configuration on a live container. [cite: 1815, 1936]
* **Techniques**:
    1.  [cite_start]**Use Distroless Images**: These images lack shells and package managers, making it very difficult for an attacker to interact with or modify the container filesystem. [cite: 1948, 1949]
    2.  [cite_start]**Externalize Configuration**: Use `ConfigMap`s and `Secret`s to inject configuration at runtime, rather than building it into the image or modifying files manually. [cite: 1954]
    3.  **Read-Only Root Filesystem**: Set `securityContext.readOnlyRootFilesystem: true` in the container spec. [cite_start]If the application needs to write to specific directories (e.g., for logs or temporary files), mount `emptyDir` volumes at those paths to provide writable scratch space. [cite: 1965, 1968]

### Using Audit Logs to Monitor Access
* **Purpose**: Kubernetes audit logs provide a chronological, security-relevant record of all requests made to the API server. [cite_start]This is essential for detecting intrusions, troubleshooting, and compliance. [cite: 1974, 1975]
* **Configuration**: Audit logging is configured via flags on the `kube-apiserver`.
* **Core Components**:
    1.  **Audit Policy**: A YAML file that specifies a set of `rules` defining *what* to log. Each rule specifies an **audit level**:
        * `None`: Don't log.
        * `Metadata`: Log request metadata only (user, timestamp, resource, verb).
        * `Request`: Log metadata and request body.
        * [cite_start]`RequestResponse`: Log metadata, request body, and response body. [cite: 1999-2001]
    2.  **Audit Backend**: Specifies *where* to send the audit events.
        * **Log Backend**: Writes events to a file on the control plane node's filesystem.
        * [cite_start]**Webhook Backend**: Sends events to an external HTTP(S) endpoint. [cite: 1989-1991]
* **Setup (Log Backend)**:
    1.  [cite_start]Create the audit policy YAML file. [cite: 1996]
    2.  Modify the `kube-apiserver` static pod manifest to add flags:
        * `--audit-policy-file=<path/to/policy.yaml>`
        * `--audit-log-path=<path/to/logfile>`
        * [cite_start]Flags for log rotation like `--audit-log-maxage` are also available. [cite: 2012, 2013, 2022]
    3.  [cite_start]Mount the policy file and the log directory as volumes into the `kube-apiserver` pod. [cite: 2014, 2015]
    4.  [cite_start]After the API server restarts, events will be written to the log file in JSON format. [cite: 1984]
