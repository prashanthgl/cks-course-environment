# CCA Exam — CLI Command Reference
> Cilium Certified Associate | Complete Command Guide
> Covers: `cilium`, `cilium-dbg`, `hubble`, `bpftool`, `tc`, `kubectl exec` patterns

---

## Table of Contents
1. [The Two-Level Model (Critical Mental Model)](#1-the-two-level-model)
2. [cilium — Status & Config](#2-cilium--status--config)
3. [cilium — Identity & Service](#3-cilium--identity--service)
4. [cilium — Endpoint](#4-cilium--endpoint)
5. [cilium bpf — Policy](#5-cilium-bpf--policy)
6. [cilium bpf — ipcache](#6-cilium-bpf--ipcache)
7. [cilium bpf — Load Balancer](#7-cilium-bpf--load-balancer)
8. [cilium bpf — Connection Tracking](#8-cilium-bpf--connection-tracking)
9. [cilium bpf — NAT & Tunnel](#9-cilium-bpf--nat--tunnel)
10. [cilium bpf — Egress & Bandwidth](#10-cilium-bpf--egress--bandwidth)
11. [cilium monitor](#11-cilium-monitor)
12. [hubble observe](#12-hubble-observe)
13. [bpftool](#13-bpftool)
14. [tc (traffic control)](#14-tc-traffic-control)
15. [kubectl exec Patterns](#15-kubectl-exec-patterns)
16. [cilium-dbg — Core Debug](#16-cilium-dbg--core-debug)
17. [cilium-dbg — Endpoint & Policy](#17-cilium-dbg--endpoint--policy)
18. [cilium-dbg — BPF Maps](#18-cilium-dbg--bpf-maps)
19. [cilium-dbg — StateDB](#19-cilium-dbg--statedb)
20. [cilium-dbg — Metrics](#20-cilium-dbg--metrics)
21. [cilium-dbg — Misc](#21-cilium-dbg--misc)
22. [cilium vs cilium-dbg — Version Matrix](#22-cilium-vs-cilium-dbg--version-matrix)
23. [Exam Traps & Confusers](#23-exam-traps--confusers)
24. [Drop Reason Codes](#24-drop-reason-codes)
25. [Reserved Identity Numbers](#25-reserved-identity-numbers)
26. [Practical Debug Workflows](#26-practical-debug-workflows)

---

## 1. The Two-Level Model

Every resource in Cilium has a **userspace view** and a **kernel/BPF view**. Discrepancies between these levels are the basis of many exam scenario questions.

| Userspace View | Kernel/BPF View | What discrepancy means |
|---|---|---|
| `cilium service list` | `cilium bpf lb list` | Stale BPF entry after service deletion |
| `cilium endpoint policy get <id>` | `cilium bpf policy get <id>` | Map regeneration hasn't completed yet |
| `cilium map list` | `bpftool map list` | Cilium vs raw kernel perspective |
| `cilium identity list` | `cilium bpf ipcache list` | Identity known but not yet propagated to datapath |

**Rule:** When troubleshooting, always check the BPF map to confirm what the kernel is actually enforcing.

---

## 2. cilium — Status & Config

> Run from your shell (standalone CLI) or inside the agent pod.

```bash
# Overall cluster health — agent, controllers, kvstore, Hubble, proxy
cilium status

# Full component breakdown — encryption, CNI chaining, kube-proxy replacement
cilium status --verbose

# Machine-readable — pipe to jq
cilium status --output json

# Dump all agent config as key=value pairs
# Verify: tunnel-mode, enable-ipv6, enable-hubble, kube-proxy-replacement
cilium config --all

# Get a single config key value
cilium config enable-ipv6

# Full diagnostic state dump — all endpoints, maps, controllers, log tail
cilium debuginfo

# Deploy test pods and run end-to-end connectivity validation
cilium connectivity test

# Standalone CLI — install Cilium into cluster (wraps Helm)
cilium install --version 1.15.0

# Standalone CLI — enable Hubble (deploys hubble-relay, updates agent config)
cilium hubble enable

# Standalone CLI — port-forward Hubble Relay automatically
cilium hubble port-forward
```

---

## 3. cilium — Identity & Service

```bash
# List all security identities — numeric ID, labels, namespace
# Reserved: world=2, host=1, unmanaged=3, health=4, init=5, remote-node=6
cilium identity list

# Fetch details for a specific identity by numeric ID
# Use when cilium monitor shows a drop for an unknown identity number
cilium identity get 12345

# All K8s services → Cilium eBPF LB table
# Shows frontend VIP and backend list for ClusterIP, NodePort, LoadBalancer
cilium service list

# Details for a specific service by its Cilium internal service ID
cilium service get 3

# List all eBPF maps by name, type, key/value size, entry count
cilium map list

# Dump contents of a named eBPF map (decoded output)
cilium map get cilium_ipcache
```

---

## 4. cilium — Endpoint

```bash
# All local pod endpoints: ID, pod name, IP, labels, identity, policy state
# Most critical command for endpoint debugging
cilium endpoint list

# Full JSON — pipe to jq to filter by policy enforcement state
cilium endpoint list --output json | \
  jq '.[] | select(.status.policy."ingress-policy-enabled" == true) | .id'

# Full detail for endpoint by ID
# Labels, identity, policy enforcement state, controllers, BPF map health, log tail
cilium endpoint get 1847

# Look up endpoint by label selector instead of numeric ID
cilium endpoint get -l k8s:app=frontend

# Per-endpoint config — shows PolicyEnforcement mode (default/always/never)
cilium endpoint config 1847

# Override PolicyEnforcement for a single endpoint (debug only)
cilium endpoint config 1847 PolicyEnforcement=always

# State machine event log — regeneration events, policy recalculation, errors
cilium endpoint log 1847

# BPF map sync status, proxy health, controller failures for one endpoint
cilium endpoint health 1847

# High-level resolved policy for endpoint 1847
# Shows per-identity, per-port allow/deny rules (human readable, with rule source)
# NOTE: Different from 'cilium bpf policy get' — see section 5
cilium endpoint policy get 1847

# Cluster-wide policy repository — all imported CNP and CCNP rules combined
cilium policy get

# Pretty-print full policy repository
cilium policy get --output json | jq .

# Simulate a policy decision — returns ALLOW or DENY with the matching rule
# Does NOT send actual traffic — reads the policy engine in-memory
cilium policy trace \
  --src-k8s-pod default/frontend-7d4b9c \
  --dst-k8s-pod default/backend-5f9c2b \
  --dport 8080/TCP

# Trace using numeric identity and endpoint ID (use for cross-node or remote pods)
cilium policy trace \
  --src-identity 12345 \
  --dst-endpoint 1847 \
  --dport 443/TCP

# Verbose trace — shows selector evaluation step by step
cilium policy trace \
  --src-k8s-pod default/frontend-7d4b9c \
  --dst-k8s-pod default/backend-5f9c2b \
  --dport 8080/TCP -v
```

---

## 5. cilium bpf — Policy

```bash
# Raw eBPF policy map for endpoint 1847
# Each row: (identity, port, proto) → allow/deny
# THIS is what the kernel is actually enforcing — ground truth
cilium bpf policy get 1847

# Include wildcard/catch-all entries (matching any identity or any port)
cilium bpf policy get 1847 --all
```

**Key distinction:**
- `cilium endpoint policy get 1847` → high-level resolved rules (human readable, shows rule source YAML)
- `cilium bpf policy get 1847` → raw eBPF map entries (kernel reality, numeric identities and ports)

If these disagree, the map hasn't been regenerated yet — check `cilium endpoint log 1847` for regeneration errors.

---

## 6. cilium bpf — ipcache

```bash
# List the IP→identity mapping table used by the datapath
# Every pod IP, node IP, and CIDR block maps to a numeric security identity
# If an IP is missing here, the datapath treats it as "world" (identity 2)
cilium bpf ipcache list

# Look up a specific IP in the ipcache
# Returns the identity associated with that IP
cilium bpf ipcache get 10.0.1.42
```

**Why it matters for cross-node policy:** If a remote pod's IP is not in the ipcache, policy cannot match it by label — it will be treated as `world`. Always check this when cross-node policy drops occur.

---

## 7. cilium bpf — Load Balancer

```bash
# All LB frontend→backend mappings from eBPF maps
# (cilium_lb4_services + cilium_lb4_backends)
# Compare with 'cilium service list' — both should match
cilium bpf lb list

# Show only backend entries (pod IPs and their states)
# Use to verify a terminated pod is no longer in the backend set
cilium bpf lb list --backend

# Show only service frontend entries (VIPs and NodePort mappings)
cilium bpf lb list --service
```

**Exam scenario:** "Service deleted but traffic still routes" → `cilium bpf lb list` will show the stale BPF entry even though `cilium service list` shows it as gone.

---

## 8. cilium bpf — Connection Tracking

```bash
# Dump global CT table — all active flows
# Shows src/dst IP:port, proto, direction, state (SYN_SENT/ESTABLISHED/TIME_WAIT), expiry
cilium bpf ct list global

# CT entries local to endpoint 1847 only (faster for single-pod debug)
cilium bpf ct list 1847

# Filter for a specific IP
cilium bpf ct list global | grep 10.0.1.42

# Clear all CT state — WARNING: drops all established connections
# Use after policy changes when connections are stuck in old state
cilium bpf ct flush global
```

---

## 9. cilium bpf — NAT & Tunnel

```bash
# NAT/SNAT table — active masquerade mappings
# Shows original src → translated src for NodePort, LoadBalancer, and egress traffic
cilium bpf nat list global

# VXLAN/Geneve tunnel endpoint table
# Maps each remote node's pod CIDR to the node's IP
# Only populated in tunnel mode (not native routing mode)
cilium bpf tunnel list

# Clear tunnel map — forces re-learning of all remote node routes
# Use if a node was replaced with a different IP
cilium bpf tunnel flush
```

---

## 10. cilium bpf — Egress & Bandwidth

```bash
# Egress Gateway policy entries — which source CIDRs use which egress node/IP
# Only relevant when CiliumEgressGatewayPolicy CRDs are deployed
cilium bpf egress list

# Per-endpoint bandwidth limits (BBR / EDT rate limiting)
# Populated when pods have bandwidth annotations
cilium bpf bandwidth list
```

---

## 11. cilium monitor

> **Scope: node-local only.** For cluster-wide flows, use `hubble observe`.
> Run INSIDE the cilium-agent pod: `kubectl exec -n kube-system ds/cilium -- cilium monitor`
> On Cilium ≥1.13, this command moved to `cilium-dbg monitor`.

```bash
# Stream all datapath events (noisy — always add filters)
cilium monitor

# Verbose — full packet decode (Ethernet, IP, TCP headers)
cilium monitor -v

# Very verbose — hex dump of packet payload
cilium monitor -vv

# ── Filter by event type ──────────────────────────────────────

# ONLY dropped packets — drop reason + identity/endpoint involved
# Primary filter for policy debugging
cilium monitor --type drop

# Both ALLOW and DENY policy decisions
# More complete than --type drop — verify allows are happening
cilium monitor --type policy-verdict

# L7 proxy events — method, URL, status code
# Only visible when an L7 policy is in effect and proxy is engaged
cilium monitor --type l7

# Packet tracing events — where a packet entered/exited the BPF datapath
cilium monitor --type trace

# Agent-level events — policy changes, endpoint creation/deletion, identity allocation
cilium monitor --type agent

# ── Filter by endpoint ────────────────────────────────────────

# Events where endpoint 1847 is source OR destination
# NOTE: uses endpoint ID (number), NOT pod name
cilium monitor --related-to 1847

# Events where endpoint 1847 is the originating source only
cilium monitor --from-source 1847

# ── Combined filters (most useful) ───────────────────────────

# Drops involving endpoint 1847 — standard go-to for "why can't this pod reach X"
cilium monitor --type drop --related-to 1847

# With verbose decode — see drop reason and rejecting identity
cilium monitor --type drop -v --related-to 1847

# Policy verdicts for endpoint 1847 with packet decode
cilium monitor --type policy-verdict --related-to 1847 -v
```

**Get endpoint ID first:**
```bash
cilium endpoint list | grep <pod-name>
```

---

## 12. hubble observe

> **Scope: cluster-wide** via Hubble Relay (all nodes).
> `cilium monitor` is node-local; `hubble observe` is cluster-wide.
> Requires Hubble to be enabled (`cilium hubble enable`).

```bash
# Check Hubble connectivity — relay reachable, nodes connected, flow buffer size
hubble status

# Show recent buffered flows from all nodes
hubble observe

# Live stream — equivalent to tail -f for network traffic
hubble observe --follow

# Last N flows from the ring buffer
hubble observe --last 100

# ── Filter by verdict ─────────────────────────────────────────
# DROPPED = policy denied
# FORWARDED = allowed
# AUDIT = matched audit-mode rule (logged, not dropped)
# ERROR = infrastructure error (not a policy decision)

# Primary debugging command for policy issues — cluster-wide
hubble observe --verdict DROPPED

# Verify a policy fix allowed the right traffic through
hubble observe --verdict FORWARDED

# Flows matching an audit-mode policy rule
hubble observe --verdict AUDIT

# Infrastructure errors (proxy error, CT table issues)
hubble observe --verdict ERROR

# ── Filter by pod / namespace / label ─────────────────────────

# Flows from a specific pod (format: namespace/pod-name)
hubble observe --from-pod default/frontend-7d4b9c

# Flows to a specific pod
hubble observe --to-pod default/backend-5f9c2b

# Both directions for a specific pod pair
hubble observe \
  --from-pod default/frontend-7d4b9c \
  --to-pod default/backend-5f9c2b

# All flows in a namespace (source OR destination)
hubble observe --namespace production

# Directional namespace filter (FROM only)
hubble observe --from-namespace staging

# Directional namespace filter (TO only)
hubble observe --to-namespace production

# Cross-namespace flows
hubble observe --from-namespace staging --to-namespace production

# Flows where source OR destination pod has this label (bidirectional)
hubble observe --label app=frontend

# Directional label filters (more precise)
hubble observe --from-label app=frontend --to-label app=backend

# ── Filter by protocol / port ─────────────────────────────────

# Protocol filter — also accepts: UDP, ICMP, HTTP, Kafka, DNS, gRPC
hubble observe --protocol TCP

# Port filter (source or destination)
hubble observe --port 8080

# Destination port filter
hubble observe --to-port 443

# Flow type filter — drop, trace, l7, agent, policy-verdict, capture
# NOTE: --type and --verdict are NOT identical — see exam traps
hubble observe --type drop

# L7 HTTP filters (only visible for proxied traffic)
hubble observe --http-status 403
hubble observe --http-method POST
hubble observe --http-path /api/v1

# ── Output format & time ──────────────────────────────────────

# JSON output — one JSON object per flow
hubble observe --verdict DROPPED -o json

# Extract specific fields with jq
hubble observe --verdict DROPPED -o json | \
  jq '{reason:.drop_reason_desc, src:.source.pod_name, dst:.destination.pod_name, port:.destination_port}'

# Flows from the last 5 minutes (also: 30s, 1h, RFC3339 timestamp)
hubble observe --since 5m

# Flows up to a specific timestamp
hubble observe --until 2024-03-15T10:00:00

# Flows from a specific node only
hubble observe --node-name worker-1

# ── Exam-level combo ──────────────────────────────────────────

# Live drops between frontend and backend with structured output
hubble observe \
  --follow \
  --verdict DROPPED \
  --from-label app=frontend \
  --to-label app=backend \
  -o json | \
  jq '{reason:.drop_reason_desc, src:.source.pod_name, dst:.destination.pod_name, port:.destination_port}'
```

---

## 13. bpftool

> Operates at the raw kernel level. Run on the node or inside the cilium-agent pod (has hostPID + privileged).
> `cilium bpf` commands are higher-level wrappers that decode Cilium's schema — prefer those for Cilium debugging. Use `bpftool` to confirm at the kernel level.

```bash
# List all eBPF programs in the kernel
# Shows: prog ID, type, name, tag (hash), loaded_at, jited, maps used
bpftool prog list

# Filter to only XDP programs
bpftool prog list --json | jq '.[] | select(.type == "xdp") | {id:.id, name:.name}'

# Details for a specific program by ID
bpftool prog show id 42

# Disassemble eBPF bytecode (BPF instruction set, pre-JIT)
bpftool prog dump xlated id 42

# Disassemble JIT-compiled native machine code
bpftool prog dump jited id 42

# List all eBPF maps in the kernel
# Shows: map ID, type (hash/array/lru_hash/percpu_array), name, key/value size, max_entries
bpftool map list

# Dump all entries from a map by ID (raw hex output)
bpftool map dump id 17

# Dump map by name (more stable across reboots than ID)
bpftool map dump name cilium_ipcache

# Look up a specific key in a map (hex representation of 10.0.1.42)
bpftool map lookup id 17 key hex 0a 00 01 2a

# Shows eBPF programs attached to network interfaces (XDP and TC)
# Tells you WHICH program is attached to eth0/lxc* and at which hook
bpftool net list

# Lists eBPF programs attached to cgroups
# Cilium uses this for socket-level LB (kube-proxy bypass)
# Shows cgroup_connect4, cgroup_sendmsg, etc.
bpftool cgroup list /sys/fs/cgroup
```

**bpftool prog list vs tc filter show:**
- `bpftool prog list` = all eBPF programs loaded in kernel (global, attached or not)
- `tc filter show dev eth0 ingress` = programs actually attached to eth0 ingress
- A program can be loaded but not attached — both commands are needed to confirm full state.

---

## 14. tc (traffic control)

> Cilium's primary datapath hook is TC ingress/egress on `lxc*` and `eth0` interfaces.

```bash
# eBPF TC classifiers on eth0 ingress
# Output includes prog ID — cross-reference with bpftool prog list
tc filter show dev eth0 ingress

# eBPF TC classifiers on eth0 egress
tc filter show dev eth0 egress

# TC classifier on pod's veth (lxcXXXXXX = node side, ingress = from pod)
# Cilium attaches the from-container program here
tc filter show dev lxc8a3f2d ingress

# Queuing discipline — must show "clsact" for TC eBPF to work
# If missing, Cilium's TC hooks are not active
tc qdisc show dev eth0

# List all veth pairs — each pod has a lxc* veth on the node side
# Use to find the interface name before running tc filter show
ip link show type veth
```

---

## 15. kubectl exec Patterns

> On exam clusters, `cilium` and `cilium-dbg` are often NOT in your PATH on the shell — run them via `kubectl exec`.

```bash
# Run cilium status inside the DaemonSet pod on current node
kubectl exec -n kube-system ds/cilium -- cilium status

# Target a specific node's agent pod by full name
kubectl get pods -n kube-system -l k8s-app=cilium -o wide
kubectl exec -n kube-system -it cilium-xxxx -- cilium endpoint list

# Stream drops from the node
kubectl exec -n kube-system ds/cilium -- cilium monitor --type drop

# Run hubble observe inside the agent pod (reads local node's ring buffer)
# Works even if Hubble Relay is NOT deployed
kubectl exec -n kube-system ds/cilium -- hubble observe --verdict DROPPED --follow

# Run hubble via Hubble Relay — gets cluster-wide flows from all nodes
kubectl exec -n kube-system deploy/hubble-relay -- hubble observe --verdict DROPPED

# bpftool from inside the agent pod (has hostPID + privileged access)
kubectl exec -n kube-system ds/cilium -- bpftool prog list

# tc commands from inside the agent pod (has NET_ADMIN + host network)
kubectl exec -n kube-system ds/cilium -- tc filter show dev eth0 ingress

# Run cilium-dbg commands
kubectl exec -n kube-system ds/cilium -- cilium-dbg endpoint list
kubectl exec -n kube-system ds/cilium -- cilium-dbg bpf policy get 1847
kubectl exec -n kube-system ds/cilium -- cilium-dbg monitor --type drop

# Port-forward Hubble Relay gRPC (then use hubble observe from local shell)
kubectl port-forward -n kube-system svc/hubble-relay 4245:80

# Port-forward Hubble UI web interface
kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# Point local hubble CLI at the forwarded relay
hubble config set server localhost:4245
```

---

## 16. cilium-dbg — Core Debug

> `cilium-dbg` lives at `/usr/bin/cilium-dbg` inside the cilium-agent container.
> Available in Cilium ≥1.13. Talks directly to the agent's Unix socket at `/var/run/cilium/cilium.sock`.
> **Must be run inside the cilium-agent pod** — not available externally.

```bash
# Check version first — determines which binary to use for each command
kubectl exec -n kube-system ds/cilium -- cilium-dbg version

# Full verbose status — more detailed than standalone cilium CLI
kubectl exec -n kube-system ds/cilium -- cilium-dbg status --verbose

# Full status of every internal controller (goroutine-level)
# Failing controller shows last error + failure count
kubectl exec -n kube-system ds/cilium -- cilium-dbg status --all-controllers

# Per-subsystem health state (agent, envoy, datapath, identity, policy)
kubectl exec -n kube-system ds/cilium -- cilium-dbg status --all-health

# Complete dump of all agent internal state — endpoints, policy, maps, goroutines
kubectl exec -n kube-system ds/cilium -- cilium-dbg debuginfo

# Capture debuginfo as JSON for offline analysis
kubectl exec -n kube-system ds/cilium -- cilium-dbg debuginfo --output json > /tmp/debug.json

# Automated troubleshooting checks (Cilium ≥1.15)
# Flags: Hubble not enabled, stale kube-proxy, IPAM exhaustion, etc.
kubectl exec -n kube-system ds/cilium -- cilium-dbg troubleshoot

# Active runtime configuration (reads from running agent, not ConfigMap)
kubectl exec -n kube-system ds/cilium -- cilium-dbg config

# Transparent encryption state — WireGuard/IPsec status, key ID, encrypted node count
kubectl exec -n kube-system ds/cilium -- cilium-dbg encrypt status

# Monitor (moved from cilium to cilium-dbg in ≥1.13)
kubectl exec -n kube-system ds/cilium -- cilium-dbg monitor --type drop
kubectl exec -n kube-system ds/cilium -- cilium-dbg monitor --type policy-verdict --related-to 1847 -v
```

---

## 17. cilium-dbg — Endpoint & Policy

```bash
# List local endpoints (more internal fields than standalone cilium CLI)
cilium-dbg endpoint list

# Full state dump for endpoint 1847
cilium-dbg endpoint get 1847

# Extract policy enforcement state from JSON
cilium-dbg endpoint get 1847 --output json | \
  jq '.[] | .status.policy'

# Confirm ingress/egress policy enforcement is actually enabled
cilium-dbg endpoint get 1847 --output json | \
  jq '.[] | {ingress:.status.policy."ingress-policy-enabled", egress:.status.policy."egress-policy-enabled"}'

# State machine event log — why is the endpoint stuck in "regenerating"?
cilium-dbg endpoint log 1847

# BPF map sync, proxy health, CT table health for one endpoint
cilium-dbg endpoint health 1847

# Full cluster policy repository (all CNP + CCNP rules as imported)
cilium-dbg policy get

# High-level resolved policy for endpoint 1847 (human readable, shows rule source)
cilium-dbg endpoint policy get 1847

# Simulate a policy decision (reads policy engine in-memory, no real traffic)
cilium-dbg policy trace \
  --src-k8s-pod default/frontend-7d4b9c \
  --dst-k8s-pod default/backend-5f9c2b \
  --dport 8080/TCP

# Verbose trace — shows selector evaluation step by step
cilium-dbg policy trace \
  --src-identity 34521 \
  --dst-endpoint 1847 \
  --dport 443/TCP -v
```

---

## 18. cilium-dbg — BPF Maps

> Functionally identical to `cilium bpf *` commands — same subcommand tree exposed through the debug binary.
> On ≥1.13, if `cilium bpf` fails, use `cilium-dbg bpf`.

```bash
# Raw eBPF policy map for endpoint 1847 — ground truth enforcement state
cilium-dbg bpf policy get 1847

# IP→identity mapping table
cilium-dbg bpf ipcache list

# LB backend map with pod health states
cilium-dbg bpf lb list --backend

# CT table filtered for a specific IP
cilium-dbg bpf ct list global | grep 10.0.1.42

# NAT/masquerade mapping table
cilium-dbg bpf nat list global

# VXLAN/Geneve tunnel endpoint table (tunnel mode only)
cilium-dbg bpf tunnel list

# List all Cilium eBPF maps with fill count
# Fill count near max_entries = map exhaustion = connections start failing
cilium-dbg map list

# Dump a map by name (decoded output — knows Cilium's schema)
cilium-dbg map get cilium_ipcache

# Live event stream from a map — insertions, deletions, updates in real time
cilium-dbg map events cilium_ipcache
```

---

## 19. cilium-dbg — StateDB

> Available in Cilium ≥1.14. StateDB is Cilium's in-memory relational database for tracking cluster objects.
> Tables: nodes, services, backends, endpoints, routes, health, devices.

```bash
# List all tables with row count and schema version
cilium-dbg statedb tables

# Dump all StateDB tables as JSON (very verbose)
cilium-dbg statedb dump

# Extract a specific service entry
cilium-dbg statedb dump | jq '.services[] | select(.Name == "my-svc")'

# List all nodes with their pod CIDR allocations
# A missing node means cross-node routing won't work for that node's pods
cilium-dbg statedb dump | jq '.nodes[] | {name:.Name, ip:.IPv4AllocCIDR}'

# Watch a table live — prints diff on every row change (Cilium ≥1.15 experimental)
cilium-dbg statedb experimental watch services
```

---

## 20. cilium-dbg — Metrics

> Cilium exports Prometheus metrics on port `9962` of each agent pod.

```bash
# List all Prometheus metrics exported by this agent
# Use to find metric names before querying Prometheus
cilium-dbg metrics list

# Find all drop-related metrics
# Key: cilium_drop_count_total (per drop reason), cilium_forward_count_total
cilium-dbg metrics list | grep drop

# Endpoint metrics
# Key: cilium_endpoint_state, cilium_endpoint_regeneration_time_stats
cilium-dbg metrics list | grep endpoint

# BPF map metrics
# Key: cilium_bpf_map_ops_total, cilium_bpf_map_pressure (0.9+ = critical)
cilium-dbg metrics list | grep map

# Direct scrape of the metrics endpoint from inside the pod
kubectl exec -n kube-system ds/cilium -- \
  curl -s localhost:9962/metrics | grep cilium_drop_count_total
```

---

## 21. cilium-dbg — Misc

```bash
# ALL identities in the CLUSTER (NOT just this node)
# In Cilium ≥1.19, this moved from "cilium identity list" which no longer exists
cilium-dbg identity list

# Details for a specific identity by numeric ID
# Shows labels and status — use when cilium monitor shows an unknown identity number
cilium-dbg identity get 12345

# Alternative: query identities via K8s API (CRD-backed identities)
# Same result as cilium-dbg identity list but via kubectl instead of agent socket
kubectl get ciliumidentity

# List all cluster nodes known to this agent
# Cross-check with kubectl get nodes to ensure no missing nodes
cilium-dbg node list

# IPs managed by this agent's IPAM — pod IPs with endpoint IDs and owners
# Spot leaked IPs (allocated but no matching endpoint)
cilium-dbg ip list

# Count IPs in use (gauge IPAM pressure)
cilium-dbg ip list --output json | jq '[.[] | select(.state == "in-use")] | length'

# List active CiliumRecorder objects (eBPF-native pcap captures)
cilium-dbg recorder list

# Details of a specific pcap recorder
cilium-dbg recorder get my-recorder

# Interactive Go REPL connected to the running agent (advanced)
cilium-dbg shell
```

---

## 22. cilium vs cilium-dbg — Version Matrix

| Command | ≤1.12 binary | ≥1.13 binary | Where to run |
|---|---|---|---|
| `status` | `cilium` | both | shell or inside pod |
| `endpoint list/get` | `cilium` | `cilium-dbg` | inside pod |
| `bpf policy get` | `cilium` | `cilium-dbg` | inside pod |
| `bpf ipcache list` | `cilium` | `cilium-dbg` | inside pod |
| `bpf lb list` | `cilium` | `cilium-dbg` | inside pod |
| `bpf ct list` | `cilium` | `cilium-dbg` | inside pod |
| `bpf nat list` | `cilium` | `cilium-dbg` | inside pod |
| `bpf tunnel list` | `cilium` | `cilium-dbg` | inside pod |
| `monitor` | `cilium` | `cilium-dbg` | inside pod |
| `policy trace` | `cilium` | `cilium-dbg` | inside pod |
| `identity list/get` | `cilium` (‼️ but not exposed in dbg) | `cilium-dbg` | inside pod |
| `debuginfo` | `cilium` | `cilium-dbg` | inside pod |
| `metrics list` | — | `cilium-dbg` | inside pod |
| `statedb` | — | `cilium-dbg` | inside pod (1.14+) |
| `troubleshoot` | — | `cilium-dbg` | inside pod (1.15+) |
| `connectivity test` | `cilium` | `cilium` (standalone) | your shell (K8s API) |
| `hubble enable` | `cilium` | `cilium` (standalone) | your shell (K8s API) |
| `install / upgrade` | `cilium` | `cilium` (standalone) | your shell (K8s API) |

**Safe strategy on the exam:** Try `cilium <cmd>` first. If you get "unknown command", retry with `cilium-dbg <cmd>`. Both binaries are in PATH inside the cilium-agent container.

---

## 23. Exam Traps & Confusers

### 0. `cilium identity` command does NOT exist in Cilium ≥1.19 (MAJOR TRAP)
```bash
# WRONG in Cilium 1.19+ — command not found
cilium identity list
cilium identity get 12345

# CORRECT in Cilium 1.19+
cilium-dbg identity list
cilium-dbg identity get 12345

# Also correct as alternative (queries K8s API, not agent socket)
kubectl get ciliumidentity
```
**What happened:** The standalone `cilium` CLI (installable separately) was always separate from the agent-side debug CLI. In 1.19+, all agent-side inspection commands (including `identity`) moved exclusively to `cilium-dbg`. The standalone CLI now focuses on cluster-level operations (install, status, hubble enable, connectivity test) that talk to the K8s API.

**On the exam:** If you try `cilium identity` and get "no such command", this is NOT a bug — **use `cilium-dbg identity` instead**. The exam explicitly tests this distinction. You might see both in different contexts or even see a question asking "which command queries all cluster identities" where the answer is `cilium-dbg identity list` (not `cilium identity list`).

### 1. `cilium endpoint list` vs `cilium-dbg identity list`
- `endpoint list` = pods on **this node only**
- `identity list` = all identities in the **cluster** (via agent socket)
- Cross-node policy debugging requires checking ipcache on **both** nodes.

### 2. `--related-to` requires endpoint ID, NOT pod name
```bash
# WRONG — silent failure, no results
cilium monitor --related-to frontend-7d4b9c

# CORRECT
cilium endpoint list | grep frontend    # get the ID first
cilium monitor --related-to 1847
```

### 3. `hubble observe --type drop` vs `--verdict DROPPED`
- `--type drop` = Hubble message type classification
- `--verdict DROPPED` = policy verdict filter
- They overlap but `--verdict DROPPED` is more precise for policy debugging. **Prefer `--verdict DROPPED` on policy questions.**

### 4. `cilium bpf policy get` vs `cilium endpoint policy get`
- `endpoint policy get 1847` = high-level resolved rules, human readable, shows YAML rule source
- `bpf policy get 1847` = raw eBPF map entries, what's **actually in the kernel**
- If these disagree: map regeneration hasn't completed yet — check `endpoint log 1847`.

### 5. `cilium service list` vs `cilium bpf lb list`
- `cilium service list` = userspace view (what Cilium thinks it programmed)
- `cilium bpf lb list` = kernel map view (what's actually being used)
- A just-deleted service may still appear in the BPF map briefly.

### 6. `cilium monitor` is node-local, `hubble observe` is cluster-wide
- For a cross-node drop (Pod A on node-1 → Pod B on node-2):
  - `cilium monitor` on node-1 = egress side
  - `cilium monitor` on node-2 = ingress side
  - `hubble observe` via Relay = both sides in one stream

### 7. `bpftool prog list` vs `tc filter show`
- `bpftool prog list` = all eBPF programs **loaded** in kernel (global)
- `tc filter show dev eth0 ingress` = programs **attached** to eth0 ingress
- A program can be loaded but not attached — check both to confirm full state.

### 8. `hubble observe --namespace` is bidirectional
```bash
# Matches flows where src OR dst is in production
hubble observe --namespace production

# Only flows FROM production
hubble observe --from-namespace production

# Only flows TO production
hubble observe --to-namespace production
```

### 9. XDP drops are invisible to Hubble
- XDP hook fires before TC — if Cilium is in XDP acceleration mode, early XDP drops (`XDP_DROP`) don't reach the perf event buffer that Hubble reads.
- If you expect drops but Hubble shows nothing, check if XDP is in use: `bpftool net list`.

### 10. `cilium policy trace` simulates, doesn't test live traffic
- Reads the in-memory policy engine
- If the endpoint is stuck in "regenerating", `policy trace` may say ALLOW while actual packets are dropped
- Always pair with `bpf policy get` to confirm the kernel map matches the simulation.

---

## 24. Drop Reason Codes

These appear in `cilium monitor --type drop -v` and `hubble observe --verdict DROPPED -o json`:

| Reason Code | Meaning | Fix |
|---|---|---|
| 133 — Policy denied | L3/L4 policy drop — no matching allow rule | Check CiliumNetworkPolicy rules for src identity + port |
| 134 — Policy denied (L7) | L7 proxy denied — HTTP path/method rejected | Check L7 policy rules (path, method, headers) |
| CT: Map insertion failed | Connection tracking table is full | Scale issue — increase CT table size |
| Stale or unroutable IP | IP not in ipcache | Pod deleted/restarted — ipcache propagation lag |
| Invalid packet | Malformed or unexpected packet format | Packet-level issue, check MTU and fragmentation |
| No tunnel/route | No route to remote pod | Check tunnel map / BGP routes (native routing mode) |

---

## 25. Reserved Identity Numbers

These appear in `cilium monitor` and `cilium bpf policy get` output:

| Identity | Label | Meaning |
|---|---|---|
| 1 | `reserved:host` | Node host network namespace |
| 2 | `reserved:world` | External (internet) traffic |
| 3 | `reserved:unmanaged` | Non-Cilium managed pods |
| 4 | `reserved:health` | Cilium health check endpoints |
| 5 | `reserved:init` | Pods during bootstrap (no labels yet) |
| 6 | `reserved:remote-node` | Traffic from other cluster nodes |
| 7 | `reserved:kube-apiserver` | Traffic from/to the API server |

---

## 26. Practical Debug Workflows

### "Pod A cannot reach Pod B on port 8080"

```bash
# Step 1: Get endpoint IDs
kubectl exec -n kube-system ds/cilium -- cilium endpoint list | grep -E "pod-a|pod-b"

# Step 2: Simulate the policy decision
kubectl exec -n kube-system ds/cilium -- cilium policy trace \
  --src-k8s-pod <ns>/pod-a \
  --dst-k8s-pod <ns>/pod-b \
  --dport 8080/TCP

# Step 3: Watch actual drops
hubble observe --follow --verdict DROPPED \
  --from-label app=pod-a --to-label app=pod-b

# Step 4: Confirm what kernel is enforcing
kubectl exec -n kube-system ds/cilium -- cilium bpf policy get <pod-b-endpoint-id>

# Step 5: Check ipcache has the correct identity for pod-a
kubectl exec -n kube-system ds/cilium -- cilium bpf ipcache get <pod-a-ip>
```

### "Service traffic not load balancing correctly"

```bash
# Step 1: Compare userspace and kernel LB views
kubectl exec -n kube-system ds/cilium -- cilium service list
kubectl exec -n kube-system ds/cilium -- cilium bpf lb list --backend

# Step 2: Check CT table for stale connections
kubectl exec -n kube-system ds/cilium -- cilium bpf ct list global | grep <service-vip>

# Step 3: Watch L4 flows to the service
hubble observe --follow --to-port 8080 --from-label app=client -o json
```

### "Cross-node policy drop — pods on different nodes"

```bash
# Step 1: On the SOURCE node — check egress policy
kubectl exec -n kube-system <source-node-agent-pod> -- cilium bpf policy get <src-endpoint-id>

# Step 2: On the DESTINATION node — check ipcache knows src pod's identity
kubectl exec -n kube-system <dst-node-agent-pod> -- cilium bpf ipcache get <src-pod-ip>

# Step 3: On the DESTINATION node — check ingress policy
kubectl exec -n kube-system <dst-node-agent-pod> -- cilium bpf policy get <dst-endpoint-id>

# Step 4: Use Hubble to see both sides in one stream (requires Hubble Relay)
hubble observe --verdict DROPPED \
  --from-label app=source-app \
  --to-label app=dest-app \
  --follow
```

### "L7 policy not working — all HTTP requests blocked"

```bash
# Step 1: Verify policy is installed in the agent
kubectl exec -n kube-system ds/cilium -- cilium policy get | grep -A 20 "my-l7-policy"

# Step 2: Trace the specific HTTP path
kubectl exec -n kube-system ds/cilium -- cilium policy trace \
  --src-k8s-pod <ns>/client \
  --dst-k8s-pod <ns>/server \
  --dport 80/TCP

# Step 3: Check for L7 proxy events
kubectl exec -n kube-system ds/cilium -- cilium monitor --type l7 --related-to <endpoint-id>

# Step 4: Check with Hubble (HTTP-specific filters)
hubble observe --follow --http-status 403 --from-label app=client
hubble observe --follow --http-path /api --verdict DROPPED
```

---

*Reference version: Cilium 1.13–1.15 | CCA Exam Prep*
