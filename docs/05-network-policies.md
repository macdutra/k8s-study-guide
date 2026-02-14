# Network Policies

Complete guide to Kubernetes NetworkPolicy for controlling pod-to-pod communication.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Basic NetworkPolicy](#basic-networkpolicy)
- [Ingress Rules](#ingress-rules)
- [Egress Rules](#egress-rules)
- [Selectors](#selectors)
- [Common Patterns](#common-patterns)
- [Hands-On Practice](#hands-on-practice)
- [Troubleshooting](#troubleshooting)
- [Exam Tips](#exam-tips)

## Overview

NetworkPolicy allows you to control traffic flow at the IP address or port level.

### Key Concepts

- **Pod Selector**: Which pods the policy applies to
- **Ingress**: Incoming traffic rules
- **Egress**: Outgoing traffic rules
- **Selectors**: podSelector, namespaceSelector, ipBlock

### Default Behavior

- **Without NetworkPolicy**: All pods can communicate with all pods
- **With NetworkPolicy**: Only explicitly allowed traffic is permitted

## Prerequisites

### ⚠️ CRITICAL: Minikube Requires Calico CNI

**The default Minikube CNI (kindnet) does NOT enforce NetworkPolicy!**

You MUST start Minikube with Calico for NetworkPolicy to work:

```bash
# If you have an existing Minikube cluster, delete it first
minikube delete

# Start Minikube with Calico CNI
minikube start --cni=calico --memory=4096 --cpus=2

# Wait for Calico to be ready (takes 2-3 minutes)
echo "Waiting for Calico to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s
kubectl wait --for=condition=ready pod -l k8s-app=calico-kube-controllers -n kube-system --timeout=300s

# Verify Calico is running
kubectl get pods -n kube-system | grep calico
# Should show:
# calico-kube-controllers-xxx   1/1     Running
# calico-node-xxx               1/1     Running
```

**Why this is required:**
- ✅ Calico enforces NetworkPolicy rules
- ❌ Default kindnet CNI ignores NetworkPolicy
- ⚠️ Installing Calico afterward causes conflicts

**For CKA Exam:** The exam cluster already has a CNI that supports NetworkPolicy, so you won't need to install anything.

### Create Test Environment

```bash
# Create namespace for testing
kubectl create namespace netpol-test
kubectl config set-context --current --namespace=netpol-test

# Create frontend pod (using busybox with wget)
kubectl run frontend --image=busybox --labels="tier=frontend" \
  -- sleep 3600

# Create backend pod (nginx for web server)
kubectl run backend --image=nginx --labels="tier=backend"

# Create database pod
kubectl run database --image=postgres:alpine --labels="tier=database" \
  --env="POSTGRES_PASSWORD=secret"

# Expose services
kubectl expose pod frontend --port=80
kubectl expose pod backend --port=80
kubectl expose pod database --port=5432

# Wait for pods to be ready
kubectl wait --for=condition=ready pod frontend --timeout=60s
kubectl wait --for=condition=ready pod backend --timeout=60s
kubectl wait --for=condition=ready pod database --timeout=60s
```

## Basic NetworkPolicy

### Deny All Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: netpol-test
spec:
  podSelector: {}  # Applies to all pods
  policyTypes:
  - Ingress
EOF
```

### Test Deny All

```bash
# Before NetworkPolicy
kubectl exec frontend -- wget -qO- --timeout=2 backend
# Works

# Apply deny-all
kubectl apply -f deny-all.yaml

# After NetworkPolicy
kubectl exec frontend -- wget -qO- --timeout=2 backend
# Fails (timeout)
```

### Allow All Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - {}  # Empty rule allows all
EOF
```

## Ingress Rules

### Allow from Specific Pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
```

### Test Specific Pod Access

```bash
# Frontend to backend - should work
kubectl exec frontend -- wget -qO- --timeout=2 backend

# Database to backend - should fail
kubectl exec database -- wget -qO- --timeout=2 backend
```

### Allow from Specific Namespace

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-prod-namespace
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
    ports:
    - protocol: TCP
      port: 8080
EOF
```

### Allow from IP Block

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-cidr
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
EOF
```

## Egress Rules

### Deny All Egress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
EOF
```

### Allow Egress to Specific Pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-to-database
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
EOF
```

### Allow DNS (Essential!)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
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
EOF
```

## Selectors

### Pod Selector

Match pods by labels.

```yaml
podSelector:
  matchLabels:
    app: frontend
    version: v1
```

### Namespace Selector

Match entire namespace.

```yaml
namespaceSelector:
  matchLabels:
    environment: production
```

### Combined Selectors (AND)

Both conditions must match.

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        environment: prod
    podSelector:
      matchLabels:
        app: api
```

### Multiple Selectors (OR)

Any condition matches.

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        environment: prod
  - podSelector:
      matchLabels:
        app: admin
```

## Common Patterns

### 3-Tier Application

```bash
cat <<EOF | kubectl apply -f -
# Frontend: Allow from anywhere
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - {}  # Allow all ingress
---
# Backend: Allow only from frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
---
# Database: Allow only from backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF
```

### Default Deny with Exceptions

```bash
cat <<EOF | kubectl apply -f -
# Default deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
---
# Allow specific connections
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-traffic
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
EOF
```

### Isolate Namespace

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: production
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF
```

## Hands-On Practice

Try these exercises on your own before looking at the solutions!

### Exercise 1: Three-Tier App Security

**Task:** Set up a 3-tier application with network isolation:
- Frontend tier (nginx)
- Backend tier (nginx)
- Database tier (postgres)

**Requirements:**
- Create 3 pods with labels: tier=frontend, tier=backend, tier=database
- Create services for each tier
- Apply a NetworkPolicy that:
  - Allows ONLY backend to connect to database on port 5432
  - Blocks frontend from accessing database directly
  - Allows frontend to access backend

**Test:**
- Before policy: All connections should work
- After policy: Frontend → database should be blocked
- After policy: Backend → database should work

### Exercise 2: Namespace Isolation

**Task:** Create namespace-level isolation:
- Create two namespaces: prod and dev
- Create identical apps in both namespaces
- Apply NetworkPolicy to isolate prod namespace

**Requirements:**
- Both namespaces have a pod named "app" (nginx)
- Both have a service exposing port 80
- Label prod namespace: environment=production
- Label dev namespace: environment=development
- NetworkPolicy in prod allows ONLY traffic from prod namespace pods

**Test:**
- dev → prod: should be BLOCKED
- prod → prod: should work
- dev → dev: should work
- prod → dev: should work

---

## Solutions

### Understanding Pod Roles in NetworkPolicy Testing

**Important:** For NetworkPolicy testing, use nginx for web tier pods (frontend, backend) and postgres for database tier.

| Pod | Image | Has Server? | Has Testing Tools? | Can Be Server? | Can Be Client? |
|-----|-------|-------------|-------------------|----------------|----------------|
| **frontend** | nginx | ✅ Port 80 | ✅ curl | ✅ Yes | ✅ Yes |
| **backend** | nginx | ✅ Port 80 | ✅ curl | ✅ Yes | ✅ Yes |
| **database** | postgres | ✅ Port 5432 | ❌ None | ✅ Yes | ❌ No |

**Why nginx for frontend and backend?**
- ✅ Both have web servers on port 80 (server role)
- ✅ Both have curl built-in (client role)
- ✅ Simpler - same image for web tier
- ✅ Realistic microservice-to-microservice testing
- ✅ No need for sleep command - nginx runs automatically

**Why NOT busybox for frontend?**
- ❌ busybox has no web server (just runs `sleep`)
- ❌ Exposing busybox on port 80 creates service pointing to nothing
- ❌ Can't test if NetworkPolicy blocks vs. no server running

<details>
<summary><b>Solution 1: Three-Tier App Security</b></summary>

**Complete Solution:**

```bash
# Create pods - all using nginx for frontend and backend (simpler!)
kubectl run frontend --image=nginx --labels="tier=frontend"
kubectl run backend --image=nginx --labels="tier=backend"
kubectl run database --image=postgres:alpine --labels="tier=database" \
  --env="POSTGRES_PASSWORD=secret"

# Create services
kubectl expose pod frontend --port=80
kubectl expose pod backend --port=80
kubectl expose pod database --port=5432

# Wait for pods
kubectl wait --for=condition=ready pod frontend --timeout=60s
kubectl wait --for=condition=ready pod backend --timeout=60s
kubectl wait --for=condition=ready pod database --timeout=60s

# Wait for services to be ready
sleep 10

# Test connectivity (should all work - use curl from nginx)
echo "=== Testing connectivity BEFORE NetworkPolicy ==="
kubectl exec frontend -- curl -m 2 http://backend | head -3
kubectl exec frontend -- curl -m 2 database:5432 || echo "(postgres connection test)"
kubectl exec backend -- curl -m 2 database:5432 || echo "(postgres connection test)"

# Apply network policies
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
EOF

# Wait for policy to apply
sleep 15

# Test again (after NetworkPolicy applied)
echo ""
echo "=== Testing AFTER NetworkPolicy ==="
echo "frontend → database (should FAIL - frontend blocked):"
kubectl exec frontend -- timeout 5 curl -m 2 database:5432 2>&1 || echo "✅ BLOCKED by NetworkPolicy!"

echo "backend → database (should WORK - backend allowed):"
kubectl exec backend -- timeout 5 curl -m 2 database:5432 2>&1 || echo "(Connection works at TCP level, postgres rejects at app level)"

echo "frontend → backend (should WORK - no policy blocking this):"
kubectl exec frontend -- curl -m 2 http://backend | head -3
```

**Why use nginx for frontend and backend?**
- ✅ Both have web servers on port 80 (can receive connections)
- ✅ Both have curl built-in (can test connections)
- ✅ Simpler - same image, consistent setup
- ✅ Realistic - microservice-to-microservice communication

</details>

<details>
<summary><b>Solution 2: Namespace Isolation</b></summary>

**Complete Solution:**

```bash
# Create namespaces
kubectl create namespace prod
kubectl create namespace dev

# Label namespaces
kubectl label namespace prod environment=production
kubectl label namespace dev environment=development

# Create pods with nginx in both namespaces
kubectl run app --image=nginx -n dev
kubectl run app --image=nginx -n prod

# Create services in BOTH namespaces
kubectl expose pod app --port=80 -n prod
kubectl expose pod app --port=80 -n dev

# Wait for pods
kubectl wait --for=condition=ready pod app -n prod --timeout=60s
kubectl wait --for=condition=ready pod app -n dev --timeout=60s

# Wait for DNS to propagate
sleep 15

# Test before policy (both should work - use curl from nginx)
echo "=== Before NetworkPolicy ==="
echo "dev → prod (should work):"
kubectl exec -n dev app -- curl -m 2 http://app.prod.svc.cluster.local | head -3

echo "prod → prod (should work):"
kubectl exec -n prod app -- curl -m 2 http://app.prod.svc.cluster.local | head -3

echo "dev → dev (should work):"
kubectl exec -n dev app -- curl -m 2 http://app.dev.svc.cluster.local | head -3

# Apply isolation
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-prod
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: production
EOF

# Wait for policy to apply
sleep 15

# Test after policy
echo ""
echo "=== After NetworkPolicy ==="
echo "dev → prod (should be BLOCKED - dev namespace not allowed):"
kubectl exec -n dev app -- timeout 5 curl -m 2 http://app.prod.svc.cluster.local 2>&1 || echo "✅ BLOCKED by NetworkPolicy!"

echo ""
echo "prod → prod (should WORK - same namespace allowed):"
kubectl exec -n prod app -- curl -m 2 http://app.prod.svc.cluster.local | head -3 && echo "✅ Connection allowed!"

echo ""
echo "dev → dev (should WORK - no policy blocking dev namespace):"
kubectl exec -n dev app -- curl -m 2 http://app.dev.svc.cluster.local | head -3 && echo "✅ Connection allowed!"

echo ""
echo "prod → dev (should WORK - no policy blocking dev namespace):"
kubectl exec -n prod app -- curl -m 2 http://app.dev.svc.cluster.local | head -3 && echo "✅ Connection allowed!"
```

**Summary of NetworkPolicy behavior:**
- ✅ prod → prod: **ALLOWED** (same namespace)
- ❌ dev → prod: **BLOCKED** (NetworkPolicy blocks non-production namespaces)
- ✅ dev → dev: **ALLOWED** (no policy on dev namespace)
- ✅ prod → dev: **ALLOWED** (no policy on dev namespace)

**Key insight:** NetworkPolicy in prod namespace only controls **incoming traffic to prod**, not outgoing traffic from prod!

**Why nginx for both?**
- ✅ nginx has a web server on port 80 (can receive connections)
- ✅ nginx has curl built-in (can test connections)
- ✅ Simpler - same image for client and server
- ✅ More realistic - testing microservice-to-microservice communication

**DNS Note:** Use full DNS name `app.prod.svc.cluster.local` if short name `app.prod` doesn't resolve.

</details>

---

## Troubleshooting

### Issue 1: NetworkPolicy Not Blocking Traffic (Most Common!)

**Problem:** You created a NetworkPolicy but traffic is still allowed.

**Root Cause:** Minikube's default CNI (kindnet) does NOT enforce NetworkPolicy.

**Solution:**

```bash
# Check if you're using Calico
kubectl get pods -n kube-system | grep calico

# If no Calico pods appear:
# You MUST restart Minikube with Calico

# Step 1: Delete current Minikube
minikube delete

# Step 2: Start with Calico CNI
minikube start --cni=calico --memory=4096 --cpus=2

# Step 3: Wait for Calico (2-3 minutes)
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

# Step 4: Verify Calico is running
kubectl get pods -n kube-system | grep calico
# Should show calico-node and calico-kube-controllers Running

# Now NetworkPolicy will work!
```

**Quick Test to Verify NetworkPolicy Works:**

```bash
# Create test
kubectl create namespace test
kubectl run pod1 --image=busybox -n test -- sleep 3600
kubectl run pod2 --image=nginx -n test
kubectl expose pod pod2 --port=80 -n test
kubectl wait --for=condition=ready pod -n test --all --timeout=60s
sleep 15

# Test before policy (should work)
kubectl exec -n test pod1 -- wget -qO- --timeout=2 http://pod2

# Apply deny-all
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: test
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

sleep 15

# Test after policy (should timeout)
kubectl exec -n test pod1 -- timeout 5 wget -qO- http://pod2

# If it times out: ✅ NetworkPolicy works!
# If it succeeds: ❌ CNI doesn't support NetworkPolicy
```

### Issue 2: Policy Not Working Even with Calico

```bash
# Pods might have been created before Calico was ready
# Solution: Recreate the pods

kubectl delete pod -n <namespace> --all

# Recreate pods
kubectl run <pod-name> --image=<image> -n <namespace>

# Wait for Calico to configure them
sleep 15
```

### Issue 3: DNS Not Working / Can't Resolve Service

**Problem:** Cross-namespace DNS like `app.prod` doesn't resolve.

**Solution 1: Use Full DNS Name (FQDN)**

```bash
# ❌ Short name might not work:
kubectl exec -n dev app -- nc -zv app.prod 80

# ✅ Use full DNS name:
kubectl exec -n dev app -- nc -zv app.prod.svc.cluster.local 80

# Kubernetes DNS format:
# <service-name>.<namespace>.svc.cluster.local
```

**Solution 2: Verify Service Exists**

```bash
# Check if service exists in target namespace
kubectl get svc -n prod

# If service doesn't exist, create it
kubectl expose pod app --port=80 -n prod

# Wait for DNS to propagate
sleep 15
```

**Solution 3: Check CoreDNS**

```bash
# Check CoreDNS is running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test basic DNS (should work)
kubectl exec -n dev app -- nslookup kubernetes

# Restart CoreDNS if needed
kubectl rollout restart deployment coredns -n kube-system
kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=120s
sleep 15
```

**Solution 4: Add DNS Egress Rule**

```bash
# If you have strict egress policies, allow DNS
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: dev
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF
```

### Issue 4: Connection Fails Even Without NetworkPolicy

**Problem:** `nc` or `wget` fails but no NetworkPolicy is applied.

**Root Cause:** Server pod (like busybox) has NO service listening on the port.

**Solution:**

```bash
# ❌ WRONG - busybox has no web server:
kubectl run app --image=busybox -n prod -- sleep 3600
kubectl expose pod app --port=80 -n prod
kubectl exec -n dev client -- nc -zv app.prod.svc.cluster.local 80
# Fails: Connection refused (nothing listening on port 80)

# ✅ CORRECT - Use nginx (has web server on port 80):
kubectl delete pod app -n prod
kubectl run app --image=nginx -n prod
kubectl expose pod app --port=80 -n prod
kubectl wait --for=condition=ready pod app -n prod --timeout=60s
sleep 10
kubectl exec -n dev client -- nc -zv app.prod.svc.cluster.local 80
# Works: app.prod.svc.cluster.local (10.x.x.x:80) open ✅
```

**Pod Role Summary:**
- **Server** (receives connections): nginx, httpd, postgres - must have listening service
- **Client** (tests connections): busybox, alpine - needs nc/wget tools
- **Don't use busybox as server** - it has no listening service!

### Issue 5: Can't Test Connectivity

**Important: Choose the right image for testing!**

```bash
# Option 1: busybox (has wget and nc)
kubectl run test --image=busybox -it --rm -- sh
# Inside pod:
wget -qO- --timeout=2 http://backend
nc -zv backend 80

# Option 2: nicolaka/netshoot (has all network tools)
kubectl run test --image=nicolaka/netshoot -it --rm -- sh
# Inside pod:
wget -qO- --timeout=2 http://backend
nc -zv backend 80
nslookup backend
curl backend

# Option 3: alpine (has wget)
kubectl run test --image=alpine -it --rm -- sh
# Inside pod:
wget -qO- --timeout=2 http://backend

# ❌ DON'T use nginx for testing - it doesn't have wget/curl/nc
```

**Testing from existing pods:**

```bash
# If pod is nginx (no wget):
kubectl exec nginx-pod -- curl backend  # nginx has curl
kubectl exec nginx-pod -- nc -zv backend 80  # nginx might not have nc

# If pod is busybox:
kubectl exec busybox-pod -- wget -qO- --timeout=2 http://backend
kubectl exec busybox-pod -- nc -zv backend 80

# Best practice: Create a dedicated test pod
kubectl run nettest --image=busybox -- sleep 3600
kubectl exec nettest -- wget -qO- --timeout=2 http://backend
kubectl exec nettest -- nc -zv backend 80
```

### Debugging Commands

```bash
# List all NetworkPolicies
kubectl get networkpolicy -A

# Describe policy
kubectl describe networkpolicy <n>

# Check pod connectivity (use busybox or alpine)
kubectl run nettest --image=busybox -- sleep 3600
kubectl exec nettest -- wget -qO- --timeout=2 http://<target>
kubectl exec nettest -- nc -zv <target> <port>

# Or use nicolaka/netshoot for full toolset
kubectl run nettest --image=nicolaka/netshoot -- sleep 3600
kubectl exec nettest -- curl <target>
kubectl exec nettest -- nslookup <target>
kubectl exec nettest -- telnet <target> <port>

# View policy YAML
kubectl get networkpolicy <n> -o yaml

# Check pod labels
kubectl get pods --show-labels

# Verify namespace labels
kubectl get namespaces --show-labels
```

## Exam Tips

### Quick NetworkPolicy Creation

```bash
# Basic template
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: <policy-name>
spec:
  podSelector:
    matchLabels:
      app: <app-name>
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: <source-app>
    ports:
    - protocol: TCP
      port: <port>
EOF
```

### Common Exam Patterns

```bash
# Pattern 1: Allow only specific pod to database
podSelector:
  matchLabels:
    tier: database
ingress:
- from:
  - podSelector:
      matchLabels:
        tier: backend

# Pattern 2: Deny all, then allow specific
# First apply deny-all, then allow policies

# Pattern 3: Always remember DNS
egress:
- to:
  - namespaceSelector: {}
  ports:
  - protocol: UDP
    port: 53
```

### Time-Saving Tips

1. **Start with deny-all**: Apply default deny, then add exceptions
2. **Test before and after**: Verify connectivity before/after policy
3. **Use kubectl explain**: `kubectl explain networkpolicy.spec`
4. **Remember DNS**: Always allow port 53 UDP for egress
5. **Check labels**: Verify pod labels match selectors

## Practice Questions

### Question 1

Create NetworkPolicy allowing only pods labeled `app=api` to access pods labeled `app=database` on port 5432.

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 5432
EOF
```
</details>

### Question 2

Create NetworkPolicy denying all egress except DNS.

<details>
<summary>Solution</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-egress-except-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF
```
</details>

## Quick Reference

### NetworkPolicy Template

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: POLICY_NAME
spec:
  podSelector:
    matchLabels:
      KEY: VALUE
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          KEY: VALUE
    ports:
    - protocol: TCP
      port: PORT
  egress:
  - to:
    - podSelector:
        matchLabels:
          KEY: VALUE
    ports:
    - protocol: TCP
      port: PORT
```

### Common Commands

```bash
# Create policy
kubectl apply -f policy.yaml

# List policies
kubectl get networkpolicy
kubectl get netpol  # short form

# Describe
kubectl describe networkpolicy <n>

# Delete
kubectl delete networkpolicy <n>

# Test connectivity (use appropriate image)
kubectl run nettest --image=busybox -- sleep 3600
kubectl exec nettest -- wget -qO- --timeout=2 http://<target>
kubectl exec nettest -- nc -zv <target> <port>
```

### Image Reference for Testing

| Image | Has Server? | wget | curl | nc | Best For |
|-------|-------------|------|------|----|----------|
| **nginx** | ✅ Port 80 | ❌ | ✅ | ❌ | **Server AND client** ⭐ |
| **busybox** | ❌ None | ✅ | ❌ | ✅ | Client testing only |
| **postgres** | ✅ Port 5432 | ❌ | ❌ | ❌ | Database server only |
| **nicolaka/netshoot** | ❌ None | ✅ | ✅ | ✅ | Advanced debugging |

**Testing Examples:**

```bash
# Using nginx for BOTH client and server (recommended!)
kubectl run server --image=nginx -n prod
kubectl run client --image=nginx -n dev
kubectl expose pod server --port=80 -n prod

# Test from client (use curl)
kubectl exec -n dev client -- curl -m 2 http://server.prod.svc.cluster.local

# Test from server (nginx can test itself)
kubectl exec -n prod server -- curl -m 2 http://server.prod.svc.cluster.local

# Or use busybox for client (has nc and wget)
kubectl run client --image=busybox -n dev -- sleep 3600
kubectl exec -n dev client -- nc -zv server.prod.svc.cluster.local 80
kubectl exec -n dev client -- wget -qO- --timeout=2 http://server.prod.svc.cluster.local
```

**Recommendation for NetworkPolicy testing:**
- ✅ **Use nginx for both client and server** - simpler, has web server + curl
- ✅ Or use busybox for client (has nc, wget) + nginx for server
- ❌ Don't use busybox as server - it has no listening service!

**For CKA exam:**
- nginx is perfect - can be both server and client
- Command: `kubectl run test --image=nginx`
- Test with: `kubectl exec test -- curl -m 2 http://target`

---

**Back to**: [Main README](../README.md) | [Previous: Storage](04-storage-management.md) | [Next: Sidecar Patterns](06-sidecar-patterns.md)
